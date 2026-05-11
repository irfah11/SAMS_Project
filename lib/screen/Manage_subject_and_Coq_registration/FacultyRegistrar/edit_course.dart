import 'package:flutter/material.dart';

class EditCourse extends StatelessWidget {
  final String courseName;
  // Kita tambah parameter supaya data dari List tadi boleh dibawa masuk ke sini
  const EditCourse({super.key, required this.courseName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE67E33),
        elevation: 0,
        title: const Text(
          'SAMS',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.edit_note,
                    size: 70,
                  ), // Ikon beza sikit (Edit)
                  const SizedBox(width: 15),
                  const Text(
                    'Edit\nCourse',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // Form Fields (Dah ada "Value" asal)
              _buildInputField('Subject Name', courseName),
              _buildInputField('Section', '01'),
              _buildInputField('Lab/Tutorial', '01A , 01B'),
              _buildInputField('Capacity', '60'),
              _buildInputField('Time', '2.00 pm - 4.00 pm'),
              _buildInputField('Lecture Name', 'MUHAMMAD ZULFAHMI TOH'),

              const SizedBox(height: 20),

              // Button Save Changes
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // Tunjuk dialog berjaya update nanti
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFF4CAF50,
                    ), // Warna Hijau Edit
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Update Changes',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, String initialValue) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          TextFormField(
            initialValue: initialValue, // Dia akan automatik isi data asal
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
