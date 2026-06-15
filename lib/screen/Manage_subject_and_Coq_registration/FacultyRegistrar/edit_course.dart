import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sams/Controller/Manage_Coq_and_Subject_Registration/RegistrationController.dart';
import 'package:sams/Domain/course_subject.dart';
import 'list_course.dart';
import 'package:sams/screen/Manage_Menu/faculty_registrar_menu.dart';

class EditCourse extends StatefulWidget {
  final CourseSubject course;

  const EditCourse({super.key, required this.course});

  @override
  State<EditCourse> createState() => _EditCourseState();
}

class _EditCourseState extends State<EditCourse> {
  late TextEditingController _idController;
  late TextEditingController _nameController;
  late TextEditingController _sectionController;
  late TextEditingController _labController;
  late TextEditingController _capacityController;
  late TextEditingController _timeController;

  String? _selectedLecturerName;
  TimeOfDay? _selectedTime;
  DateTime? _selectedDateTime;

  final RegistrationController _controller = RegistrationController();

  @override
  void initState() {
    super.initState();

    _idController = TextEditingController(text: widget.course.subjectId);
    _nameController = TextEditingController(text: widget.course.subjectName);
    _sectionController = TextEditingController(text: widget.course.section);
    _labController = TextEditingController(text: widget.course.tutorialLab);
    _capacityController = TextEditingController(
      text: widget.course.capacity.toString(),
    );

    _selectedDateTime = widget.course.time;
    _selectedTime = TimeOfDay.fromDateTime(widget.course.time);
    _timeController = TextEditingController(text: _formatTime(_selectedTime!));

    _selectedLecturerName = widget.course.lecturerName;
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _sectionController.dispose();
    _labController.dispose();
    _capacityController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  Future<void> _pickTimeOnly() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (pickedTime == null) return;

    final DateTime oldDate = _selectedDateTime ?? DateTime.now();

    setState(() {
      _selectedTime = pickedTime;

      _selectedDateTime = DateTime(
        oldDate.year,
        oldDate.month,
        oldDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      _timeController.text = _formatTime(pickedTime);
    });
  }

  void _updateForm() async {
    if (_idController.text.trim().isEmpty ||
        _nameController.text.trim().isEmpty ||
        _sectionController.text.trim().isEmpty ||
        _labController.text.trim().isEmpty ||
        _capacityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sila lengkapkan semua maklumat!')),
      );
      return;
    }

    if (_selectedTime == null || _selectedDateTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sila pilih masa kelas!')));
      return;
    }

    if (_selectedLecturerName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sila pilih nama pensyarah!')),
      );
      return;
    }

    final CourseSubject updatedCourse = CourseSubject(
      subjectId: _idController.text.trim(),
      subjectName: _nameController.text.trim(),
      section: _sectionController.text.trim(),
      tutorialLab: _labController.text.trim(),
      capacity: int.tryParse(_capacityController.text.trim()) ?? 0,
      time: _selectedDateTime!,
      lecturerName: _selectedLecturerName!,
    );

    try {
      await _controller.updateCourse(updatedCourse);

      if (!mounted) return;

      _showSuccessDialog(context);

      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;

        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ListCourse()),
        );
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ralat: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      drawer: const FacultyRegistrarMenu(),

      appBar: AppBar(
        backgroundColor: const Color(0xFFE67E33),
        elevation: 0,
        title: const Text(
          'SAMS',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
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
                children: const [
                  OpenBookIcon(size: 70),
                  SizedBox(width: 15),
                  Text(
                    'Edit\nCourse',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              _buildInputField('Subject ID', _idController, readOnly: true),
              _buildInputField('Subject Name', _nameController),
              _buildInputField('Section', _sectionController),
              _buildInputField('Lab/Tutorial', _labController),
              _buildInputField('Capacity', _capacityController, isNumber: true),

              _buildTimeField(),

              _buildLecturerDropdown(),

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

  Widget _buildTimeField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Time',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),

          const SizedBox(height: 5),

          TextField(
            controller: _timeController,
            readOnly: true,
            onTap: _pickTimeOnly,
            decoration: InputDecoration(
              hintText: 'Select Time',
              suffixIcon: const Icon(Icons.access_time),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLecturerDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lecturer Name',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
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

              final lecturerItems = snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;

                final String fullName =
                    data['full_name'] ?? data['name'] ?? 'No Name';

                return DropdownMenuItem<String>(
                  value: fullName,
                  child: Text(fullName),
                );
              }).toList();

              final bool lecturerExists = lecturerItems.any(
                (item) => item.value == _selectedLecturerName,
              );

              return DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15),
                ),
                hint: const Text("Select Lecturer"),
                value: lecturerExists ? _selectedLecturerName : null,
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

class OpenBookIcon extends StatelessWidget {
  final double size;

  const OpenBookIcon({super.key, this.size = 60});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _OpenBookPainter()),
    );
  }
}

class _OpenBookPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3.1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    final leftPage = Path()
      ..moveTo(w * 0.08, h * 0.22)
      ..lineTo(w * 0.40, h * 0.22)
      ..quadraticBezierTo(w * 0.50, h * 0.22, w * 0.50, h * 0.34)
      ..lineTo(w * 0.50, h * 0.78)
      ..quadraticBezierTo(w * 0.35, h * 0.66, w * 0.08, h * 0.72)
      ..close();

    final rightPage = Path()
      ..moveTo(w * 0.92, h * 0.22)
      ..lineTo(w * 0.60, h * 0.22)
      ..quadraticBezierTo(w * 0.50, h * 0.22, w * 0.50, h * 0.34)
      ..lineTo(w * 0.50, h * 0.78)
      ..quadraticBezierTo(w * 0.65, h * 0.66, w * 0.92, h * 0.72)
      ..close();

    canvas.drawPath(leftPage, paint);
    canvas.drawPath(rightPage, paint);

    canvas.drawLine(
      Offset(w * 0.50, h * 0.32),
      Offset(w * 0.50, h * 0.80),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
