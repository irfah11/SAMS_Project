// =============================================================
// Stripe configuration
// =============================================================
class StripeConfig {
  // Publishable (client) key — safe to ship inside the app.
  // This is the TEST key; swap for the live key (pk_live_...) when going live.
  static const String publishableKey =
      'pk_test_51TcZxg7HyzJnXS6cHIdXkQsiil0ymD9r1YDWWLSlTqQpd24KQixqEzeY5Gxpjo8Jv9LOMVkpnRNOQh2HGUIjtMdu00Ygi9LLng';

  // Currency for charges (ISO 4217). Malaysian Ringgit.
  static const String currency = 'myr';

  // Your backend endpoint that creates a Stripe PaymentIntent using the
  // SECRET key and returns its `client_secret`.
  //
  // ⚠️  The Stripe SECRET key must live on the server (e.g. a Firebase Cloud
  //     Function) — NEVER in this app. Until you deploy that endpoint and set
  //     the URL below, card payments will fail with a clear "backend not
  //     configured" message. FPX/online-banking will be wired separately once
  //     the Billplz key arrives.
  // ⚠️ LOCAL EMULATOR over Wi-Fi: this is THIS PC's Wi-Fi IP. A physical phone
  //    must be on the same Wi-Fi. The IP changes when you switch networks —
  //    run `ipconfig` (look for the Wi-Fi IPv4) and update it here when it does.
  static const String createPaymentIntentUrl =
      'http://172.25.166.82:5001/sams-7a359/us-central1/createPaymentIntent';
}
