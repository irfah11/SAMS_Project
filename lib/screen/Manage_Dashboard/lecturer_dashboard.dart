import 'package:flutter/material.dart';
// Make sure this path matches your file structure
import '../Manage_Menu/lecture_menu.dart';

class LecturerDashboard extends StatelessWidget {
  const LecturerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Linking the Drawer to the LecturerDrawer below
      drawer: const LecturerDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4C66EE), // Blue shade from your mockup
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

              // Profile Section (Lecturer Name)
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

              // Banners
              _buildResponsiveImage('assets/Mobility.jpg'),
              const SizedBox(height: 15),
              _buildResponsiveImage('assets/LarianAmal.jpg'),
              const SizedBox(height: 15),
              _buildResponsiveImage('assets/Programming.jpg'),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveImage(String path) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.asset(path, fit: BoxFit.contain),
      ),
    );
  }
}
