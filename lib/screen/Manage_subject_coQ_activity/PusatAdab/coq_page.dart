import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sams/screen/Manage_subject_and_Coq_registration/PusatAdab/list_coq.dart';

class CoQPage extends StatelessWidget {
  final String coqId;
  final String activityName;
  final String location;
  final String lecturerName;
  final int bookingQuota;

  const CoQPage({
    super.key,
    required this.coqId,
    required this.activityName,
    required this.location,
    required this.lecturerName,
    required this.bookingQuota,
  });

  /// UPDATE CREDIT STATUS
  Future<void> updateCreditStatus(String studentId, String status) async {
    await FirebaseFirestore.instance
        .collection('coq_sessions')
        .doc(coqId)
        .collection('students')
        .doc(studentId)
        .update({'creditStatus': status});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SAMS")),

      body: Column(
        children: [
          // ================= SESSION INFO =================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.grey.shade200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activityName),
                Text("CoQ ID: $coqId"),
                Text("Quota: $bookingQuota"),
                Text("Location: $location"),
                Text("Lecturer: $lecturerName"),
              ],
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            "Student List",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          // ================= FIREBASE STREAM =================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('coq_sessions')
                  .doc(coqId)
                  .collection('students')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final students = snapshot.data!.docs;

                return SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text("No")),
                      DataColumn(label: Text("ID")),
                      DataColumn(label: Text("Name")),
                      DataColumn(label: Text("Attendance")),
                      DataColumn(label: Text("Credit Claim")),
                    ],
                    rows: List.generate(students.length, (index) {
                      final data = students[index];
                      final studentId = data.id;

                      return DataRow(
                        cells: [
                          DataCell(Text("${index + 1}")),
                          DataCell(Text(data['studentId'] ?? '')),
                          DataCell(Text(data['name'] ?? '')),

                          // ATTENDANCE
                          DataCell(
                            Chip(
                              label: Text(data['attendance'] ?? 'UNKNOWN'),
                              backgroundColor: data['attendance'] == 'PRESENT'
                                  ? Colors.green[200]
                                  : Colors.red[200],
                            ),
                          ),

                          // APPROVE / REJECT
                          DataCell(
                            Row(
                              children: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  onPressed: () {
                                    updateCreditStatus(studentId, "Approved");
                                  },
                                  child: const Text("Approve"),
                                ),
                                const SizedBox(width: 5),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  onPressed: () {
                                    updateCreditStatus(studentId, "Rejected");
                                  },
                                  child: const Text("Reject"),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
