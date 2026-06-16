import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sams/Controller/manage_coq_activity/subject_controller.dart';
import 'package:sams/screen/Manage_Menu/lecture_menu.dart';
import 'package:sams/screen/Manage_subject_coQ_activity/Lecturer/lecturer_subject_page.dart';

class LecturerDashboard extends StatelessWidget {
  const LecturerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),

      appBar: AppBar(
        backgroundColor: const Color(0xFF446BE6),
        elevation: 0,
        title: const Text(
          'SAMS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 24,
          ),
        ),
      ),

      // ✅ FIX: guna ListView (lebih stable dari SingleChildScrollView + GridView)
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Subject',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'My Course',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4B5563),
            ),
          ),

          const SizedBox(height: 12),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
            children: [
              _buildCourseCard(
                context,
                code: 'BCS3133',
                title: 'Software Engineering\nProcess',
                color: const Color(0xFFE5E7EB),
              ),
              _buildCourseCard(
                context,
                code: 'BCS2313',
                title: 'Artificial Intelligence\nTechniques',
                color: const Color(0xFFD1D5DB),
              ),
            ],
          ),

          const SizedBox(height: 30),

          const Text(
            'My Co-Q',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4B5563),
            ),
          ),

          const SizedBox(height: 12),

          _buildCourseCard(
            context,
            code: 'HQD3012',
            title: '3D Design + 3D Printing',
            color: const Color(0xFF10B981),
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(
    BuildContext context, {
    required String code,
    required String title,
    required Color color,
    bool fullWidth = false,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LecturerSubjectPage(
              subjectId: code, // sementara guna code (atau tukar Firestore ID)
              subjectCode: code,
              subjectName: title.replaceAll('\n', ' '),
            ),
          ),
        );
      },

      child: Container(
        width: fullWidth ? double.infinity : null,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),

        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 10),

              Text(
                code,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 5),

              Text(
                title.replaceAll('\n', ' '),
                style: const TextStyle(fontSize: 12, color: Color(0xFF1F2937)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
