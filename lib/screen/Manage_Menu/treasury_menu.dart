import 'package:flutter/material.dart';

class TreasuryMenu extends StatelessWidget {
  const TreasuryMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20),
            color: const Color(0xFF4ED471), // Hijau Treasury
            child: const Text(
              'SAMS',
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(Icons.home_outlined, 'Home', context),
                _buildMenuItem(
                  Icons.book_outlined,
                  'Registration Course',
                  context,
                ),
                _buildMenuItem(Icons.bookmark_border, 'My Course', context),
                _buildMenuItem(Icons.emoji_events_outlined, 'My Co-Q', context),
                _buildMenuItem(Icons.attach_money, 'Student Record', context),
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
}
