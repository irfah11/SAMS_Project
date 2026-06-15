import 'package:flutter/material.dart';
import '../../Manage_Menu/student_menu.dart';
import 'reg_menu.dart';

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
        toolbarHeight: 64,
        titleSpacing: 24,
        title: const Text(
          'SAMS',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 28,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu, color: Colors.black, size: 34),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 22.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Menu circle button
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RegMenuScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(50),
              child: Container(
                padding: const EdgeInsets.all(13),
                decoration: const BoxDecoration(
                  color: Color(0xFFBCE3DC),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.list, size: 34, color: Colors.black87),
              ),
            ),

            const SizedBox(height: 34),

            // Page title with custom outline book icon
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  OpenBookIcon(size: 62),
                  SizedBox(width: 18),
                  Text(
                    'Open\nRegistration\nCourse',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      height: 1.1,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 38),

            // Attention box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 18, 20),
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
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),

                  const SizedBox(height: 12),

                  _buildBulletPoint(
                    'you are not allowed to open multiple tab at one time. system will automatically logout',
                  ),

                  const SizedBox(height: 9),

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

// Custom book icon to match Figma style better
class OpenBookIcon extends StatelessWidget {
  final double size;

  const OpenBookIcon({super.key, this.size = 60});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _OpenBookPainter()),
    );
  }
}

class _OpenBookPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3.1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    // Left page
    final leftPage = Path()
      ..moveTo(w * 0.08, h * 0.22)
      ..lineTo(w * 0.40, h * 0.22)
      ..quadraticBezierTo(w * 0.50, h * 0.22, w * 0.50, h * 0.34)
      ..lineTo(w * 0.50, h * 0.78)
      ..quadraticBezierTo(w * 0.35, h * 0.66, w * 0.08, h * 0.72)
      ..close();

    // Right page
    final rightPage = Path()
      ..moveTo(w * 0.92, h * 0.22)
      ..lineTo(w * 0.60, h * 0.22)
      ..quadraticBezierTo(w * 0.50, h * 0.22, w * 0.50, h * 0.34)
      ..lineTo(w * 0.50, h * 0.78)
      ..quadraticBezierTo(w * 0.65, h * 0.66, w * 0.92, h * 0.72)
      ..close();

    canvas.drawPath(leftPage, paint);
    canvas.drawPath(rightPage, paint);

    // Center fold
    canvas.drawLine(
      Offset(w * 0.50, h * 0.32),
      Offset(w * 0.50, h * 0.80),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
