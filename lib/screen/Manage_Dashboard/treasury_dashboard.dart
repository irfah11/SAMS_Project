import 'package:flutter/material.dart';

import '../Manage_Menu/treasury_menu.dart';

class TreasuryDashboard extends StatelessWidget {
  const TreasuryDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Drawer untuk menu Treasury
      drawer: const TreasuryMenu(),
      appBar: AppBar(
        // Guna warna hijau cerah mengikut imej kedua (SAMS Treasury)
        backgroundColor: const Color(0xFF4ED471),
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
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.black, size: 32),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
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

              // 1. Profile Section (Treasury Staff)
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

              // 2. Banner Events (Sama seperti dashboard lain)
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

  // Helper function untuk banner
  Widget _buildEventBanner(String imagePath) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 150,
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image, color: Colors.grey),
            );
          },
        ),
      ),
    );
  }
}
