// =============================================================
// SAMS payment backend — Firebase Cloud Functions (2nd gen)
//
// Three HTTPS endpoints:
//   createPaymentIntent  → Stripe card payments (returns a client_secret)
//   createBill           → Billplz FPX (returns a hosted bill URL)
//   billplzCallback      → Billplz server-to-server webhook (marks fee paid)
//
// Secret keys live in Firebase Secret Manager (see SETUP.md), NEVER in the app.
// All amounts are computed SERVER-SIDE from the Fee document, so a tampered
// client can't change what's charged.
// =============================================================
const crypto = require("crypto");
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret, defineString } = require("firebase-functions/params");
const admin = require("firebase-admin");
const Stripe = require("stripe");

admin.initializeApp();
const db = admin.firestore();

// ---- Configuration ----
const STRIPE_SECRET_KEY = defineSecret("STRIPE_SECRET_KEY");
const BILLPLZ_SECRET_KEY = defineSecret("BILLPLZ_SECRET_KEY");
const BILLPLZ_XSIGNATURE = defineSecret("BILLPLZ_XSIGNATURE");

// Non-secret params (set in functions/.env — see .env.example)
const BILLPLZ_COLLECTION_ID = defineString("BILLPLZ_COLLECTION_ID");
const BILLPLZ_CALLBACK_URL = defineString("BILLPLZ_CALLBACK_URL"); // set after first deploy

// Billplz SANDBOX. Switch to https://www.billplz.com/api/v3 when going live.
const BILLPLZ_BASE = "https://www.billplz-sandbox.com/api/v3";
const CURRENCY = "myr";

// =============================================================
// Helpers
// =============================================================

// Find the Fee document for a student+semester (throws if none).
async function loadFeeDoc(studentId, semesterId) {
  const snap = await db
    .collection("Fee")
    .where("student_id", "==", studentId)
    .where("semester_id", "==", semesterId)
    .limit(1)
    .get();
  if (snap.empty) {
    throw new Error(`No Fee record for ${studentId} / ${semesterId}`);
  }
  return snap.docs[0];
}

// Look up the student's name + email (email is stored as user_id on `student`).
async function loadStudent(studentId) {
  const snap = await db
    .collection("student")
    .where("student_id", "==", studentId)
    .limit(1)
    .get();
  if (snap.empty) return null;
  return snap.docs[0].data();
}

// Record a successful payment: write a transaction + mark the Fee paid.
// Idempotent — if a transaction with this id already exists, do nothing
// (protects against duplicate/replayed webhooks).
async function recordPayment({ studentId, semesterId, amount, method, transactionId }) {
  const dup = await db
    .collection("transactions")
    .where("transaction_id", "==", transactionId)
    .limit(1)
    .get();
  if (!dup.empty) {
    console.log(`Transaction ${transactionId} already recorded — skipping.`);
    return;
  }

  await db.collection("transactions").add({
    transaction_id: transactionId,
    student_id: studentId,
    semester_id: semesterId,
    amount_paid: amount,
    payment_method: method,
    transaction_date: admin.firestore.FieldValue.serverTimestamp(),
    payment_success_stat: "success",
  });

  const feeDoc = await loadFeeDoc(studentId, semesterId);
  await feeDoc.ref.update({
    payment_status: "Paid",
    access_status: "Unblocked",
    total_outstanding: 0,
  });
}

// =============================================================
// 1) Stripe — create a PaymentIntent
//    The app confirms it with the card entered in its CardField.
// =============================================================
exports.createPaymentIntent = onRequest(
  { secrets: [STRIPE_SECRET_KEY], cors: true },
  async (req, res) => {
    try {
      const { student_id, semester_id } = req.body || {};
      if (!student_id || !semester_id) {
        return res.status(400).json({ error: "student_id and semester_id required" });
      }

      const feeDoc = await loadFeeDoc(student_id, semester_id);
      const amount = Number(feeDoc.data().total_outstanding) || 0;
      if (amount <= 0) {
        return res.status(400).json({ error: "Nothing outstanding to pay" });
      }

      const stripe = Stripe(STRIPE_SECRET_KEY.value());
      const intent = await stripe.paymentIntents.create({
        amount: Math.round(amount * 100), // smallest unit (sen)
        currency: CURRENCY,
        metadata: { student_id, semester_id },
        automatic_payment_methods: { enabled: true, allow_redirects: "never" },
      });

      // NOTE: for production, also add a Stripe webhook that records the payment
      // server-side on `payment_intent.succeeded` instead of trusting the client.
      return res.json({ client_secret: intent.client_secret });
    } catch (e) {
      console.error("createPaymentIntent:", e);
      return res.status(500).json({ error: e.message });
    }
  }
);

