import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';
import 'register_screen.dart';
import 'seed_demo_data.dart';

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
  bool _isSettingUp = false;
  bool _isSeeding = false;
  String _selectedRole = 'student'; // Default role
  final List<String> _roles = [
    'student',
    'lecturer',
    'registrar',
    'adab',
    'treasury',
  ];

  // Test accounts to create
  static const _testAccounts = [
    {'email': 'student@sams.com',    'password': 'sams1234', 'role': 'student',    'name': 'Test Student',       'student_id': 'CB23028', 'lecturer_id': ''},
    {'email': 'lecturer@sams.com',   'password': 'sams1234', 'role': 'lecturer',   'name': 'Test Lecturer',      'student_id': '',        'lecturer_id': '1002'},
    {'email': 'adab@sams.com',       'password': 'sams1234', 'role': 'adab',       'name': 'Pusat Adab Staff',   'student_id': '',        'lecturer_id': ''},
    {'email': 'registrar@sams.com',  'password': 'sams1234', 'role': 'registrar',  'name': 'Faculty Registrar',  'student_id': '',        'lecturer_id': ''},
    {'email': 'treasury@sams.com',   'password': 'sams1234', 'role': 'treasury',   'name': 'Treasury Staff',     'student_id': '',        'lecturer_id': ''},
  ];

  Future<void> _setupTestAccounts() async {
    setState(() => _isSettingUp = true);
    int created = 0;
    int skipped = 0;

    for (final acc in _testAccounts) {
      try {
        // Register in Firebase Auth
        final user = await _authService.register(acc['email']!, acc['password']!, acc['role']!);
        if (user != null) {
          // Create Firestore user document with role + linked IDs
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
            'email':       acc['email'],
            'name':        acc['name'],
            'role':        acc['role'],
            if ((acc['student_id'] ?? '').isNotEmpty)
              'student_id': acc['student_id'],
            if ((acc['lecturer_id'] ?? '').isNotEmpty)
              'lecturer_id': int.tryParse(acc['lecturer_id']!) ?? acc['lecturer_id'],
          });
          created++;
        } else {
          skipped++; // Already exists
        }
      } catch (_) {
        skipped++; // Already exists or other error
      }
    }

    // Sign out after setup so user can log in fresh
    await _authService.logout();

    if (mounted) {
      setState(() => _isSettingUp = false);
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Test Accounts Ready'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Created: $created  |  Already existed: $skipped'),
              const SizedBox(height: 16),
              const Text('Use these credentials to log in:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _credRow('Student',    'student@sams.com'),
              _credRow('Lecturer',   'lecturer@sams.com'),
              _credRow('Pusat Adab', 'adab@sams.com'),
              _credRow('Registrar',  'registrar@sams.com'),
              _credRow('Treasury',   'treasury@sams.com'),
              const SizedBox(height: 8),
              const Text('Password for all: sams1234',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.green)),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE67E33),
                foregroundColor: Colors.white,
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _seedDemoData() async {
    setState(() => _isSeeding = true);
    String summary;
    try {
      summary = await SeedDemoData.run();
    } catch (e) {
      summary = 'Error while seeding: $e';
    }
    if (!mounted) return;
    setState(() => _isSeeding = false);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Demo Data Ready'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(summary, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 12),
              const Text('Lecturers',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...SeedDemoData.lecturers.map((l) =>
                  _credRow(l['name'] as String, l['email'] as String)),
              const SizedBox(height: 8),
              const Text('Students',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...SeedDemoData.students.map((s) => _credRow(
                  '${s['name']} (${s['student_id']})', s['email'] as String)),
              const SizedBox(height: 8),
              const Text('Pusat Adab',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...SeedDemoData.pusatAdab.map((a) =>
                  _credRow(a['name'] as String, a['email'] as String)),
              const SizedBox(height: 8),
              const Text('Password for all: sams1234',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.green)),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE67E33),
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _credRow(String role, String email) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 90,
              child: Text(role,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.black54)),
            ),
            Expanded(
              child: Text(email,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      );

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
                initialValue: _selectedRole,
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

              const Divider(height: 32),

              // ── DEV ONLY: Create test accounts automatically ──
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: _isSettingUp ? null : _setupTestAccounts,
                  icon: _isSettingUp
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.build_outlined, size: 18),
                  label: Text(
                    _isSettingUp ? 'Creating accounts...' : 'Setup Test Accounts',
                    style: const TextStyle(fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'First time? Tap above to create all test accounts automatically.',
                style: TextStyle(fontSize: 11, color: Colors.black38),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // ── DEV ONLY: Seed full demo dataset (users + attendance data) ──
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: _isSeeding ? null : _seedDemoData,
                  icon: _isSeeding
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.dataset_outlined, size: 18),
                  label: Text(
                    _isSeeding ? 'Seeding demo data...' : 'Seed Demo Data',
                    style: const TextStyle(fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE67E33),
                    side: const BorderSide(color: Color(0xFFE67E33)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '2 lecturers, 5 students, 2 Pusat Adab, 3 subjects + Co-Q, with sessions & records.',
                style: TextStyle(fontSize: 11, color: Colors.black38),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
