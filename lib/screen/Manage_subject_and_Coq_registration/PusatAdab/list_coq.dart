import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sams/Domain/module_coq.dart';
import 'create_module_coq.dart';
import 'edit_coq.dart';
import 'delete_coq.dart';

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
              var data = doc.data() as Map<String, dynamic>;

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
                      data['activity_name'] ?? 'No Name',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildInfoRow('Co-Q ID', ' : ${data['coq_id'] ?? doc.id}'),
                    _buildInfoRow(
                      'Quota',
                      ' : ${data['booking_quota'] ?? 0} slots',
                    ),
                    _buildInfoRow(
                      'Location',
                      ' : ${data['location'] ?? 'Not Set'}',
                    ),
                    _buildInfoRow(
                      'Advisor',
                      ' : ${data['lecturer_name'] ?? 'No Advisor'}',
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildActionButton('Edit', Colors.green.shade400, () {
                          ModuleCoQ currentCoQ = ModuleCoQ(
                            coqId: data['coq_id'] ?? doc.id,
                            activityName: data['activity_name'] ?? 'No Name',
                            bookingQuota: data['booking_quota'] ?? 0,
                            location: data['location'] ?? '',
                            lecturerName: data['lecturer_name'] ?? 'No Advisor',
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditCoQ(coq: currentCoQ),
                            ),
                          );
                        }),
                        const SizedBox(width: 10),
                        _buildActionButton('Delete', Colors.red.shade400, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DeleteCoQ(
                                coqId: data['coq_id'] ?? doc.id,
                                activityName:
                                    data['activity_name'] ?? 'No Name',
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
