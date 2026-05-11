import 'package:flutter/material.dart';

class FacultyRegistrarMenu extends StatelessWidget {
  const FacultyRegistrarMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header Menu dengan warna Oren Faculty Registrar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20),
            color: const Color(0xFFE67E33), // Warna Oren
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

                // ExpansionTile untuk Dropdown "Registration Course"
                ExpansionTile(
                  leading: const Icon(Icons.book_outlined, color: Colors.black),
                  title: const Text(
                    'Registration Course',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  children: [
                    _buildSubMenuItem('Create Course Subject'),
                    _buildSubMenuItem('Listing Course'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Fungsi untuk Menu Utama
  Widget _buildMenuItem(IconData icon, String title, BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: () {
        // Navigasi atau tutup drawer
        Navigator.pop(context);
      },
    );
  }

  // Fungsi untuk Sub-Menu (Dropdown)
  Widget _buildSubMenuItem(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 70.0,
      ), // Jarak ke dalam untuk sub-menu
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        onTap: () {
          // Tambah navigasi ke fungsi spesifik di sini nanti
        },
      ),
    );
  }
}
