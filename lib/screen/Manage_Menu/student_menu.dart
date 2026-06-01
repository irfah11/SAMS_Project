import 'package:flutter/material.dart';
import '../Manage_subject_and_Coq_registration/student/coq_list.dart';
import '../Manage_subject_and_Coq_registration/student/reg_dashboard.dart';
// 1. IMPORT the booking screen here
import '../Manage_subject_and_Coq_registration/student/booked_coq.dart';
import '../Fee/Student/FeePage.dart';
import 'package:sams/auth/auth_service.dart';
import 'package:sams/auth/login_screen.dart';

class StudentDrawer extends StatelessWidget {
  final String studentId;
  const StudentDrawer({super.key, this.studentId = ''});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Drawer(
        backgroundColor: Colors.white,
        elevation: 10,
        child: Column(
          children: [
            // Header SAMS
            Container(
              height: 100,
              width: double.infinity,
              color: const Color(0xFF5CE1E6),
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.only(left: 20, bottom: 15),
              child: const Text(
                'SAMS',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            // Senarai Menu
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildMenuItem(
                    context,
                    Icons.home_outlined,
                    'Home',
                    onTap: () => Navigator.pop(context),
                  ),
                  const Divider(
                    height: 1,
                    color: Color(0xFFCCCCCC),
                    indent: 15,
                    endIndent: 15,
                  ),

                  _buildMenuItem(
                    context,
                    Icons.book_outlined,
                    'Open Registration Course',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CourseRegDashboardScreen(studentId: studentId),
                        ),
                      );
                    },
                  ),
                  const Divider(
                    height: 1,
                    color: Color(0xFFCCCCCC),
                    indent: 15,
                    endIndent: 15,
                  ),

                  _buildMenuItem(
                    context,
                    Icons.bookmark_border,
                    'Subject',
                    onTap: () => Navigator.pop(context),
                  ),
                  const Divider(
                    height: 1,
                    color: Color(0xFFCCCCCC),
                    indent: 15,
                    endIndent: 15,
                  ),

                  // --- Dropdown My Co-Q ---
                  _buildDropdownMenu(
                    icon: Icons.military_tech_outlined,
                    title: 'My Co-Q',
                    children: [
                      // Updated with Navigation for Booking Slot
                      _buildSubMenuItem(
                        context,
                        'Booking Slot',
                        onTap: () {
                          Navigator.pop(context); // Close Drawer
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BookedCoqScreen(),
                            ),
                          );
                        },
                      ),
                      _buildSubMenuItem(
                        context,
                        'View Booking List',
                        onTap: () {
                          Navigator.pop(context); // Close Drawer
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CoqListScreen(),
                            ),
                          );
                        },
                      ),
                      _buildSubMenuItem(context, 'Credit Claim Status'),
                    ],
                  ),
                  const Divider(
                    height: 1,
                    color: Color(0xFFCCCCCC),
                    indent: 15,
                    endIndent: 15,
                  ),

                  // Dropdown Attendance
                  _buildDropdownMenu(
                    icon: Icons.people_outline,
                    title: 'Attendance',
                    children: [_buildSubMenuItem(context, 'Check In')],
                  ),
                  const Divider(
                    height: 1,
                    color: Color(0xFFCCCCCC),
                    indent: 15,
                    endIndent: 15,
                  ),

                  // Dropdown Financial Details
                  _buildDropdownMenu(
                    icon: Icons.attach_money,
                    title: 'Financial Details',
                    children: [
                      _buildSubMenuItem(
                        context,
                        'Fee Statement',
                        onTap: () {
                          Navigator.pop(context); // Close Drawer
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  FeePage(studentId: studentId),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const Divider(
                    height: 1,
                    color: Color(0xFFCCCCCC),
                    indent: 15,
                    endIndent: 15,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFCCCCCC)),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () async {
                final navigator = Navigator.of(context);
                await AuthService().logout();
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title, {
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black, size: 28),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildDropdownMenu({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Theme(
      data: ThemeData().copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Icon(icon, color: Colors.black, size: 28),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.black),
        childrenPadding: const EdgeInsets.only(left: 45),
        children: children,
      ),
    );
  }

  // --- Updated SubMenuItem to handle Custom Navigation ---
  Widget _buildSubMenuItem(
    BuildContext context,
    String title, {
    VoidCallback? onTap,
  }) {
    return Column(
      children: [
        const Divider(height: 1, color: Color(0xFFE0E0E0)),
        ListTile(
          title: Text(
            title,
            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),
          onTap:
              onTap ??
              () => Navigator.pop(context), // Default is just to close drawer
        ),
      ],
    );
  }
}
