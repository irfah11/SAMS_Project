import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Result of a successful login.
/// [role] decides which dashboard to open. The account's owner is identified by
/// either [studentId] (students → student/{studentId}) or [staffId]
/// (lecturer/registrar/adab/treasury). Exactly one is populated.
class AuthResult {
  final String role;
  final String studentId;
  final String staffId;

  const AuthResult({
    required this.role,
    this.studentId = '',
    this.staffId = '',
  });
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. LOGIN — sign in, then read users/{uid} for the role + linked student_id.
  Future<AuthResult?> login(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userDoc = await _firestore
          .collection('users')
          .doc(result.user!.uid)
          .get();

      if (!userDoc.exists) return null;

      final data = userDoc.data() as Map<String, dynamic>;
      return AuthResult(
        role: (data['role'] ?? '').toString(),
        studentId: (data['student_id'] ?? '').toString(),
        staffId: (data['staff_id'] ?? '').toString(),
      );
    } catch (e) {
      print("Error login: $e");
      return null;
    }
  }

  // 2. REGISTER — create the account and the matching users/{uid} document.
  // [linkedId] is the ID the user typed: their student ID (students) or staff ID
  // (lecturer/registrar/adab/treasury). It's stored under the right field so the
  // login flow can tell which person this account belongs to.
  Future<User?> register(
    String email,
    String password,
    String role, {
    String linkedId = '',
  }) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = result.user;
      if (user != null) {
        final data = <String, dynamic>{'email': email, 'role': role};
        if (linkedId.isNotEmpty) {
          // Route the linked ID to the field the attendance module reads:
          //   students  → student_id  (String, e.g. "CB23028")
          //   lecturers → lecturer_id (numeric, e.g. 1002)
          //   others    → staff_id
          if (role == 'student') {
            data['student_id'] = linkedId;
          } else if (role == 'lecturer') {
            data['lecturer_id'] = int.tryParse(linkedId) ?? linkedId;
          } else {
            data['staff_id'] = linkedId;
          }
        }
        await _firestore.collection('users').doc(user.uid).set(data);
      }

      return user;
    } catch (e) {
      print("Error register: $e");
      return null;
    }
  }

  // 3. LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }
}
