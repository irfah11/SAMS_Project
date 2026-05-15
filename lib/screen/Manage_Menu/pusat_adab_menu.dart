import 'package:flutter/material.dart';
import 'package:sams/screen/Manage_subject_and_Coq_registration/PusatAdab/create_module_coq.dart';
import 'package:sams/screen/Manage_subject_and_Coq_registration/PusatAdab/list_coq.dart';

class PusatAdabMenu extends StatelessWidget {
  const PusatAdabMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header Menu dengan warna Maroon
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20),
            color: const Color(0xFF965E5E),
            child: const Text(
              'SAMS',
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Serif',
              ),
            ),
          ),

          // List Menu
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(Icons.home_outlined, 'Home', context),
                _buildMenuItem(
                  Icons.book_outlined,
                  'Registration Co-Q',
                  context,
                ),

                // ExpansionTile untuk Dropdown "Co-Q"
                ExpansionTile(
                  leading: const Icon(
                    Icons.emoji_events_outlined,
                    color: Colors.black,
                  ),
                  title: const Text(
                    'Co-Q',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  children: [
                    // Kemas kini bahagian ini:
                    _buildSubMenuItem('Create Course Subject', () {
                      Navigator.pop(context); // Tutup drawer dahulu
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateModuleCoQ(),
                        ),
                      );
                    }),
                    _buildSubMenuItem('Listing Course', () {
                      Navigator.pop(context); // Tutup drawer dahulu
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ListCoQ(),
                        ),
                      );
                    }),
                  ],
                ),

                // ExpansionTile untuk Dropdown "Attendance"
                ExpansionTile(
                  leading: const Icon(
                    Icons.people_outline,
                    color: Colors.black,
                  ),
                  title: const Text(
                    'Attendance',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  children: [
                    _buildSubMenuItem('View Attendance', () {
                      // Implementation for viewing attendance
                    }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: () => Navigator.pop(context),
    );
  }

  Widget _buildSubMenuItem(String title, VoidCallback onTap) {
    // Tambah parameter onTap
    return Padding(
      padding: const EdgeInsets.only(left: 70.0),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        onTap: onTap, // Gunakan parameter onTap di sini
      ),
    );
  }
}