// =============================================================
// 2) Billplz — create a hosted FPX bill
// =============================================================
exports.createBill = onRequest(
  { secrets: [BILLPLZ_SECRET_KEY], cors: true },
  async (req, res) => {
    try {
      const { student_id, semester_id } = req.body || {};
      if (!student_id || !semester_id) {
        return res.status(400).json({ error: "student_id and semester_id required" });
      }

      const feeDoc = await loadFeeDoc(student_id, semester_id);
      const amount = Number(feeDoc.data().total_outstanding) || 0;
      if (amount <= 0) {
        return res.status(400).json({ error: "Nothing outstanding to pay" });
      }

      const student = await loadStudent(student_id);
      const email = (student && student.user_id) || "student@example.com";
      const name = (student && student.full_name) || student_id;

      const form = new URLSearchParams({
        collection_id: BILLPLZ_COLLECTION_ID.value(),
        email,
        name,
        amount: String(Math.round(amount * 100)), // sen
        callback_url: BILLPLZ_CALLBACK_URL.value(),
        description: `SAMS fee — ${semester_id}`,
        reference_1_label: "Student",
        reference_1: student_id,
        reference_2_label: "Semester",
        reference_2: semester_id,
      });

      // Billplz uses HTTP Basic auth: secret key as username, blank password.
      const auth = Buffer.from(`${BILLPLZ_SECRET_KEY.value()}:`).toString("base64");
      const resp = await fetch(`${BILLPLZ_BASE}/bills`, {
        method: "POST",
        headers: {
          Authorization: `Basic ${auth}`,
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: form.toString(),
      });

      const data = await resp.json();
      if (!resp.ok) {
        console.error("Billplz createBill error:", data);
        return res.status(resp.status).json({ error: data });
      }

      return res.json({ url: data.url, bill_id: data.id });
    } catch (e) {
      console.error("createBill:", e);
      return res.status(500).json({ error: e.message });
    }
  }
);

// =============================================================
// 3) Billplz — payment webhook (server-to-server)
//    Billplz POSTs here when the bill state changes. We verify the
//    X-Signature, then RE-FETCH the bill from Billplz (authoritative)
//    before recording anything.
// =============================================================
exports.billplzCallback = onRequest(
  { secrets: [BILLPLZ_SECRET_KEY, BILLPLZ_XSIGNATURE] },
  async (req, res) => {
    try {
      const data = req.body || {};

      // ---- Verify X-Signature ----
      // Source string = each "key" + "value" (except x_signature), the
      // resulting strings sorted ascending and joined with "|", then
      // HMAC-SHA256 with your X-Signature key.
      const received = data.x_signature;
      const source = Object.keys(data)
        .filter((k) => k !== "x_signature")
        .sort()
        .map((k) => `${k}${data[k]}`)
        .join("|");
      const expected = crypto
        .createHmac("sha256", BILLPLZ_XSIGNATURE.value())
        .update(source)
        .digest("hex");

      const signatureOk = received && received === expected;
      if (!signatureOk) {
        // Don't hard-fail: the bill re-fetch below is the real source of truth.
        console.warn("Billplz x_signature mismatch — relying on bill re-fetch.");
      }

      // ---- Re-fetch the bill to confirm it is actually paid ----
      const billId = data.id;
      if (!billId) return res.status(400).send("missing bill id");

      const auth = Buffer.from(`${BILLPLZ_SECRET_KEY.value()}:`).toString("base64");
      const billResp = await fetch(`${BILLPLZ_BASE}/bills/${billId}`, {
        headers: { Authorization: `Basic ${auth}` },
      });
      const bill = await billResp.json();

      if (bill.paid === true) {
        await recordPayment({
          studentId: bill.reference_1,
          semesterId: bill.reference_2,
          amount: Number(bill.amount) / 100,
          method: "FPX",
          transactionId: bill.id, // Billplz bill id doubles as the receipt no.
        });
      }

      // Always 200 so Billplz stops retrying.
      return res.status(200).send("OK");
    } catch (e) {
      console.error("billplzCallback:", e);
      return res.status(500).send("error");
    }
  }
);
