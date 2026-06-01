import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'register_screen.dart';

import 'package:sams/screen/Manage_Dashboard/treasury_dashboard.dart';
import 'package:sams/screen/Manage_Dashboard/student_dashboard.dart';
import 'package:sams/screen/Manage_Dashboard/lecturer_dashboard.dart';
import 'package:sams/screen/Manage_Dashboard/pusat_adab_dashboard.dart';
import '../screen/Manage_Dashboard/faculty_registrar_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String _selectedRole = 'student'; // Default role
  final List<String> _roles = [
    'student',
    'lecturer',
    'registrar',
    'adab',
    'treasury',
  ];

  // --- FUNGSI NAVIGASI (LAMPU ISYARAT) ---
  void _navigateToDashboard(String role, String studentId) {
    switch (role) {
      case 'student':
        // Pass the logged-in student's id so the dashboard + Fee page load
        // the correct student/{studentId} record.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => StudentDashboard(studentId: studentId),
          ),
        );
        break;
      case 'lecturer':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LecturerDashboard()),
        );
        break;
      case 'registrar':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => FacultyRegistrarDashboard()),
        );
        break;
      case 'adab':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => PusatAdabDashboard()),
        );
        break;
      case 'treasury':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => TreasuryDashboard()),
        );
        break;
      default:
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Role tidak dikenali!")));
    }
  }

  void _handleLogin() async {
    setState(() => _isLoading = true);

    // 1. Login & read the real role + linked student_id from users/{uid}.
    final AuthResult? auth = await _authService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (auth != null) {
      // 2. NAVIGASI: route by the REAL role stored in Firestore (not the
      // dropdown). The dropdown is now only a visual hint.
      _navigateToDashboard(auth.role, auth.studentId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Login berjaya sebagai ${auth.role}."),
        ),
      );
    } else {
      // Jika login gagal (Email/Password salah)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Login Gagal! Sila periksa email dan password anda."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon SAMS
              const Icon(Icons.school, size: 80, color: Color(0xFFE67E33)),
              const SizedBox(height: 16),
              const Text(
                "SAMS LOGIN",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFE67E33),
                ),
              ),
              const SizedBox(height: 32),

              // Input Email
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email address",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 16),

              // Input Password
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 24),

              // --- DROPDOWN ROLE ---
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: "Login As",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_pin_rounded),
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
              const SizedBox(height: 20),

              // Butang Login
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE67E33),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "LOGIN",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterScreen(),
                    ),
                  );
                },
                child: const Text("Don't have an account? Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
