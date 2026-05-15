import 'package:flutter/material.dart';
import 'package:sams/screen/Manage_subject_and_Coq_registration/FacultyRegistrar/delete_course.dart';
import 'package:sams/screen/Manage_subject_and_Coq_registration/FacultyRegistrar/edit_course.dart';

class ListCourse extends StatelessWidget {
  const ListCourse({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE67E33), // Oren Faculty
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
            icon: const Icon(Icons.menu, color: Colors.black, size: 30),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Butang + Add
              Align(
                alignment: Alignment.topRight,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Kembali ke skrin Register Course
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A69FF), // Biru
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '+ Add',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Senarai Kad Kursus - Sekarang menghantar 'context'
              _buildCourseCard(
                context: context,
                title: 'Software Engineering Practice',
                section: '01',
                lab: '01A , 01B',
                lecture: 'MUHAMMAD ZULFAHMI TOH',
                time: '2.00 pm - 4.00 pm',
                capacity: '60',
                cardColor: const Color(0xFFD182F3), // Ungu
              ),
              const SizedBox(height: 15),
              _buildCourseCard(
                context: context,
                title: 'Software Evolution Maintenance',
                section: '01',
                lab: '01A , 01B',
                lecture: 'AL - FAHIM BIN MUBARAK ALI',
                time: '4.00 pm - 6.00 pm',
                capacity: '60',
                cardColor: const Color(0xFFE557A0), // Pink
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper function - Ditambah 'BuildContext context' ke dalam parameter
  Widget _buildCourseCard({
    required BuildContext context,
    required String title,
    required String section,
    required String lab,
    required String lecture,
    required String time,
    required String capacity,
    required Color cardColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          _buildInfoRow('Section', section),
          _buildInfoRow('Lab', lab),
          _buildInfoRow('Lecture', lecture),
          _buildInfoRow('Time', time),
          _buildInfoRow('Capacity', capacity),
          const SizedBox(height: 15),

          // Butang Edit & Delete
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Butang EDIT
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditCourse(courseName: title),
                    ),
                  );
                },
                child: _buildActionButton('Edit', const Color(0xFF4CAF50)),
              ),

              const SizedBox(width: 10),

              // Butang DELETE
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DeleteCourse(courseName: title),
                    ),
                  );
                },
                child: _buildActionButton('Delete', const Color(0xFFD32F2F)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Text(
        '$label : $value',
        style: const TextStyle(fontSize: 14, color: Colors.black),
      ),
    );
  }

  Widget _buildActionButton(String label, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black45),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
