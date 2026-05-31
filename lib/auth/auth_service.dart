import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. FUNGSI LOGIN
  Future<String?> loginAndGetRole(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .get();

      if (userDoc.exists) {
        return userDoc.get('role');
      }
      return null;
    } catch (e) {
      print("Error login: $e");
      return null;
    }
  }

  // 2. FUNGSI REGISTER
  Future<User?> register(String email, String password, String role) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;
      if (user != null) {
        // Create the matching users/{uid} document so login can read the role.
        await _firestore.collection('users').doc(user.uid).set({
          'email': email,
          'role': role,
        });
      }

      return user;
    } catch (e) {
      print("Error register: $e");
      return null;
    }
  }

  // 3. FUNGSI LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }
}
