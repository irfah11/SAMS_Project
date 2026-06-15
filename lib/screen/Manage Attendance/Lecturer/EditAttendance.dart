import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class EditAttendanceScreen extends StatefulWidget {
  final String sessionId;
  final Map<String, dynamic> sessionData;

  const EditAttendanceScreen({
    super.key,
    required this.sessionId,
    required this.sessionData,
  });

  @override
  State<EditAttendanceScreen> createState() => _EditAttendanceScreenState();
}

class _EditAttendanceScreenState extends State<EditAttendanceScreen> {
  static const _blue = Color(0xFF4C66EE);

  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late TextEditingController _descController;
  late TextEditingController _radiusController;
  bool _isSaving = false;

  bool _isOnline = false;
  GeoPoint? _sessionLocation;
  bool _isCapturingLocation = false;

  @override
  void initState() {
    super.initState();
    loadSessionData();
  }

  /// SDD loadSessionData() — pre-fill the form from the existing session.
  void loadSessionData() {
    final data = widget.sessionData;

    // start_time and end_time are Timestamps
    final startTs = data['start_time'] as Timestamp?;
    final endTs   = data['end_time'] as Timestamp?;

    final startDt = startTs?.toDate() ?? DateTime.now();
    final endDt   = endTs?.toDate() ??
        DateTime.now().add(const Duration(hours: 2));

    _selectedDate = startDt;
    _startTime    = TimeOfDay(hour: startDt.hour, minute: startDt.minute);
    _endTime      = TimeOfDay(hour: endDt.hour, minute: endDt.minute);
    _descController = TextEditingController(
        text: data['session_description'] as String? ?? '');
    _radiusController = TextEditingController(
        text: (data['radius_meters'] as int? ?? 100).toString());
    _isOnline = data['is_online'] as bool? ?? false;
    _sessionLocation = data['session_location'] as GeoPoint?;
  }

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
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Timestamp _toTimestamp(TimeOfDay time) => Timestamp.fromDate(
      DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day,
          time.hour, time.minute));

  bool _isStartBeforeEnd() {
    final s = _startTime.hour * 60 + _startTime.minute;
    final e = _endTime.hour * 60 + _endTime.minute;
    return s < e;
  }

  Future<void> _pickDate() async {
    final p = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (p != null) setState(() => _selectedDate = p);
  }

  Future<void> _pickTime(bool isStart) async {
    final p = await showTimePicker(
        context: context,
        initialTime: isStart ? _startTime : _endTime);
    if (p != null) {
      setState(() {
        if (isStart) { _startTime = p; } else { _endTime = p; }
      });
    }
  }

  Future<void> _captureLocation() async {
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

  /// SDD inputModifiedDetails() — validate the edited form values.
  bool inputModifiedDetails() {
    if (_descController.text.trim().isEmpty) {
      displayStatus('Description cannot be empty.', success: false);
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

  /// SDD displayStatus(msg) — show a status message to the lecturer.
  void displayStatus(String msg, {bool success = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? Colors.green : Colors.red,
    ));
  }

  /// SDD updateSession() — validate then persist the edited session.
  Future<void> updateSession() async {
    if (!inputModifiedDetails()) return;

    setState(() => _isSaving = true);
    try {
      // Update AttendanceSession with your field names
      await FirebaseFirestore.instance
          .collection('AttendanceSession')
          .doc(widget.sessionId)
          .update({
        'start_time':          _toTimestamp(_startTime),
        'end_time':            _toTimestamp(_endTime),
        'session_description': _descController.text.trim(),
        'radius_meters':
            int.tryParse(_radiusController.text.trim()) ?? 100,
        'is_online':           _isOnline,
        'session_location':    _isOnline ? null : _sessionLocation,
      });

      if (mounted) {
        setState(() => _isSaving = false);
        // Figure 3.5.69 — edit class successful dialog, then back to the list.
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.check_circle_outline,
                  size: 64, color: Colors.green.shade600),
              const SizedBox(height: 16),
              const Text('Attendance Class Edited',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('You had successfully Edit Attendance.',
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
              Icon(Icons.edit_outlined, size: 36, color: _blue),
              SizedBox(width: 10),
              Text('Edit Attendance',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w600)),
            ]),
            const SizedBox(height: 28),

            _lbl('Class Date'),
            const SizedBox(height: 6),
            _tap(_fmtDate(_selectedDate), Icons.calendar_today_outlined,
                _pickDate),
            const SizedBox(height: 16),

            Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _lbl('Start Time'),
                      const SizedBox(height: 6),
                      _tap(_fmtTime(_startTime), Icons.access_time,
                          () => _pickTime(true)),
                    ]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _lbl('End Time'),
                      const SizedBox(height: 6),
                      _tap(_fmtTime(_endTime),
                          Icons.access_time_filled_outlined,
                          () => _pickTime(false)),
                    ]),
              ),
            ]),
            const SizedBox(height: 16),

            _lbl('Class Description'),
            const SizedBox(height: 6),
            TextField(
              controller: _descController,
              decoration: _deco('Description', Icons.description_outlined),
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
              _lbl('Check-in Radius (metres)'),
              const SizedBox(height: 6),
              TextField(
                controller: _radiusController,
                keyboardType: TextInputType.number,
                decoration: _deco('Radius', Icons.radar_outlined),
              ),
              const SizedBox(height: 16),

              _lbl('Class Location'),
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
                      _isCapturingLocation ? null : _captureLocation,
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
                  onPressed: _isSaving ? null : updateSession,
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
                      : const Text('Save Changes',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _lbl(String t) =>
      Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600));

  Widget _tap(String val, IconData icon, VoidCallback onTap) =>
      GestureDetector(
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
            Text(val,
                style: const TextStyle(
                    fontSize: 14, color: Colors.black87)),
          ]),
        ),
      );

  InputDecoration _deco(String hint, IconData icon) => InputDecoration(
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
