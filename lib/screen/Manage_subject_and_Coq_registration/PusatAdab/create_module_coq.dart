import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sams/Controller/Manage_Coq_and_Subject_Registration/RegistrationController.dart';
import 'package:sams/Domain/module_coq.dart';
import 'list_coq.dart';
import 'package:sams/screen/Manage_Menu/pusat_adab_menu.dart';

class CreateModuleCoQ extends StatefulWidget {
  const CreateModuleCoQ({super.key});

  @override
  State<CreateModuleCoQ> createState() => _CreateModuleCoQState();
}

class _CreateModuleCoQState extends State<CreateModuleCoQ> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _quotaController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _lecturerController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  final RegistrationController _controller = RegistrationController();

  @override
  void dispose() {
    _subjectController.dispose();
    _quotaController.dispose();
    _locationController.dispose();
    _lecturerController.dispose();
    super.dispose();
  }

  String _generateCoqId() {
    return 'COQ_${DateTime.now().millisecondsSinceEpoch}';
  }

  String _getDayName(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return '';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Value';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Value';

    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  DateTime _combineDateAndTime() {
    return DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (pickedDate == null) return;

    setState(() {
      _selectedDate = pickedDate;
    });
  }

  Future<void> _pickTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );

    if (pickedTime == null) return;

    setState(() {
      _selectedTime = pickedTime;
    });
  }

  void _submitForm() async {
    if (_subjectController.text.trim().isEmpty ||
        _quotaController.text.trim().isEmpty ||
        _locationController.text.trim().isEmpty ||
        _lecturerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields.')),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select date.')));
      return;
    }

    if (_selectedTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select time.')));
      return;
    }

    final DateTime activityDateTime = _combineDateAndTime();

    final ModuleCoQ newCoQ = ModuleCoQ(
      coqId: _generateCoqId(),
      activityName: _subjectController.text.trim(),
      bookingQuota: int.tryParse(_quotaController.text.trim()) ?? 0,
      location: _locationController.text.trim(),
      lecturerName: _lecturerController.text.trim(),
      date: Timestamp.fromDate(activityDateTime),
      time: Timestamp.fromDate(activityDateTime),
      day: _getDayName(activityDateTime),
      booked: 0,
      status: 'Available',
    );

    try {
      await _controller.createCoQ(newCoQ);

      if (!mounted) return;

      _showSuccessDialog(context);

      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;

        Navigator.pop(context);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ListCoQ()),
        );
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const PusatAdabMenu(),

      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFA96366),
        elevation: 0,
        toolbarHeight: 64,
        titleSpacing: 24,
        title: const Text(
          'SAMS',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 28,
            letterSpacing: 2,
            shadows: [
              Shadow(
                color: Colors.black38,
                offset: Offset(2, 2),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu, color: Colors.black, size: 32),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 60, bottom: 35),
        child: Center(
          child: Container(
            width: 295,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    OpenRibbonIcon(size: 64),
                    SizedBox(width: 16),
                    Text(
                      'Register\nCo-Q',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2,
                        height: 1.05,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 22),

                _buildTextInput(
                  label: 'Subject',
                  controller: _subjectController,
                ),

                _buildPickerInput(
                  label: 'Date',
                  value: _formatDate(_selectedDate),
                  onTap: _pickDate,
                ),

                _buildPickerInput(
                  label: 'Time',
                  value: _formatTime(_selectedTime),
                  onTap: _pickTime,
                ),

                _buildTextInput(
                  label: 'Location',
                  controller: _locationController,
                ),

                _buildTextInput(
                  label: 'Booking Quota',
                  controller: _quotaController,
                  isNumber: true,
                ),

                _buildTextInput(
                  label: 'Lecture Name',
                  controller: _lecturerController,
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 34,
                  child: ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2F2F2F),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: const Text(
                      'Submit',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.w400,
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

  Widget _buildTextInput({
    required String label,
    required TextEditingController controller,
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w400,
            ),
          ),

          const SizedBox(height: 6),

          SizedBox(
            height: 36,
            child: TextField(
              controller: controller,
              keyboardType: isNumber
                  ? TextInputType.number
                  : TextInputType.text,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Value',
                hintStyle: const TextStyle(
                  color: Color(0xFFBDBDBD),
                  fontSize: 14,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 0,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                  borderSide: const BorderSide(
                    color: Color(0xFFD7D7D7),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                  borderSide: const BorderSide(
                    color: Color(0xFFD7D7D7),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickerInput({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final bool isPlaceholder = value == 'Value';

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w400,
            ),
          ),

          const SizedBox(height: 6),

          InkWell(
            onTap: onTap,
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD7D7D7), width: 1),
                borderRadius: BorderRadius.circular(7),
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  color: isPlaceholder
                      ? const Color(0xFFBDBDBD)
                      : Colors.black87,
                  fontSize: 14,
                ),
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
              'Registration Successful',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Co-Q Activity has been added successfully.'),
          ],
        ),
      ),
    );
  }
}

class OpenRibbonIcon extends StatelessWidget {
  final double size;

  const OpenRibbonIcon({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _OpenRibbonPainter()),
    );
  }
}

class _OpenRibbonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;

    canvas.drawCircle(Offset(w * 0.5, h * 0.34), w * 0.30, paint);

    final leftRibbon = Path()
      ..moveTo(w * 0.31, h * 0.58)
      ..lineTo(w * 0.31, h * 0.92)
      ..lineTo(w * 0.50, h * 0.78);

    final rightRibbon = Path()
      ..moveTo(w * 0.69, h * 0.58)
      ..lineTo(w * 0.69, h * 0.92)
      ..lineTo(w * 0.50, h * 0.78);

    canvas.drawPath(leftRibbon, paint);
    canvas.drawPath(rightRibbon, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
