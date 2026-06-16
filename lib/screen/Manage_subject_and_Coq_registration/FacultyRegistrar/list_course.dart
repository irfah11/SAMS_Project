import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sams/Domain/course_subject.dart';
import 'package:sams/screen/Manage_subject_and_Coq_registration/FacultyRegistrar/create_course.dart';
import 'package:sams/screen/Manage_subject_and_Coq_registration/FacultyRegistrar/edit_course.dart';
import 'package:sams/screen/Manage_subject_and_Coq_registration/FacultyRegistrar/delete_course.dart';
import 'package:sams/screen/Manage_Menu/faculty_registrar_menu.dart';

class ListCourse extends StatelessWidget {
  const ListCourse({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const FacultyRegistrarMenu(),

      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFF36C21),
        elevation: 0,
        toolbarHeight: 64,
        titleSpacing: 24,
        title: const Text(
          'SAMS',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 28,
            letterSpacing: 2,
            shadows: [
              Shadow(
                color: Colors.black38,
                offset: Offset(2, 2),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu, color: Colors.black, size: 32),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('course_subjects')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Column(
              children: [
                _buildAddButton(context),
                const Expanded(
                  child: Center(
                    child: Text(
                      'No courses registered yet.',
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                ),
              ],
            );
          }

          final docs = snapshot.data!.docs;

          return Column(
            children: [
              _buildAddButton(context),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(28, 16, 28, 35),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final Color cardColor = index % 2 == 0
                        ? const Color(0xFFD46BEF)
                        : const Color(0xFFE34DA7);

                    return _buildCourseCard(
                      context: context,
                      docId: doc.id,
                      data: data,
                      color: cardColor,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, right: 18),
      child: Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: 58,
          height: 31,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateCourse()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3F63D7),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
                side: const BorderSide(color: Colors.black54, width: 1),
              ),
            ),
            child: const Text(
              '+ Add',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCourseCard({
    required BuildContext context,
    required String docId,
    required Map<String, dynamic> data,
    required Color color,
  }) {
    final String subjectId = _toText(data['subject_id'] ?? docId);
    final String subjectName = _toText(data['subject_name']);
    final String section = _toText(data['section']);
    final String lab = _toText(data['tutorial_lab'] ?? data['TutorialLab']);
    final String lecturer = _toText(data['lecturer_name'] ?? data['fullname']);
    final String time = _formatTime(data['time']);
    final int capacity = _toInt(data['capacity']);

    return Container(
      margin: const EdgeInsets.only(bottom: 52),
      padding: const EdgeInsets.fromLTRB(24, 24, 14, 18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 230,
            child: Text(
              subjectName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                height: 1.08,
              ),
            ),
          ),

          const SizedBox(height: 12),

          _buildInfoRow('Section', section),
          _buildInfoRow('Lab', lab),
          _buildInfoRow('Lecture', lecturer),
          _buildInfoRow('Time', time),
          _buildInfoRow('Capacity', capacity.toString()),

          const SizedBox(height: 7),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildActionButton(
                label: 'Edit',
                color: const Color(0xFF4CAF50),
                onTap: () {
                  final CourseSubject currentCourse = CourseSubject(
                    subjectId: subjectId,
                    subjectName: subjectName,
                    section: section,
                    tutorialLab: lab,
                    capacity: capacity,
                    time: _toDateTime(data['time']),
                    lecturerName: lecturer,
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditCourse(course: currentCourse),
                    ),
                  );
                },
              ),

              const SizedBox(width: 14),

              _buildActionButton(
                label: 'Delete',
                color: const Color(0xFFE53935),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DeleteCourse(
                        subjectId: subjectId,
                        courseName: subjectName,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 66,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: Colors.black,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          const Text(
            ': ',
            style: TextStyle(
              fontSize: 12.5,
              color: Colors.black,
              fontWeight: FontWeight.w400,
            ),
          ),

          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                color: Colors.black,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 42,
      height: 31,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: const BorderSide(color: Colors.black54, width: 0.8),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  String _toText(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) return '-';
    return value.toString();
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse((value ?? '0').toString()) ?? 0;
  }

  DateTime _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  String _formatTime(dynamic value) {
    if (value == null) return '-';

    if (value is Timestamp) {
      return _formatTimeFromDateTime(value.toDate());
    }

    if (value is DateTime) {
      return _formatTimeFromDateTime(value);
    }

    return value.toString();
  }

  String _formatTimeFromDateTime(DateTime date) {
    int hour = date.hour;
    final int minute = date.minute;

    final String period = hour >= 12 ? 'pm' : 'am';

    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour = hour - 12;
    }

    final String minuteText = minute.toString().padLeft(2, '0');

    return '$hour.$minuteText $period';
  }
}
