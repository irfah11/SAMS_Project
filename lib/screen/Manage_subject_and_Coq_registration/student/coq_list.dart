import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../Controller/Manage_Coq_and_Subject_Registration/RegistrationController.dart';

class CoqListScreen extends StatefulWidget {
  const CoqListScreen({super.key});

  @override
  State<CoqListScreen> createState() => _CoqListScreenState();
}

class _CoqListScreenState extends State<CoqListScreen> {
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

  Future<void> _drop(String regId, String activityName) async {
    try {
      await _controller.dropCoQRegistration(regId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dropped "$activityName".')),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. My Co-Q Header
                  Row(
                    children: const [
                      Icon(Icons.military_tech_outlined, size: 60),
                      SizedBox(width: 15),
                      Text(
                        'MY Co-Q',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // 2. Section Title
                  const Text(
                    'Booking List',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 20),

                  // 3. Booking cards
                  if (_studentId == null)
                    _buildEmptyState(
                      'Your profile is missing a "student_id" field.',
                    )
                  else
                    Expanded(
                      child: StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _controller.studentCoQRegistrationsStream(_studentId!),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          final regs = snapshot.data ?? [];
                          if (regs.isEmpty) {
                            return _buildEmptyState('No Co-Q activities booked yet.');
                          }
                          return ListView.builder(
                            itemCount: regs.length,
                            itemBuilder: (context, index) =>
                                _buildBookingCard(regs[index]),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> reg) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFD976E1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reg['activity_name'] as String? ?? 'Unknown Activity',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 15),
          _buildDetailRow('Location', reg['location'] as String? ?? '-'),
          _buildDetailRow('Advisor', reg['lecturer_name'] as String? ?? '-'),
          const SizedBox(height: 10),

          // Drop Button
          Align(
            alignment: Alignment.bottomRight,
            child: ElevatedButton(
              onPressed: () => _drop(
                reg['reg_id'] as String,
                reg['activity_name'] as String? ?? 'this activity',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC64444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
              ),
              child: const Text('Drop'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          const Text(': ', style: TextStyle(fontSize: 14)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Center(
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined, size: 64, color: Colors.black26),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
