import 'package:flutter/material.dart';
import '../../Manage_Menu/student_menu.dart';
import 'reg_menu.dart'; // Pastikan anda mengimport fail reg_menu.dart

class CourseRegDashboardScreen extends StatelessWidget {
  final String studentId;
  const CourseRegDashboardScreen({super.key, this.studentId = ''});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: StudentDrawer(studentId: studentId),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5CE1E6),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'SAMS',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 28,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.black, size: 32),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Ikon Bulat Menu yang kini boleh diklik
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegMenuScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(50), // Efek klik membulat
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFBCE3DC),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.list, size: 35, color: Colors.black87),
              ),
            ),
            const SizedBox(height: 25),

            // 2. Tajuk Halaman beserta Ikon Buku
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.menu_book_outlined,
                  size: 55,
                  color: Colors.black,
                ),
                const SizedBox(width: 15),
                const Expanded(
                  child: Text(
                    'Open\nRegistration\nCourse',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      height: 1.1,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 35),

            // 3. Kotak Perhatian / Notifikasi
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFC7E2DC),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Attention Student',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildBulletPoint(
                    'you are not allowed to open multiple tab at one time. system will automatically logout',
                  ),
                  const SizedBox(height: 8),
                  _buildBulletPoint(
                    'any unethical behavior are recorded and discipline action will be taken to against you',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '• ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }
}
