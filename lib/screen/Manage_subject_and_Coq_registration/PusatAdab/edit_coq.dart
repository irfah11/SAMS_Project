import 'package:flutter/material.dart';
import 'package:sams/screen/Manage_Menu/pusat_adab_menu.dart';

class EditCoQ extends StatelessWidget {
  final String courseName;

  const EditCoQ({super.key, required this.courseName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      drawer: const PusatAdabMenu(),

      // ================= HEADER =================
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          backgroundColor: const Color(0xFF9A6666),
          elevation: 0,
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          flexibleSpace: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // LEFT SIDE (ONLY LOGO)
                  const Text(
                    'SAMS',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 28,
                      letterSpacing: 1,
                      shadows: [
                        Shadow(
                          offset: Offset(2, 2),
                          blurRadius: 0,
                          color: Colors.black26,
                        ),
                      ],
                    ),
                  ),

                  // RIGHT DRAWER ICON
                  Builder(
                    builder: (context) => IconButton(
                      icon: const Icon(
                        Icons.menu,
                        color: Colors.black,
                        size: 30,
                      ),
                      onPressed: () {
                        Scaffold.of(context).openDrawer();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      // ================= BODY =================
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                // ===== TOP TITLE =====
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: const Icon(
                        Icons.military_tech_outlined,
                        size: 45,
                        color: Colors.black,
                      ),
                    ),

                    const SizedBox(width: 15),

                    const Expanded(
                      child: Text(
                        'Edit Register\nCo-Q',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // ===== FORM =====
                _buildInputField('Subject', courseName),
                _buildInputField('Date', ''),
                _buildInputField('Time', ''),
                _buildInputField('Location', ''),
                _buildInputField('Booking Quota', ''),
                _buildInputField('Lecture Name', ''),

                const SizedBox(height: 20),

                // ===== BUTTON =====
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF333333),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Submit',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= INPUT FIELD =================
  static Widget _buildInputField(String label, String initialValue) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),

          const SizedBox(height: 5),

          TextField(
            decoration: InputDecoration(
              hintText: initialValue.isEmpty ? 'Value' : initialValue,

              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),

              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
