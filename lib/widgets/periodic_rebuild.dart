import 'dart:async';
import 'package:flutter/material.dart';

/// Rebuilds [builder] on a fixed [interval] so that time-derived UI — such as
/// a session's Pending / Active / Passed status (see
/// `AttendanceController.effectiveStatus`) — keeps updating while the screen
/// stays open, without waiting for a Firestore change.
///
/// Wrap only the time-dependent part (e.g. the session table) so any
/// surrounding `StreamBuilder` keeps its subscription instead of resubscribing.
class PeriodicRebuild extends StatefulWidget {
  final Duration interval;
  final WidgetBuilder builder;

  const PeriodicRebuild({
    super.key,
    this.interval = const Duration(seconds: 30),
    required this.builder,
  });

  @override
  State<PeriodicRebuild> createState() => _PeriodicRebuildState();
}

class _PeriodicRebuildState extends State<PeriodicRebuild> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.interval, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}
