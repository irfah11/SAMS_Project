import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../Controller/Manage Attendance/AttendanceController.dart';
import '../../../Controller/Manage_Coq_and_Subject_Registration/RegistrationController.dart';
import '../../../Domain/module_coq.dart';

class BookedCoqScreen extends StatefulWidget {
  const BookedCoqScreen({super.key});

  @override
  State<BookedCoqScreen> createState() => _BookedCoqScreenState();
}

class _BookedCoqScreenState extends State<BookedCoqScreen> {
  final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final RegistrationController _controller = RegistrationController();

  bool _isLoading = true;
  String? _studentId;

  @override
  void initState() {
    super.initState();
    _loadStudentId();
  }

  Future<void> _loadStudentId() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .get();
    _studentId = userDoc.data()?['student_id'] as String?;
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _book(ModuleCoQ coq) async {
    try {
      await _controller.registerForCoQ(_studentId!, coq);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booked "${coq.activityName}" successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF64D2EC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'SAMS',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. My Co-Q Header with Badge Icon
                  Row(
                    children: const [
                      Icon(Icons.military_tech_outlined, size: 60),
                      SizedBox(width: 15),
                      Text(
                        'MY Co-Q',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // 2. Section Title
                  const Text(
                    'Booking Slot',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _studentId != null
                        ? 'Student ID: $_studentId'
                        : 'Your profile is missing a "student_id" field.',
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 15),

                  // 3. Available Co-Q activities
                  StreamBuilder<QuerySnapshot>(
                    stream: AttendanceController.coqModulesStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.only(top: 20),
                          child: Center(
                            child: Text('No Co-Q activities available yet.'),
                          ),
                        );
                      }
                      return Column(
                        children: snapshot.data!.docs.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final coq = ModuleCoQ(
                            coqId: data['coq_id'] ?? doc.id,
                            activityName:
                                data['activity_name'] ?? 'Unknown Activity',
                            bookingQuota: data['booking_quota'] ?? 0,
                            location: data['location'] ?? '-',
                            lecturerName: data['lecturer_name'] ?? '-',
                          );
                          return _buildCoQCard(coq);
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCoQCard(ModuleCoQ coq) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F7FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coq.activityName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Location: ${coq.location}',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                Text(
                  'Advisor: ${coq.lecturerName}',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                Text(
                  'Quota: ${coq.bookingQuota} slots',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: _studentId == null ? null : () => _book(coq),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF81D4FA),
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Book'),
          ),
        ],
      ),
    );
  }
}
