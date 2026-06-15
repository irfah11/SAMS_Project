import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:sams/Controller/Manage_Coq_and_Subject_Registration/RegistrationController.dart';
import 'package:sams/Domain/course_subject.dart';
import 'list_course.dart';

class EditCourse extends StatefulWidget {
  final CourseSubject course; // Menerima data asal daripada senarai

  const EditCourse({super.key, required this.course});

  @override
  State<EditCourse> createState() => _EditCourseState();
}

class _EditCourseState extends State<EditCourse> {
  // Isytihar Controller
  late TextEditingController _idController;
  late TextEditingController _nameController;
  late TextEditingController _sectionController;
  late TextEditingController _labController;
  late TextEditingController _capacityController;
  late TextEditingController _timeController;

  String? _selectedLecturerName;
  DateTime? _selectedDateTime;

  final RegistrationController _controller = RegistrationController();

  void navigatorInit() {} // Sesuai dengan amalan anda

  @override
  void initState() {
    super.initState();
    // Isi kotak input secara automatik dengan data sedia ada
    _idController = TextEditingController(text: widget.course.subjectId);
    _nameController = TextEditingController(text: widget.course.subjectName);
    _sectionController = TextEditingController(text: widget.course.section);
    _labController = TextEditingController(text: widget.course.tutorialLab);
    _capacityController = TextEditingController(
      text: widget.course.capacity.toString(),
    );
    _timeController = TextEditingController(
      text: DateFormat('yyyy-MM-dd HH:mm').format(widget.course.time),
    );

    _selectedDateTime = widget.course.time;
    _selectedLecturerName = widget.course.lecturerName;
  }

  Future<void> _pickDateTime() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        // ignore: use_build_context_synchronously
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _selectedDateTime ?? DateTime.now(),
        ),
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
          _timeController.text = DateFormat(
            'yyyy-MM-dd HH:mm',
          ).format(_selectedDateTime!);
        });
      }
    }
  }

  void _updateForm() async {
    if (_selectedLecturerName == null || _selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sila pastikan tarikh/masa dan nama pensyarah lengkap!',
          ),
        ),
      );
      return;
    }

    // Bina objek baharu dengan data dikemas kini
    CourseSubject updatedCourse = CourseSubject(
      subjectId: _idController.text, // ID dikekalkan sebagai rujukan dokumen
      subjectName: _nameController.text,
      section: _sectionController.text,
      tutorialLab: _labController.text,
      capacity: int.tryParse(_capacityController.text) ?? 0,
      time: _selectedDateTime!,
      lecturerName: _selectedLecturerName!,
    );

    try {
      await _controller.updateCourse(updatedCourse);

      if (mounted) {
        _showSuccessDialog(context);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context); // Tutup dialog
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
        backgroundColor: const Color(0xFFE67E33),
        title: const Text(
          'Edit Course',
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
              _buildInputField(
                'Subject ID',
                _idController,
                readOnly: true,
              ), // ID tidak sepatutnya boleh diubah
              _buildInputField('Subject Name', _nameController),
              _buildInputField('Section', _sectionController),
              _buildInputField('Lab/Tutorial', _labController),
              _buildInputField('Capacity', _capacityController, isNumber: true),

              // Time Picker
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
                      readOnly: true,
                      onTap: _pickDateTime,
                      decoration: InputDecoration(
                        suffixIcon: const Icon(Icons.calendar_month),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Dropdown Lecturer
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
                  onPressed: _updateForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF333333),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Save Changes',
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
    bool readOnly = false,
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
            readOnly: readOnly,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
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
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 60),
            SizedBox(height: 20),
            Text(
              'Update Successful',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Course details have been modified.'),
          ],
        ),
      ),
    );
  }
}
