import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sams/Domain/module_coq.dart';
import 'create_module_coq.dart';
import 'edit_coq.dart';
import 'delete_coq.dart';
import 'package:sams/screen/Manage_subject_coQ_activity/PusatAdab/coq_page.dart';

class ListCoQ extends StatelessWidget {
  const ListCoQ({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE67E33), // Warna oren tema SAMS anda
        elevation: 0,
        title: const Text(
          'Pusat Adab - CoQ List',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateModuleCoQ(),
                ),
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('module_coq').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(child: Text('Something went wrong'));
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty)
            return const Center(
              child: Text('No Co-Q activities registered yet.'),
            );

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];

              // ✅ convert to domain model
              ModuleCoQ coq = ModuleCoQ.fromFirebase(
                doc.data() as Map<String, dynamic>,
              );

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CoQPage(
                        coqId: coq.coqId,
                        activityName: coq.activityName,
                        location: coq.location,
                        lecturerName: coq.lecturerName,
                        bookingQuota: coq.bookingQuota,
                      ),
                    ),
                  );
                },

                child: Container(
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
                        coq.activityName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 10),

                      _buildInfoRow('Co-Q ID', ' : ${coq.coqId}'),
                      _buildInfoRow('Quota', ' : ${coq.bookingQuota} slots'),
                      _buildInfoRow('Location', ' : ${coq.location}'),
                      _buildInfoRow('Advisor', ' : ${coq.lecturerName}'),

                      const SizedBox(height: 15),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildActionButton('Edit', Colors.green.shade400, () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditCoQ(coq: coq),
                              ),
                            );
                          }),

                          const SizedBox(width: 10),

                          _buildActionButton('Delete', Colors.red.shade400, () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DeleteCoQ(
                                  coqId: coq.coqId,
                                  activityName: coq.activityName,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

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
