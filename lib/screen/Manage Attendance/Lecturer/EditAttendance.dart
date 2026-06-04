import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  @override
  void initState() {
    super.initState();
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

  Future<void> _save() async {
    if (_descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Description cannot be empty.')));
      return;
    }
    if (!_isStartBeforeEnd()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('End time must be after start time.'),
          backgroundColor: Colors.red));
      return;
    }

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
      });

      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Session updated successfully!'),
            backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
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

            _lbl('Check-in Radius (metres)'),
            const SizedBox(height: 6),
            TextField(
              controller: _radiusController,
              keyboardType: TextInputType.number,
              decoration: _deco('Radius', Icons.radar_outlined),
            ),
            const SizedBox(height: 36),

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
                  onPressed: _isSaving ? null : _save,
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
