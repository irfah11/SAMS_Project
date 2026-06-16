import 'package:flutter/material.dart';
import 'auth_service.dart';
// ignore: unused_import
import 'login_screen.dart';

import '../screen/Manage_Dashboard/student_dashboard.dart';
import '../screen/Manage_Dashboard/lecturer_dashboard.dart';
import '../screen/Manage_Dashboard/faculty_registrar_dashboard.dart';
import '../screen/Manage_Dashboard/pusat_adab_dashboard.dart';
import '../screen/Fee/Treasury/TreasuryDashboardPage.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  // The ID the user types: a student ID for students, a staff ID otherwise.
  final TextEditingController _idController = TextEditingController();
  final AuthService _authService = AuthService();

  // Role values match users/{uid}.role and the login screen dropdown.
  String _selectedRole = 'student';
  final List<String> _roles = [
    'student',
    'lecturer',
    'registrar',
    'adab',
    'treasury',
  ];

  // The ID field's label changes with the selected role.
  String get _idLabel =>
      _selectedRole == 'student' ? 'Student ID (e.g. CB23076)' : 'Staff ID';

  void _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final linkedId = _idController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email and password.')),
      );
      return;
    }

    // Every account must be linked to a real person via their ID.
    if (linkedId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your $_idLabel.')),
      );
      return;
    }

    final user = await _authService.register(
      email,
      password,
      _selectedRole,
      linkedId: linkedId,
    );

    if (user != null) {
      if (!mounted) return;

      Widget nextScreen;
      switch (_selectedRole) {
        case 'lecturer':
          nextScreen = const LecturerDashboard();
          break;
        case 'registrar':
          nextScreen = const FacultyRegistrarDashboard();
          break;
        case 'adab':
          nextScreen = const PusatAdabDashboard();
          break;
        case 'treasury':
          nextScreen = const TreasuryDashboardPage();
          break;
        case 'student':
        default:
          nextScreen = StudentDashboard(studentId: linkedId);
          break;
      }

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
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              decoration: const InputDecoration(
                labelText: 'Register As',
                border: OutlineInputBorder(),
              ),
              items: _roles.map((String role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(role.toUpperCase()),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedRole = newValue!;
                });
              },
            ),
            const SizedBox(height: 16),
            // ID field — label follows the selected role (Student ID / Staff ID).
            TextField(
              controller: _idController,
              decoration: InputDecoration(
                labelText: _idLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: _register, child: const Text('Register')),
          ],
        ),
      ),
    );
  }
}
