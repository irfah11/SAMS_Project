import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sams/Controller/Manage_Coq_and_Subject_Registration/RegistrationController.dart';
import 'package:sams/screen/Manage_Menu/student_menu.dart';

class CoqListScreen extends StatefulWidget {
  const CoqListScreen({super.key});

  @override
  State<CoqListScreen> createState() => _CoqListScreenState();
}

class _CoqListScreenState extends State<CoqListScreen> {
  final RegistrationController _controller = RegistrationController();

  final String currentStudentId = "CB23041";

  String _toText(dynamic value) {
    if (value == null) return '-';

    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }

    return value.toString();
  }

  String _toTimeText(dynamic value) {
    if (value == null) return '-';

    if (value is Timestamp) {
      final date = value.toDate();
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }

    return value.toString();
  }

  Future<void> _handleDrop({
    required String registrationDocId,
    required String moduleDocId,
  }) async {
    try {
      await _controller.dropCoQ(
        registrationDocId: registrationDocId,
        moduleDocId: moduleDocId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Co-Q registration dropped.")),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to drop: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const StudentDrawer(),

      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF55D3E7),
        elevation: 0,
        toolbarHeight: 64,
        titleSpacing: 27,
        title: const Text(
          'SAMS',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 24,
            letterSpacing: 1.5,
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

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 20, 16, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.workspace_premium_outlined, size: 58),
                SizedBox(width: 14),
                Text(
                  'MY Co-Q',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Text(
              'Booking List',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),

            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot>(
              stream: _controller.getStudentCoQRegistrations(currentStudentId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final regDocs = snapshot.data?.docs ?? [];

                if (regDocs.isEmpty) {
                  return const Text(
                    "You have not registered any Co-Q yet.",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  );
                }

                return Column(
                  children: List.generate(regDocs.length, (index) {
                    final doc = regDocs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final String moduleDocId =
                        _toText(data['module_doc_id']) == '-'
                        ? ''
                        : _toText(data['module_doc_id']);

                    return _buildBookingCard(
                      activityName: _toText(data['activity_name']),
                      date: _toText(data['date']),
                      time: _toTimeText(data['time']),
                      location: _toText(data['location']),
                      lecturer: _toText(data['lecturer_name']),
                      onDrop: () {
                        if (moduleDocId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Module ID missing.")),
                          );
                          return;
                        }

                        _handleDrop(
                          registrationDocId: doc.id,
                          moduleDocId: moduleDocId,
                        );
                      },
                    );
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard({
    required String activityName,
    required String date,
    required String time,
    required String location,
    required String lecturer,
    required VoidCallback onDrop,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFD768D8),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activityName,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 8),

                _infoLine("Date", date),
                _infoLine("Time", time),
                _infoLine("Location", location),
                _infoLine("Lecturer", lecturer),
              ],
            ),
          ),

          Positioned(
            right: 0,
            bottom: 0,
            child: SizedBox(
              width: 42,
              height: 26,
              child: ElevatedButton(
                onPressed: onDrop,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE75B4F),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text("Drop", style: TextStyle(fontSize: 9)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        "$label      :  $value",
        style: const TextStyle(fontSize: 9, color: Colors.black, height: 1.2),
      ),
    );
  }
}
