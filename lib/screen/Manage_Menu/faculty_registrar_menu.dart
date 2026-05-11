import 'package:flutter/material.dart';
import 'package:sams/screen/Manage_subject_and_Coq_registration/FacultyRegistrar/list_course.dart';
// Pastikan path import ini betul mengikut nama fail create course awak
import '../Manage_subject_and_Coq_registration/FacultyRegistrar/create_course.dart';

class FacultyRegistrarMenu extends StatelessWidget {
  const FacultyRegistrarMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header Menu
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20),
            color: const Color(0xFFE67E33), // Oren Faculty
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
                _buildMenuItem(Icons.home_outlined, 'Home', context, () {
                  Navigator.pop(context);
                }),

                // ExpansionTile untuk Dropdown
                ExpansionTile(
                  leading: const Icon(Icons.book_outlined, color: Colors.black),
                  title: const Text(
                    'Registration Course',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  children: [
                    // PANGGIL fungsi sub menu di sini
                    _buildSubMenuItem('Create Course Subject', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CreateCourse(),
                        ),
                      );
                    }),
                    _buildSubMenuItem('Listing Course', () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ListCourse(),
                        ),
                      );
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

  // Fungsi untuk Menu Utama (Dah diupdate ada VoidCallback)
  Widget _buildMenuItem(
    IconData icon,
    String title,
    BuildContext context,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }

  // Fungsi untuk Sub-Menu (Dah diupdate ada VoidCallback)
  Widget _buildSubMenuItem(String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(left: 70.0),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        onTap: onTap,
      ),
    );
  }
}
