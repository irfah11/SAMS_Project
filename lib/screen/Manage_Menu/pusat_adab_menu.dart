import 'package:flutter/material.dart';

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
                    _buildSubMenuItem('Create Course Subject'),
                    _buildSubMenuItem('Listing Course'),
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
                  children: [_buildSubMenuItem('View Attendance')],
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

  Widget _buildSubMenuItem(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 70.0),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        onTap: () {},
      ),
    );
  }
}
