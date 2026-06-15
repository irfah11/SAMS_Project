import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../../../Controller/Manage Attendance/AttendanceController.dart';

enum _LocationStatus {
  checking,
  withinRange,
  outOfRange,
  permissionDenied,
  serviceDisabled,
  error,
  notRequired,
}

class AttendanceCheckInScreen extends StatefulWidget {
  final String sessionId;
  final Map<String, dynamic> sessionData;
  final String subjectName;
  // Option B: matric student_id (e.g. "CB23028") — NOT Firebase Auth UID
  final String? studentId;

  const AttendanceCheckInScreen({
    super.key,
    required this.sessionId,
    required this.sessionData,
    required this.subjectName,
    required this.studentId,
  });

  @override
  State<AttendanceCheckInScreen> createState() =>
      _AttendanceCheckInScreenState();
}

class _AttendanceCheckInScreenState
    extends State<AttendanceCheckInScreen> {
  final _codeController = TextEditingController();
  bool _isLoading = false;

  _LocationStatus _locationStatus = _LocationStatus.checking;
  Position? _position;
  double? _distanceMeters;

  GeoPoint? get _sessionLocation =>
      widget.sessionData['session_location'] as GeoPoint?;

  double get _radiusMeters =>
      (widget.sessionData['radius_meters'] as num?)?.toDouble() ?? 100;

  bool get _isOnline => widget.sessionData['is_online'] as bool? ?? false;

  static const _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday'
  ];
  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  void initState() {
    super.initState();
    if (_isOnline) {
      _locationStatus = _LocationStatus.notRequired;
    } else {
      getStudentLocation();
    }
  }

  Future<void> getStudentLocation() async {
    setState(() => _locationStatus = _LocationStatus.checking);

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() => _locationStatus = _LocationStatus.serviceDisabled);
      }
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() => _locationStatus = _LocationStatus.permissionDenied);
      }
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final sessionLoc = _sessionLocation;
      final distance = sessionLoc == null
          ? null
          : Geolocator.distanceBetween(
              position.latitude,
              position.longitude,
              sessionLoc.latitude,
              sessionLoc.longitude,
            );

      if (mounted) {
        setState(() {
          _position = position;
          _distanceMeters = distance;
          _locationStatus = (distance == null || distance <= _radiusMeters)
              ? _LocationStatus.withinRange
              : _LocationStatus.outOfRange;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _locationStatus = _LocationStatus.error);
      }
    }
  }

  /// e.g. "Thursday, 2 Apr 2026"
  String _fmtDateLong(dynamic ts) {
    if (ts is! Timestamp) return '-';
    final d = ts.toDate();
    return '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  String _fmtTime(dynamic ts) {
    if (ts is! Timestamp) return '-';
    final d = ts.toDate();
    return '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  /// SDD inputCode() — the class code typed by the student.
  String inputCode() => _codeController.text.trim().toUpperCase();

  Future<void> verifyCheckIn() async {
    final entered = inputCode();

    if (entered.isEmpty) {
      displayStatus(
          success: false, message: 'Please enter the class code.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final studentIdToWrite = widget.studentId ?? uid;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final studentName =
          userDoc.data()?['name'] as String? ?? studentIdToWrite;

      final result = await AttendanceController.validateCheckIn(
        studentIdToWrite,
        entered,
        _position?.latitude,
        _position?.longitude,
        sessionId:   widget.sessionId,
        studentName: studentName,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        displayStatus(success: result.success, message: result.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        displayStatus(success: false, message: 'An error occurred: $e');
      }
    }
  }

  /// Result popup overlaying the screen (Figs 3.5.57 / 3.5.58 / 3.5.59).
  void displayStatus({required bool success, required String message}) {
    final isOutOfRange = !success &&
        _locationStatus == _LocationStatus.outOfRange &&
        _distanceMeters != null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(
              success ? Icons.check_circle_outline : Icons.cancel_outlined,
              size: 56,
              color: success ? Colors.green.shade600 : Colors.red.shade600,
            ),
            const SizedBox(height: 14),
            Text(
              success
                  ? 'Attendance Check-In Successful'
                  : 'Attendance Check-In Failed',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            // Distance shown ONLY on an invalid (out-of-range) check-in.
            if (isOutOfRange) ...[
              const SizedBox(height: 12),
              Text(
                'You are ${_distanceMeters!.toStringAsFixed(0)} m from the class '
                'location (must be within ${_radiusMeters.toStringAsFixed(0)} m).',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.red.shade700),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (success) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5CE1E6),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text('OK'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final startTs = widget.sessionData['start_time'];
    final endTs   = widget.sessionData['end_time'];
    final dateStr = _fmtDateLong(startTs);
    final timeStr = '${_fmtTime(startTs)} — ${_fmtTime(endTs)}';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF5CE1E6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
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
              Icon(Icons.people_outline, size: 32),
              SizedBox(width: 10),
              Text('Manage  Attendance',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w500)),
            ]),
            const SizedBox(height: 12),
            Center(
              child: Text(widget.subjectName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 28),

            // Selected session date + time
            Center(
              child: Column(children: [
                Text(dateStr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(timeStr,
                    style: const TextStyle(
                        fontSize: 13, color: Colors.black54)),
              ]),
            ),
            const SizedBox(height: 28),

            // GPS status — only show when there's a location issue
            if (_locationStatus != _LocationStatus.withinRange &&
                _locationStatus != _LocationStatus.notRequired) ...[
              _buildLocationCard(),
              const SizedBox(height: 24),
            ],

            // Class code field
            const Text('Class Code',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'Value',
                hintStyle: const TextStyle(
                    fontSize: 14, color: Colors.black38),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(
                      color: Color(0xFF5CE1E6), width: 2),
                ),
              ),
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3),
            ),
            const SizedBox(height: 28),

            // Save button (green, centered like the wireframe)
            Center(
              child: SizedBox(
                width: 130,
                height: 42,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : verifyCheckIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Save',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    IconData icon;
    Color bg, border, fg;
    String message;
    bool showRetry = true;

    switch (_locationStatus) {
      case _LocationStatus.checking:
        icon = Icons.gps_not_fixed;
        bg = const Color(0xFFE0F7FA);
        border = const Color(0xFF5CE1E6);
        fg = Colors.black54;
        message = 'Checking your location...';
        showRetry = false;
        break;
      case _LocationStatus.outOfRange:
        icon = Icons.gps_off;
        bg = const Color(0xFFFFF3E0);
        border = Colors.orange.shade300;
        fg = Colors.orange.shade800;
        message = 'You are ${_distanceMeters?.toStringAsFixed(0)} m away '
            '(must be within ${_radiusMeters.toStringAsFixed(0)} m of the class location).';
        break;
      case _LocationStatus.permissionDenied:
        icon = Icons.location_disabled;
        bg = const Color(0xFFFFEBEE);
        border = Colors.red.shade300;
        fg = Colors.red.shade800;
        message =
            'Location permission denied. Allow location access to check in.';
        break;
      case _LocationStatus.serviceDisabled:
        icon = Icons.location_off;
        bg = const Color(0xFFFFEBEE);
        border = Colors.red.shade300;
        fg = Colors.red.shade800;
        message = 'Location services are off. Please enable GPS to check in.';
        break;
      case _LocationStatus.error:
        icon = Icons.error_outline;
        bg = const Color(0xFFFFEBEE);
        border = Colors.red.shade300;
        fg = Colors.red.shade800;
        message = 'Could not get your location. Please try again.';
        break;
      case _LocationStatus.withinRange:
      case _LocationStatus.notRequired:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border),
      ),
      child: Row(children: [
        _locationStatus == _LocationStatus.checking
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
            : Icon(icon, color: fg),
        const SizedBox(width: 12),
        Expanded(
          child: Text(message, style: TextStyle(fontSize: 13, color: fg)),
        ),
        if (showRetry)
          IconButton(
            icon: Icon(Icons.refresh, color: fg),
            tooltip: 'Retry',
            onPressed: getStudentLocation,
          ),
      ]),
    );
  }
}
