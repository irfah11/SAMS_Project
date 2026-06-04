import 'package:flutter/material.dart';
import 'package:sams/auth/auth_service.dart';
import 'package:sams/auth/login_screen.dart';
import 'package:sams/screen/Fee/Treasury/TreasuryDashboardPage.dart';

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
                _buildMenuItem(
                  Icons.attach_money,
                  'Student Record',
                  context,
                  onTap: () {
                    Navigator.pop(context); // close the drawer
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TreasuryDashboardPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFCCCCCC)),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(
                color: Colors.red,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () async {
              final navigator = Navigator.of(context);
              await AuthService().logout();
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    BuildContext context, {
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap ?? () => Navigator.pop(context),
    );
  }
}
