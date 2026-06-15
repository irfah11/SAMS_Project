import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../Controller/Manage Attendance/AttendanceController.dart';
import '../../../widgets/card_image.dart';
import 'ClassCo-Q.dart';

class PusatAdabCoQListScreen extends StatelessWidget {
  const PusatAdabCoQListScreen({super.key});

  static const _maroon = Color(0xFF965E5E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _maroon,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: const [
                Icon(Icons.people_outline, size: 32),
                SizedBox(width: 10),
                Text(
                  'View  Attendance',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            StreamBuilder<QuerySnapshot>(
              stream: fetchCoQModules(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }
                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildModuleCard(
                      context,
                      coqId:
                          (data['coq_id'] as String?)?.trim().isNotEmpty == true
                              ? data['coq_id'] as String
                              : doc.id,
                      docId: doc.id,
                      activityName:
                          data['activity_name'] as String? ?? 'Unknown Activity',
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// SDD fetchCoQModules() — live stream of all Co-Q modules.
  Stream<QuerySnapshot> fetchCoQModules() =>
      AttendanceController.coqModulesStream();

  /// SDD onModuleSelected(coqID) — open the class list for the chosen module.
  void onModuleSelected(
      BuildContext context, String coqId, String activityName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PusatAdabClassCoQScreen(
          coqId: coqId,
          activityName: activityName,
        ),
      ),
    );
  }

  Widget _buildModuleCard(
    BuildContext context, {
    required String coqId,
    required String docId,
    required String activityName,
  }) {
    return GestureDetector(
      onTap: () => onModuleSelected(context, docId, '$coqId  $activityName'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(18),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            const CardImageBanner(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                children: [
                  Text(
                    coqId,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activityName.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.only(top: 40),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.black26),
            SizedBox(height: 16),
            Text(
              'No Co-Q modules found.',
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
            SizedBox(height: 8),
            Text(
              'Co-Q modules registered by Pusat Adab will appear here.',
              style: TextStyle(fontSize: 13, color: Colors.black38),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
