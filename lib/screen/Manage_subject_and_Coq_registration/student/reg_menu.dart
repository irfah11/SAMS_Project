import 'package:flutter/material.dart';
// Ensure this path matches your folder structure exactly

import 'course_reg_ approval.dart' show CourseRegApprovalScreen;

class RegMenuScreen extends StatelessWidget {
  const RegMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF64D2EC),
        elevation: 0,
        title: const Text(
          'SAMS',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black, size: 28),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            MenuTile(
              title: 'Course Catalog',
              onTap: () {
                // Future Catalog Logic
              },
            ),
            const SizedBox(height: 15),
            MenuTile(
              title: 'Course Registration Sem 1 2526',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const CourseRegApprovalScreen(semester: 'Sem 1 2526'),
                  ),
                );
              },
            ),
            const SizedBox(height: 15),
            MenuTile(
              title: 'Course Registration Sem 2 2526',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const CourseRegApprovalScreen(semester: 'Sem 2 2526'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class MenuTile extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const MenuTile({super.key, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F1F1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
        ),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
