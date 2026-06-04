import 'package:flutter/material.dart';
import '../Manage Attendance/Pusat Adab/Co-QList.dart';
import '../../auth/auth_service.dart';
import '../../auth/login_screen.dart';

import '../Manage_Menu/pusat_adab_menu.dart';

class PusatAdabDashboard extends StatelessWidget {
  const PusatAdabDashboard({super.key});

  void _logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService().logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: _buildDrawer(context),
      appBar: AppBar(
        backgroundColor: const Color(0xFF965E5E),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'SAMS',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 28,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            tooltip: 'Logout',
            onPressed: () => _logout(context),
          ),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.black, size: 32),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Welcome Back,\nNURUL BALQIS',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      height: 1.2,
                      fontFamily: 'Serif',
                    ),
                  ),
                  ClipOval(
                    child: Image.network(
                      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR6vI071kHqE_4E8H-PqN7l34Y5YvW44a_9AQ&s',
                      width: 65,
                      height: 65,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 65,
                        height: 65,
                        color: const Color(0xFFE0E0E0),
                        child: const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              _buildEventBanner('assets/Mobility.jpg'),
              const SizedBox(height: 15),
              _buildEventBanner('assets/LarianAmal.jpg'),
              const SizedBox(height: 15),
              _buildEventBanner('assets/Programming.jpg'),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Drawer(
        backgroundColor: Colors.white,
        elevation: 10,
        child: Column(
          children: [
            Container(
              height: 100,
              width: double.infinity,
              color: const Color(0xFF965E5E),
              alignment: Alignment.bottomLeft,
              padding: const EdgeInsets.only(left: 20, bottom: 15),
              child: const Text(
                'SAMS',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.home_outlined,
                        color: Colors.black, size: 28),
                    title: const Text('Home', style: TextStyle(fontSize: 16)),
                    onTap: () => Navigator.pop(context),
                  ),
                  const Divider(
                      height: 1,
                      color: Color(0xFFCCCCCC),
                      indent: 15,
                      endIndent: 15),
                  ListTile(
                    leading: const Icon(Icons.military_tech_outlined,
                        color: Colors.black, size: 28),
                    title: const Text('Co-Q', style: TextStyle(fontSize: 16)),
                    onTap: () => Navigator.pop(context),
                  ),
                  const Divider(
                      height: 1,
                      color: Color(0xFFCCCCCC),
                      indent: 15,
                      endIndent: 15),
                  Theme(
                    data: ThemeData().copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      leading: const Icon(Icons.people_outline,
                          color: Colors.black, size: 28),
                      title: const Text('Attendance',
                          style: TextStyle(fontSize: 16)),
                      trailing: const Icon(Icons.chevron_right,
                          color: Colors.black),
                      childrenPadding: const EdgeInsets.only(left: 45),
                      children: [
                        const Divider(height: 1, color: Color(0xFFE0E0E0)),
                        ListTile(
                          title: const Text('View Attendance',
                              style: TextStyle(
                                  color: Colors.black54, fontSize: 14)),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const PusatAdabCoQListScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                      height: 1,
                      color: Color(0xFFCCCCCC),
                      indent: 15,
                      endIndent: 15),
                ],
              ),
            ),
            // Logout at bottom of drawer
            const Divider(height: 1, color: Color(0xFFCCCCCC)),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red, size: 26),
              title: const Text('Logout',
                  style: TextStyle(color: Colors.red, fontSize: 15)),
              onTap: () {
                Navigator.pop(context);
                _logout(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildEventBanner(String imagePath) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(imagePath, fit: BoxFit.cover),
      ),
    );
  }
}
