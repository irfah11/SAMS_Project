import 'package:flutter/material.dart';

import '../Manage_subject_and_Coq_registration/Lecturer/approval_reg.dart';

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
            // 1. Header SAMS (Blue Background)
            Container(
              height: 100,
              width: double.infinity,
              color: const Color(0xFF4C66EE), // Darker blue for Lecturer
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

            // 2. Menu List
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Home
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

                  // Approval Course Registration
                  _buildMenuItem(
                    context,
                    Icons.menu_book_outlined,
                    'Approval Course Registration',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ApprovalReg(),
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

                  // Subject
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

                  // My Co-Q (ExpansionTile)
                  _buildDropdownMenu(
                    icon: Icons.military_tech_outlined,
                    title: 'My Co-Q',
                    children: [
                      _buildSubMenuItem(context, 'Booking Slot'),
                      _buildSubMenuItem(context, 'View Booking List'),
                    ],
                  ),
                  const Divider(
                    height: 1,
                    color: Color(0xFFCCCCCC),
                    indent: 15,
                    endIndent: 15,
                  ),

                  // Attendance (Manage Attendance)
                  _buildDropdownMenu(
                    icon: Icons.people_outline,
                    title: 'Attendance',
                    initiallyExpanded:
                        true, // Shows Manage Attendance by default
                    children: [
                      _buildSubMenuItem(
                        context,
                        'Manage Attendance',
                        onTap: () {
                          Navigator.pop(context);
                          // Navigator.push logic for Manage Attendance goes here
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
          ],
        ),
      ),
    );
  }

  // --- Helper Widgets ---

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
    bool initiallyExpanded = false,
  }) {
    return Theme(
      data: ThemeData().copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        leading: Icon(icon, color: Colors.black, size: 28),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
        ),
        trailing: const Icon(Icons.keyboard_arrow_right, color: Colors.black),
        childrenPadding: const EdgeInsets.only(left: 45),
        children: children,
      ),
    );
  }

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
            style: const TextStyle(color: Colors.black, fontSize: 14),
          ),
          onTap: onTap ?? () => Navigator.pop(context),
        ),
      ],
    );
  }
}
