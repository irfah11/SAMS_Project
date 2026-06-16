import 'package:flutter/material.dart';
import 'package:sams/auth/auth_service.dart';
import 'package:sams/auth/login_screen.dart';
import 'package:sams/screen/Manage_subject_and_Coq_registration/Lecturer/approval_reg.dart';
// IMPORT DASHBOARD DI SINI
import 'package:sams/screen/Manage_subject_coQ_activity/Lecturer/lecturer_dashboard.dart';

class LecturerDrawer extends StatelessWidget {
  const LecturerDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Drawer(
        backgroundColor: Colors.white,
        elevation: 10,
        child: Column(
          children: [
            // ================= HEADER =================
            Container(
              height: 100,
              width: double.infinity,
              color: const Color(0xFF4C66EE),
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.only(left: 20, bottom: 15),
              child: const Text(
                'SAMS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),

            // ================= MENU =================
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildMenuItem(
                    context,
                    Icons.home_outlined,
                    'Home',
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LecturerDashboard(),
                        ),
                        (route) => false,
                      );
                    },
                  ),

                  const Divider(),

                  _buildMenuItem(
                    context,
                    Icons.menu_book_outlined,
                    'Approval Course Registration',
                    onTap: () {
                      Navigator.pop(context); // Close Drawer
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ApprovalReg()),
                      );
                    },
                  ),

                  const Divider(),

                  // ================= SUBJECT =================
                  _buildMenuItem(
                    context,
                    Icons.bookmark_border,
                    'Subject',
                    onTap: () {
                      Navigator.pop(context); // tutup drawer dulu

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LecturerDashboard(),
                        ),
                      );
                    },
                  ),

                  const Divider(),

                  _buildDropdownMenu(
                    icon: Icons.military_tech_outlined,
                    title: 'My Co-Q',
                    children: [
                      _buildSubMenuItem(context, 'Booking Slot'),
                      _buildSubMenuItem(context, 'View Booking List'),
                    ],
                  ),

                  const Divider(),

                  _buildDropdownMenu(
                    icon: Icons.people_outline,
                    title: 'Attendance',
                    initiallyExpanded: true,
                    children: [
                      _buildSubMenuItem(
                        context,
                        'Manage Attendance',
                        onTap: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(),

            // ================= LOGOUT =================
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
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

  // ================= HELPERS =================
  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    String title, {
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(title),
      onTap: onTap,
    );
  }

  Widget _buildDropdownMenu({
    required IconData icon,
    required String title,
    required List<Widget> children,
    bool initiallyExpanded = false,
  }) {
    return ExpansionTile(
      initiallyExpanded: initiallyExpanded,
      leading: Icon(icon, color: Colors.black),
      title: Text(title),
      children: children,
    );
  }

  Widget _buildSubMenuItem(
    BuildContext context,
    String title, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      title: Text(title),
      onTap: onTap ?? () => Navigator.pop(context),
    );
  }
}
