import 'package:flutter/material.dart';

class PusatAdabDashboard extends StatelessWidget {
  const PusatAdabDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Placeholder for the Pusat Adab specific menu
      drawer: const Drawer(),
      appBar: AppBar(
        backgroundColor: const Color(
          0xFF965E5E,
        ), // Maroon/Brown shade from your mockup
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

              // 1. Profile & Welcome Section
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
                      fontFamily:
                          'Serif', // Matches the stylized font in the image
                    ),
                  ),
                  ClipOval(
                    child: Image.network(
                      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR6vI071kHqE_4E8H-PqN7l34Y5YvW44a_9AQ&s',
                      width: 65,
                      height: 65,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // 2. Event Banners
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

  // Helper function to maintain consistent banner styling
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
        child: Image.asset(imagePath, fit: BoxFit.cover),
      ),
    );
  }
}
