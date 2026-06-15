import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class AddAttendanceScreen extends StatefulWidget {
  final String? subjectId;
  final String? coqId;
  final String subjectName;
  final bool isCoQ;
  // Option B: numeric lecturer_id (e.g. 1002) — NOT the Firebase Auth UID
  final dynamic lecturerId;

  const AddAttendanceScreen({
    super.key,
    this.subjectId,
    this.coqId,
    required this.subjectName,
    required this.isCoQ,
    required this.lecturerId,
  });

  @override
  State<AddAttendanceScreen> createState() => _AddAttendanceScreenState();
}

class _AddAttendanceScreenState extends State<AddAttendanceScreen> {
  static const _blue = Color(0xFF4C66EE);

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final _descController   = TextEditingController();
  final _radiusController = TextEditingController(text: '100');
  bool _isSaving = false;

  bool _isOnline = false;
  GeoPoint? _sessionLocation;
  bool _isCapturingLocation = false;

  @override
  void dispose() {
    _descController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';

  // Convert TimeOfDay to Timestamp for Firestore (using selected date)
  Timestamp _toTimestamp(TimeOfDay time) {
    final d = _selectedDate ?? DateTime.now();
    return Timestamp.fromDate(
        DateTime(d.year, d.month, d.day, time.hour, time.minute));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime(bool isStart) async {
    final init = isStart
        ? const TimeOfDay(hour: 8, minute: 0)
        : const TimeOfDay(hour: 10, minute: 0);
    final picked = await showTimePicker(context: context, initialTime: init);
    if (picked != null) {
      setState(() {
        if (isStart) { _startTime = picked; } else { _endTime = picked; }
      });
    }
  }

  bool _isStartBeforeEnd() {
    if (_startTime == null || _endTime == null) return true;
    final s = _startTime!.hour * 60 + _startTime!.minute;
    final e = _endTime!.hour * 60 + _endTime!.minute;
    return s < e;
  }

  Future<void> getCurrentLocation() async {
    setState(() => _isCapturingLocation = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled. Please enable GPS.';
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw 'Location permission denied.';
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (mounted) {
        setState(() {
          _sessionLocation = GeoPoint(pos.latitude, pos.longitude);
          _isCapturingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCapturingLocation = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  /// SDD inputSessionDetails() — validate the form the lecturer filled in.
  bool inputSessionDetails() {
    if (_selectedDate == null ||
        _startTime == null ||
        _endTime == null ||
        _descController.text.trim().isEmpty) {
      displayStatus('Please fill in all required fields.', success: false);
      return false;
    }
    if (!_isStartBeforeEnd()) {
      displayStatus('End time must be after start time.', success: false);
      return false;
    }
    if (!_isOnline && _sessionLocation == null) {
      displayStatus(
          'Please capture the class location, or mark it as an online class.',
          success: false);
      return false;
    }
    return true;
  }

  /// SDD setCheckInRadius() — the check-in radius (metres) entered, default 100.
  int setCheckInRadius() => int.tryParse(_radiusController.text.trim()) ?? 100;

  /// SDD displayStatus(msg) — show a status message to the lecturer.
  void displayStatus(String msg, {bool success = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? Colors.green : Colors.red,
    ));
  }

  /// SDD createSession() — validate then write the new AttendanceSession.
  Future<void> createSession() async {
    if (!inputSessionDetails()) return;

    setState(() => _isSaving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final userDoc = await FirebaseFirestore.instance
          .collection('users').doc(uid).get();
      final lecturerName =
          userDoc.data()?['name'] as String? ?? 'Lecturer';
      final radius = setCheckInRadius();

      // Option B: use numeric lecturer_id (e.g. 1002) not Firebase Auth UID
      final lecturerId = widget.lecturerId;

      await FirebaseFirestore.instance
          .collection('AttendanceSession')
          .add({
        'Lecturer_id':          lecturerId,   // numeric id (e.g. 1002)
        'lecturer_name':        lecturerName,
        'subject_id':           widget.subjectId,
        'coq_id':               widget.coqId,
        'subject_name':         widget.subjectName,
        'is_coq':               widget.isCoQ,
        'start_time':           _toTimestamp(_startTime!),
        'end_time':             _toTimestamp(_endTime!),
        'session_description':  _descController.text.trim(),
        'attendance_code':      '',
        'is_online':            _isOnline,
        'session_location':     _isOnline ? null : _sessionLocation,
        'radius_meters':        radius,
        'session_status':       'Pending',
        'created_at':           Timestamp.now(),
      });

      if (mounted) {
        setState(() => _isSaving = false);
        // Figure 3.5.66 — add class successful dialog, then back to the list.
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.check_circle_outline,
                  size: 64, color: Colors.green.shade600),
              const SizedBox(height: 16),
              const Text('Attendance Class Added',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('You had successfully Add Class Attendance.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black54)),
            ]),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('OK')),
            ],
          ),
        );
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        displayStatus('Error: $e', success: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _blue,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context)),
        title: const Text('SAMS',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 24)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: const [
              Icon(Icons.add_circle_outline, size: 36, color: _blue),
              SizedBox(width: 10),
              Text('Add Attendance',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 6),
            Text(widget.subjectName,
                style: const TextStyle(
                    fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 28),

            _label('Class Date *'),
            const SizedBox(height: 6),
            _tapField(
              value: _selectedDate != null
                  ? _fmtDate(_selectedDate!)
                  : 'Select date',
              icon: Icons.calendar_today_outlined,
              onTap: _pickDate,
            ),
            const SizedBox(height: 16),

            Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Start Time *'),
                    const SizedBox(height: 6),
                    _tapField(
                      value: _startTime != null
                          ? _fmtTime(_startTime!)
                          : 'Start',
                      icon: Icons.access_time,
                      onTap: () => _pickTime(true),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('End Time *'),
                    const SizedBox(height: 6),
                    _tapField(
                      value: _endTime != null
                          ? _fmtTime(_endTime!)
                          : 'End',
                      icon: Icons.access_time_filled_outlined,
                      onTap: () => _pickTime(false),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 16),

            _label('Class Description *'),
            const SizedBox(height: 6),
            TextField(
              controller: _descController,
              decoration: _inputDeco(
                  'e.g. Regular class session',
                  Icons.description_outlined),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isOnline,
                onChanged: (v) => setState(() => _isOnline = v),
                title: const Text('Online Class',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text(
                    'No location check required for check-in',
                    style: TextStyle(fontSize: 12, color: Colors.black54)),
              ),
            ),
            const SizedBox(height: 16),

            if (!_isOnline) ...[
              _label('Check-in Radius (metres)'),
              const SizedBox(height: 6),
              TextField(
                controller: _radiusController,
                keyboardType: TextInputType.number,
                decoration: _inputDeco('Default: 100', Icons.radar_outlined),
              ),
              const SizedBox(height: 16),

              _label('Class Location *'),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(
                  child: Text(
                    _sessionLocation != null
                        ? '${_sessionLocation!.latitude.toStringAsFixed(5)}, '
                            '${_sessionLocation!.longitude.toStringAsFixed(5)}'
                        : 'Not set — tap to capture your current location',
                    style: TextStyle(
                        fontSize: 13,
                        color: _sessionLocation != null
                            ? Colors.black87
                            : Colors.grey),
                  ),
                ),
                TextButton.icon(
                  onPressed:
                      _isCapturingLocation ? null : getCurrentLocation,
                  icon: _isCapturingLocation
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.my_location),
                  label:
                      Text(_sessionLocation != null ? 'Update' : 'Capture'),
                ),
              ]),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 28),

            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isSaving ? null : createSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Confirm',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) =>
      Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600));

  Widget _tapField(
      {required String value,
      required IconData icon,
      required VoidCallback onTap}) {
    final isPlaceholder =
        value == 'Select date' || value == 'Start' || value == 'End';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: Colors.black54),
          const SizedBox(width: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  color: isPlaceholder ? Colors.grey : Colors.black87)),
        ]),
      ),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.black54),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _blue, width: 2),
        ),
      );
}
