import 'package:flutter/material.dart';
import 'auth_service.dart';
// ignore: unused_import
import 'login_screen.dart'; // 1. Added this import

// 2. Added Dashboard imports
import '../screen/Manage_Dashboard/student_dashboard.dart';
import '../screen/Manage_Dashboard/lecturer_dashboard.dart';
import '../screen/Manage_Dashboard/faculty_registrar_dashboard.dart';
import '../screen/Manage_Dashboard/pusat_adab_dashboard.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

// 3. FIXED SYNTAX: Removed the "()" after _RegisterScreenState
class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  void _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email and password.')),
      );
      return;
    }

    final user = await _authService.register(email, password);

    if (user != null) {
      if (!mounted) return;

      String userRole = "Student";
      Widget nextScreen;

      switch (userRole) {
        case 'Lecturer':
          nextScreen = const LecturerDashboard();
          break;
        case 'Faculty Registrar':
          nextScreen = const FacultyRegistrarDashboard();
          break;
        case 'Pusat Adab':
          nextScreen = const PusatAdabDashboard();
          break;
        case 'Student':
        default:
          nextScreen = const StudentDashboard();
          break;
      }

      // 4. FIXED NAVIGATION: Use nextScreen or LoginScreen based on your preference
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => nextScreen),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Register",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _register, child: const Text('Register')),
          ],
        ),
      ),
    );
  }
}
