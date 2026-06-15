import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
// Import fail login

import 'package:sams/auth/login_screen.dart';
import 'package:sams/config/stripe_config.dart';
// Import firebase_options yang kita dah jana tadi

// FIX: Buang 'dynamic DefaultFirebaseOptions' dari dalam kurungan main()
void main() async {
  // 1. Pastikan binding dimulakan dulu
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inisialisasi Firebase secara ringkas (dia akan baca google-services.json)
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey:
          'AIzaSyDNRaEm5JkpDMy0c789Ga5H6ulcv55t-fI', // Cari "current_key" dalam google-services.json
      appId:
          '1:696960893106:android:720aaff5a2010995af49ab', // Cari "mobilesdk_app_id"
      messagingSenderId: '696960893106', // Cari "project_number"
      projectId: 'sams-7a359',
      storageBucket:
          'sams-7a359.firebasestorage.app', // Ini ID projek awak berdasarkan gambar tadi
    ),
  );

  // 3. Initialise Stripe with the publishable key.
  // flutter_stripe has no web/desktop platform implementation; its
  // MethodChannelStripe reads dart:io Platform.isIOS/isAndroid, which
  // throws UnsupportedError on web and crashes main() before runApp().
  if (!kIsWeb) {
    Stripe.publishableKey = StripeConfig.publishableKey;
    await Stripe.instance.applySettings();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SAMS',
      theme: ThemeData(
        primaryColor: const Color(
          0xFFE67E33,
        ), // Warna oren registrar sebagai tema
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
