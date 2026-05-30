// =============================================================
// Billplz (FPX online banking) configuration
// =============================================================
class BillplzConfig {
  // Your backend endpoint that creates a Billplz bill using the SECRET key and
  // returns the hosted bill URL. This is the deployed `createBill` Cloud
  // Function URL (see functions/SETUP.md).
  //
  // ⚠️  The Billplz SECRET key and X-Signature key live in the Cloud Function
  //     (Firebase Secret Manager) — NEVER in this app. Until this URL is set,
  //     FPX payments fail with a clear "backend not configured" message.
  static const String createBillUrl =
      'http://10.62.107.202:5001/sams-7a359/us-central1/createBill';
}
