import 'package:flutter/material.dart';
import 'package:sams/screen/Manage_Menu/pusat_adab_menu.dart';
import 'package:sams/screen/Manage_subject_and_Coq_registration/PusatAdab/create_module_coq.dart'; // Pastikan path import ini betul mengikut nama fail create module coq awak
import 'package:sams/screen/Manage_subject_and_Coq_registration/PusatAdab/edit_coq.dart';
import 'package:sams/screen/Manage_subject_and_Coq_registration/PusatAdab/delete_coq.dart';

class ListCoQ extends StatelessWidget {
  const ListCoQ({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      drawer: const PusatAdabMenu(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF965E5E), // Maroon Pusat Adab
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'SAMS',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
            fontFamily: 'Serif',
          ),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.black, size: 30),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 1. Butang + Add di bahagian atas kanan
              Align(
                alignment: Alignment.topRight,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateModuleCoQ(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4A69FF), // Biru
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '+ Add',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // 2. Kad Kursus: 3D Modelling (Ungu)
              _buildCoqCard(
                context: context,
                title: '3D Modelling',
                date: '8 / 4 / 2026',
                time: '9.00 pm - 5.00 pm',
                location: 'FTKPM',
                capacity: '60',
                lecturer: 'AINIIN SOFIA',
                cardColor: const Color(0xFFD182F3), // Ungu mengikut gambar
              ),

              const SizedBox(height: 15),

              // 3. Kad Kursus: Chess (Pink)
              _buildCoqCard(
                context: context,
                title: 'Chess',
                date: '10 / 4 / 2026',
                time: '9.00 pm - 5.00 pm',
                location: 'FKOM',
                capacity: '60',
                lecturer: 'NAIM AQASHAH',
                cardColor: const Color(0xFFE557A0), // Pink mengikut gambar
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper function untuk membina kad yang kemas
  Widget _buildCoqCard({
    required BuildContext context,
    required String title,
    required String date,
    required String time,
    required String location,
    required String capacity,
    required String lecturer,
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
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          _buildInfoRow('Date', date),
          _buildInfoRow('Time', time),
          _buildInfoRow('Location', location),
          _buildInfoRow('Capacity', capacity),
          _buildInfoRow('Lecturer', lecturer),

          const SizedBox(height: 15),

          // Barisan Butang Edit & Delete
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Butang Edit (Hijau)
              _buildActionButton('Edit', const Color(0xFF4CAF50), () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditCoQ(
                      courseName: title,
                    ), // Hantar nama kursus (title)
                  ),
                );
              }),
              // Cari bahagian butang Delete di dalam list_coq.dart
              _buildActionButton('Delete', const Color(0xFFD32F2F), () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return DeleteCoQDialog(
                      courseName: title,
                    ); // Panggil skrin dialog
                  },
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
          ),
          const Text(
            ' : ',
            style: TextStyle(fontSize: 14, color: Colors.black),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black45),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
