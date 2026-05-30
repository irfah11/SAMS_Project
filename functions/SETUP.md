# SAMS Payment Backend — Setup Guide

This folder is a **Firebase Cloud Functions** project. It holds your Stripe and
Billplz **secret keys** and exposes three endpoints your Flutter app calls.

> Why a backend at all? Stripe and Billplz both need a *secret* key to actually
> move money. That key must never ship inside an APK (anyone can extract it).
> The app only ever talks to these functions; the functions talk to Stripe/Billplz.

---

## 0. One-time prerequisites

1. **Install Node.js 20** → https://nodejs.org (LTS).
2. **Install the Firebase CLI** (PowerShell):
   ```powershell
   npm install -g firebase-tools
   firebase login
   ```
3. **Upgrade the Firebase project to the Blaze (pay-as-you-go) plan.**
   Cloud Functions that call the internet (Stripe/Billplz) require Blaze.
   It has a generous free tier — you won't be charged for light testing.
   Firebase Console → ⚙ → Usage and billing → Modify plan → Blaze.

---

## 1. Install dependencies

```powershell
cd functions
npm install
```

---

## 2. Create a Billplz sandbox Collection

Card payments need nothing extra. Billplz bills must belong to a *collection*.

1. Log in to the **Billplz sandbox**: https://www.billplz-sandbox.com
2. Billing → **New Collection** (e.g. "SAMS Fees").
3. Copy the **Collection ID**.

---

## 3. Configure the function

### Non-secret params → `functions/.env`
```powershell
copy .env.example .env
```
Open `.env` and set:
```
BILLPLZ_COLLECTION_ID=<your collection id>
BILLPLZ_CALLBACK_URL=        # leave blank for now (filled in step 5)
```

### Secret keys → Firebase Secret Manager
Run each command and paste the value when prompted (nothing is written to disk):
```powershell
firebase functions:secrets:set STRIPE_SECRET_KEY
firebase functions:secrets:set BILLPLZ_SECRET_KEY
firebase functions:secrets:set BILLPLZ_XSIGNATURE
```
- `STRIPE_SECRET_KEY` → your Stripe **test** secret key (`sk_test_...`) from the
  Stripe dashboard (Developers → API keys). You gave me the *publishable* key
  earlier; the **secret** one is the partner to it.
- `BILLPLZ_SECRET_KEY` → your Billplz sandbox API secret key.
- `BILLPLZ_XSIGNATURE` → your Billplz X-Signature key.

> 🔐 Because these keys were shared in chat, consider rotating them in the
> Stripe/Billplz dashboards before going live, and never commit them to git.

---

## 4. First deploy

```powershell
firebase deploy --only functions
```
When it finishes, the CLI prints a URL for each function, e.g.:
```
createPaymentIntent: https://us-central1-sams-7a359.cloudfunctions.net/createPaymentIntent
createBill:          https://us-central1-sams-7a359.cloudfunctions.net/createBill
billplzCallback:     https://us-central1-sams-7a359.cloudfunctions.net/billplzCallback
```
Copy these.

---

## 5. Wire the callback + the app, then redeploy

1. Put the **billplzCallback** URL into `functions/.env`:
   ```
   BILLPLZ_CALLBACK_URL=https://us-central1-sams-7a359.cloudfunctions.net/billplzCallback
   ```
2. Put the other two URLs into the Flutter app:
   - `lib/config/stripe_config.dart` → `createPaymentIntentUrl` = the **createPaymentIntent** URL
   - `lib/config/billplz_config.dart` → `createBillUrl` = the **createBill** URL
3. Redeploy so the callback URL takes effect:
   ```powershell
   firebase deploy --only functions
   ```

---

## 6. Test

- **Card:** in the app, pay by card with Stripe test card `4242 4242 4242 4242`,
  any future expiry, any CVC. The Fee should flip to Paid.
- **FPX:** pay by FPX → the app opens the Billplz page → pick a sandbox bank →
  "pay". Billplz calls `billplzCallback`, which marks the Fee paid, and the app's
  waiting screen updates automatically.
- Watch logs while testing:
  ```powershell
  firebase functions:log
  ```

---

## Going live (later)
- Swap `BILLPLZ_BASE` in `index.js` to `https://www.billplz.com/api/v3` and set
  live Billplz keys.
- Use Stripe **live** keys (`pk_live_`, `sk_live_`).
- Add a **Stripe webhook** (`payment_intent.succeeded`) so card payments are
  recorded server-side instead of trusting the client — the FPX flow already
  works this way via `billplzCallback`.
- Add Firestore Security Rules so only the functions (Admin SDK) can write to
  `transactions` / `Fee`.
