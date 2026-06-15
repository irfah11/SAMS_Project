import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Sila pastikan intl ada dalam pubspec.yaml untuk format tarikh
import 'package:sams/Controller/Manage_Coq_and_Subject_Registration/RegistrationController.dart';
import 'package:sams/Domain/course_subject.dart';
import 'package:sams/screen/Manage_subject_and_Coq_registration/FacultyRegistrar/list_course.dart';

class CreateCourse extends StatefulWidget {
  const CreateCourse({super.key});

  @override
  State<CreateCourse> createState() => _CreateCourseState();
}

class _CreateCourseState extends State<CreateCourse> {
  // 1. Isytihar Controller untuk input field biasa
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _sectionController = TextEditingController();
  final TextEditingController _labController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  // 2. Pembolehubah untuk menyimpan data pilihan (Dropdown & DateTime)
  String? _selectedLecturerName;
  DateTime? _selectedDateTime;

  // 3. Isytihar RegistrationController (MVC)
  final RegistrationController _controller = RegistrationController();

  // Fungsi untuk memaparkan Date & Time Picker
  Future<void> _pickDateTime() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        // ignore: use_build_context_synchronously
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          // Paparkan tarikh & masa yang kemas pada kotak input
          _timeController.text = DateFormat(
            'yyyy-MM-dd HH:mm',
          ).format(_selectedDateTime!);
        });
      }
    }
  }

  // Fungsi untuk menyimpan data ke Firebase
  void _submitForm() async {
    // Validasi ringkas untuk memastikan dropdown dan tarikh telah dipilih
    if (_selectedLecturerName == null || _selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sila pilih tarikh/masa dan nama pensyarah!'),
        ),
      );
      return;
    }

    CourseSubject newCourse = CourseSubject(
      subjectId: _idController.text,
      subjectName: _nameController.text,
      section: _sectionController.text,
      tutorialLab: _labController.text,
      capacity: int.tryParse(_capacityController.text) ?? 0,
      time:
          _selectedDateTime!, // Menyimpan objek DateTime (Akan dihantar sebagai Timestamp)
      lecturerName:
          _selectedLecturerName!, // Menyimpan String nama pensyarah pilihan
    );

    try {
      await _controller.createCourse(newCourse);

      if (mounted) {
        _showSuccessDialog(context);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context); // Tetap tutup dialog kejayaan dahulu

            // Alihkan pengguna terus ke ListCourse secara rasmi
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ListCourse()),
            );
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ralat: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE67E33), // Oren Faculty
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
                  const Icon(Icons.menu_book_outlined, size: 70),
                  const SizedBox(width: 15),
                  const Text(
                    'Register\nCourse',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // Form Fields biasa menggunakan TextField
              _buildInputField('Subject ID', _idController),
              _buildInputField('Subject Name', _nameController),
              _buildInputField('Section', _sectionController),
              _buildInputField('Lab/Tutorial', _labController),
              _buildInputField('Capacity', _capacityController, isNumber: true),

              // FIELD TIME: Ditukar menjadi tap untuk buka Calendar/Time Picker
              Padding(
                padding: const EdgeInsets.only(bottom: 15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Time',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: _timeController,
                      readOnly: true, // Pengguna tak boleh taip manual
                      onTap: _pickDateTime, // Buka picker bila ditekan
                      decoration: InputDecoration(
                        hintText: 'Select Date & Time',
                        suffixIcon: const Icon(Icons.calendar_month),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // FIELD LECTURER NAME: Ditukar menjadi Dropdown dari Firebase
              Padding(
                padding: const EdgeInsets.only(bottom: 15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lecturer Name',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('lecturer')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const LinearProgressIndicator();
                        }

                        List<DropdownMenuItem<String>> lecturerItems = [];
                        for (var doc in snapshot.data!.docs) {
                          var data = doc.data() as Map<String, dynamic>;
                          String fullName = data['full_name'] ?? 'No Name';
                          lecturerItems.add(
                            DropdownMenuItem(
                              value: fullName,
                              child: Text(fullName),
                            ),
                          );
                        }

                        return DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 15,
                            ),
                          ),
                          hint: const Text("Select Lecturer"),
                          initialValue: _selectedLecturerName,
                          items: lecturerItems,
                          onChanged: (value) {
                            setState(() {
                              _selectedLecturerName = value;
                            });
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF333333),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Submit',
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

  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              hintText: 'Value',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const SizedBox(height: 20),
            const Text(
              'Registration Successful',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('Course has been added to the list.'),
          ],
        ),
      ),
    );
  }
}
