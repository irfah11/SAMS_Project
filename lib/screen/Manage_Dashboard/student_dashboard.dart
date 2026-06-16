import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../Manage_Menu/student_menu.dart';
import '../Fee/Student/FeePage.dart' show formatMoney, formatDate;
import '../../auth/auth_service.dart';
import '../../auth/login_screen.dart';

class StudentDashboard extends StatelessWidget {
  final String studentId;
  const StudentDashboard({super.key, this.studentId = ''});

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService().logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

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
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.black, size: 32),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Load the logged-in student's real name from Firestore.
                  // Looked up by the student_id field, since not all student
                  // docs are keyed by studentId as their document ID.
                  Flexible(
                    child: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      future: studentId.isEmpty
                          ? null
                          : FirebaseFirestore.instance
                              .collection('student')
                              .where('student_id', isEqualTo: studentId)
                              .limit(1)
                              .get(),
                      builder: (context, snapshot) {
                        String name = 'Student';
                        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                          name = (snapshot.data!.docs.first.data()['full_name'] ??
                                  'Student')
                              .toString();
                        }
                        return Text(
                          'Welcome Back,\n${name.toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            height: 1.2,
                            fontFamily: 'Serif',
                          ),
                        );
                      },
                    ),
                  ),
                  ClipOval(
                    child: Image.network(
                      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR6vI071kHqE_4E8H-PqN7l34Y5YvW44a_9AQ&s',
                      width: 65,
                      height: 65,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 65,
                        height: 65,
                        color: const Color(0xFFE0E0E0),
                        child: const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // Fee payment reminder — only shows for unpaid students.
              _FeeReminderCard(studentId: studentId),

              // Banner 1: Mobility To Philippines
              _buildResponsiveImage('assets/Mobility.jpg'),
              const SizedBox(height: 15),
              _buildResponsiveImage('assets/LarianAmal.jpg'),
              const SizedBox(height: 15),
              _buildResponsiveImage('assets/Programming.jpg'),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveImage(String path) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.asset(path, fit: BoxFit.contain),
      ),
    );
  }
}

// =============================================================
// Fee payment reminder — shown only when the logged-in student has an
// unpaid (or overdue) fee. Reads the student's Fee doc by student_id.
// =============================================================
class _FeeReminderCard extends StatelessWidget {
  final String studentId;
  const _FeeReminderCard({required this.studentId});

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  static DateTime? _toDateOrNull(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (studentId.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('Fee')
          .where('student_id', isEqualTo: studentId)
          .limit(1)
          .get(),
      builder: (context, snapshot) {
        // No fee record yet, still loading, or an error → show nothing.
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!.docs.first.data();
        final status = (data['payment_status'] ?? '').toString();

        // Paid students don't need a reminder.
        if (status.toLowerCase() == 'paid') return const SizedBox.shrink();

        final dueWeek = (data['due_week'] ?? '').toString();
        final outstanding = _toDouble(data['total_outstanding']);
        final dueDate = _toDateOrNull(data['due_date']);

        final detail = StringBuffer('Your fee is ');
        if (dueWeek.isNotEmpty) {
          detail.write('due by Week $dueWeek');
          if (dueDate != null) detail.write(' (${formatDate(dueDate)})');
          detail.write('. ');
        }
        if (outstanding > 0) {
          detail.write('Outstanding: RM ${formatMoney(outstanding)}. ');
        }
        detail.write('Unpaid accounts will be blocked automatically.');

        // Timestamp line — hardcoded.
        const stamp = 'Today, 8:00 AM';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF9E9D24), // olive
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Fee payment reminder',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          detail.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          stamp,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}
