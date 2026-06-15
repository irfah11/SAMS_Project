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

  String get _desc =>
      widget.sessionData['session_description'] as String? ?? '-';

  GeoPoint? get _sessionLocation =>
      widget.sessionData['session_location'] as GeoPoint?;

  double get _radiusMeters =>
      (widget.sessionData['radius_meters'] as num?)?.toDouble() ?? 100;

  bool get _isOnline => widget.sessionData['is_online'] as bool? ?? false;

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

  String _locationStatusMessage() {
    switch (_locationStatus) {
      case _LocationStatus.serviceDisabled:
        return 'Location services are turned off. Please enable GPS and try again.';
      case _LocationStatus.permissionDenied:
        return 'Location permission is required to check in. Please grant permission and try again.';
      case _LocationStatus.outOfRange:
        return 'Your location for Check-In is out of range.';
      case _LocationStatus.error:
        return 'Could not determine your location. Please try again.';
      case _LocationStatus.checking:
      case _LocationStatus.withinRange:
      case _LocationStatus.notRequired:
        return 'You are not within the class location. Attendance not recorded.';
    }
  }

  String _fmtTs(dynamic ts) {
    if (ts == null) return '-';
    if (ts is Timestamp) {
      final d = ts.toDate();
      return '${d.hour.toString().padLeft(2, '0')}:'
          '${d.minute.toString().padLeft(2, '0')}';
    }
    return ts.toString();
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

    final locationOk = _locationStatus == _LocationStatus.notRequired ||
        (_locationStatus == _LocationStatus.withinRange && _position != null);
    if (!locationOk) {
      displayStatus(
          success: false,
          message: _locationStatusMessage(),
          icon: Icons.gps_off);
      return;
    }
    if (entered.isEmpty) {
      displayStatus(
          success: false,
          message: 'Please enter the class code.',
          icon: Icons.warning_amber);
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
        displayStatus(
          success: result.success,
          message: result.message,
          icon: result.success
              ? Icons.check_circle_outline
              : Icons.cancel_outlined,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        displayStatus(
            success: false,
            message: 'An error occurred: $e',
            icon: Icons.error_outline);
      }
    }
  }

  void displayStatus(
      {required bool success,
      required String message,
      required IconData icon}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              size: 64,
              color: success
                  ? Colors.green.shade600
                  : Colors.red.shade600),
          const SizedBox(height: 16),
          Text(
              success
                  ? 'Attendance Check-In Successful'
                  : 'Attendance Check-In Failed',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.black54)),
        ]),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (success) Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final startTs = widget.sessionData['start_time'];
    final endTs   = widget.sessionData['end_time'];
    final timeStr = '${_fmtTs(startTs)} — ${_fmtTs(endTs)}';

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
              Icon(Icons.people_outline, size: 40),
              SizedBox(width: 10),
              Text('Manage Attendance',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w500)),
            ]),
            const SizedBox(height: 6),
            Text(widget.subjectName,
                style: const TextStyle(
                    fontSize: 14, color: Colors.black54)),
            if (widget.studentId != null) ...[
              const SizedBox(height: 2),
              Text('Student ID: ${widget.studentId}',
                  style: const TextStyle(
                      fontSize: 12, color: Colors.black38)),
            ],
            const SizedBox(height: 24),

            // Session info card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE0F7FA),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF5CE1E6)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_desc,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.access_time,
                        size: 16, color: Colors.black54),
                    const SizedBox(width: 6),
                    Text(timeStr,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.black87)),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // GPS status
            _buildLocationCard(),
            const SizedBox(height: 28),

            // Class code field
            const Text('Class Code',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'Enter 6-character code (e.g. QWE123)',
                hintStyle: const TextStyle(
                    fontSize: 13, color: Colors.black38),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                      color: Color(0xFF5CE1E6), width: 2),
                ),
                prefixIcon:
                    const Icon(Icons.keyboard, color: Colors.black54),
              ),
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: (_isLoading ||
                        (_locationStatus != _LocationStatus.withinRange &&
                            _locationStatus != _LocationStatus.notRequired))
                    ? null
                    : verifyCheckIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5CE1E6),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Enter',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
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
      case _LocationStatus.withinRange:
        icon = Icons.gps_fixed;
        bg = const Color(0xFFE8F5E9);
        border = Colors.green.shade300;
        fg = Colors.green.shade800;
        message = _distanceMeters != null
            ? 'Location verified — ${_distanceMeters!.toStringAsFixed(0)} m from class location.'
            : 'Location verified.';
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
      case _LocationStatus.notRequired:
        icon = Icons.wifi;
        bg = const Color(0xFFE0F7FA);
        border = const Color(0xFF5CE1E6);
        fg = Colors.black54;
        message = 'Online class — location check not required.';
        showRetry = false;
        break;
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
