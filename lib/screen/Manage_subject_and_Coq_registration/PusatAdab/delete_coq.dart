import 'package:flutter/material.dart';

class DeleteCoQDialog extends StatelessWidget {
  final String courseName;

  const DeleteCoQDialog({super.key, required this.courseName});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          4,
        ), // Bentuk petak seperti dalam gambar
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        width: MediaQuery.of(context).size.width * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min, // Saiz kotak mengikut kandungan
          children: [
            // 1. Ikon Pangkah Merah
            const CircleAvatar(
              radius: 35,
              backgroundColor: Color(0xFFD32F2F), // Merah
              child: Icon(Icons.close, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 20),

            // 2. Teks Tajuk
            const Text(
              'Confirm',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // 3. Teks Soalan
            Text(
              'Are you sure you want to delete this\nKo-Q subject',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 25),

            // 4. Barisan Butang (Cancel & Delete)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Butang Cancel (Biru)
                SizedBox(
                  width: 100,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A69FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),

                // Butang Delete (Merah)
                SizedBox(
                  width: 100,
                  child: ElevatedButton(
                    onPressed: () {
                      // Masukkan logik delete database di sini
                      Navigator.pop(context); // Tutup dialog
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
