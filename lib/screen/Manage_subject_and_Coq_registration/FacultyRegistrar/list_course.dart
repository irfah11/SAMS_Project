import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sams/screen/Manage_subject_and_Coq_registration/FacultyRegistrar/delete_course.dart';
import 'package:sams/screen/Manage_subject_and_Coq_registration/FacultyRegistrar/edit_course.dart';
import 'package:sams/screen/Manage_subject_and_Coq_registration/FacultyRegistrar/create_course.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sams/Controller/Manage_Coq_and_Subject_Registration/RegistrationController.dart';
import 'package:sams/Domain/course_subject.dart';

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
          // Butang Add untuk ke skrin pendaftaran
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateCourse()),
              );
            },
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text("Add", style: TextStyle(color: Colors.white)),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFF4A69FF).withOpacity(0.8),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),

      // STREAMBUILDER: Ditukar kepada 'course_subjects' supaya selaras dengan database
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

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No courses registered yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;

              // LOGIK SELAMAT: Menguruskan pemformatan masa daripada Firebase
              String formattedDate = 'No Date';
              String formattedTime = 'No Time';

              if (data['time'] != null) {
                if (data['time'] is Timestamp) {
                  // Jika data baharu daripada Date & Time Picker (Timestamp)
                  DateTime dateTime = (data['time'] as Timestamp).toDate();
                  formattedDate = DateFormat('yyyy-MM-dd').format(dateTime);
                  formattedTime = DateFormat('HH:mm').format(dateTime);
                } else {
                  // Jika data lama berbentuk String (Contoh: "2.00")
                  formattedDate =
                      '16 / 5 / 2026'; // Default statik bagi data lama
                  formattedTime = data['time'].toString();
                }
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['subject_name'] ?? 'No Name',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Paparan maklumat menggunakan pembolehubah yang telah diformat secara selamat
                    _buildInfoRow('Date', ' : $formattedDate'),
                    _buildInfoRow('Time', ' : $formattedTime'),

                    // Menyokong ejaan huruf kecil atau besar bagi data lama/baru di Firebase
                    _buildInfoRow(
                      'Location',
                      ' : ${data['tutorial_lab'] ?? data['TutorialLab'] ?? 'Not Set'}',
                    ),
                    _buildInfoRow('Capacity', ' : ${data['capacity'] ?? 0}'),
                    _buildInfoRow(
                      'Lecturer',
                      ' : ${data['lecturer_name'] ?? data['fullname'] ?? 'No Name'}',
                    ),

                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Cari bahagian ini di dalam list_course.dart anda:
                        _buildActionButton('Edit', Colors.green.shade400, () {
                          // Tukar isi kandungan di sini kepada fungsi navigasi:

                          // Bina objek CourseSubject berdasarkan data doc Firebase untuk dihantar
                          CourseSubject currentCourse = CourseSubject(
                            subjectId: data['subject_id'] ?? doc.id,
                            subjectName: data['subject_name'] ?? 'No Name',
                            section: data['section'] ?? '',
                            tutorialLab:
                                data['tutorial_lab'] ??
                                data['TutorialLab'] ??
                                '',
                            capacity: data['capacity'] ?? 0,
                            time: data['time'] is Timestamp
                                ? (data['time'] as Timestamp).toDate()
                                : DateTime.now(),
                            lecturerName:
                                data['lecturer_name'] ??
                                data['fullname'] ??
                                'No Name',
                          );

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditCourse(course: currentCourse),
                            ),
                          );
                        }),
                        const SizedBox(width: 10),
                        _buildActionButton('Delete', Colors.red.shade400, () {
                          // Tukar isi kandungan di sini untuk navigasi ke Delete Page:

                          String currentSubjectId =
                              data['subject_id'] ??
                              doc.id; // Mengambil ID dokumen Firebase
                          String currentSubjectName =
                              data['subject_name'] ?? 'No Name';

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DeleteCourse(
                                subjectId: currentSubjectId,
                                courseName: currentSubjectName,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Widget pembantu untuk baris maklumat
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // Widget pembantu untuk butang Edit/Delete
  Widget _buildActionButton(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
