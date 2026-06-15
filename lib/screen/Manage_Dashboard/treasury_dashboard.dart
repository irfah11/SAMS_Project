import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../Manage_Menu/treasury_menu.dart';
import 'package:sams/Controller/Fee/FeeController.dart'
    show TreasuryController, DashboardStats, StudentRow;

class TreasuryDashboard extends StatefulWidget {
  const TreasuryDashboard({super.key});

  @override
  State<TreasuryDashboard> createState() => _TreasuryDashboardState();
}

class _TreasuryDashboardState extends State<TreasuryDashboard> {
  late Future<({DashboardStats stats, List<StudentRow> students})> _future;

  @override
  void initState() {
    super.initState();
    _future = TreasuryController.getDashboardStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Drawer untuk menu Treasury
      drawer: const TreasuryMenu(),
      appBar: AppBar(
        // Guna warna hijau cerah mengikut imej kedua (SAMS Treasury)
        backgroundColor: const Color(0xFF4ED471),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'SAMS',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 28,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.black, size: 32),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),

              // 1. Profile Section (Treasury Staff)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Welcome Back,',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      height: 1.2,
                      fontFamily: 'Serif',
                    ),
                  ),
                  ClipOval(
                    child: Image.network(
                      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR6vI071kHqE_4E8H-PqN7l34Y5YvW44a_9AQ&s',
                      width: 65,
                      height: 65,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 65,
                        height: 65,
                        color: const Color(0xFFE0E0E0),
                        child: const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // 2. Fee status pie chart (Paid vs Unpaid)
              FutureBuilder<
                  ({DashboardStats stats, List<StudentRow> students})>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const SizedBox(
                      height: 220,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return SizedBox(
                      height: 120,
                      child: Center(
                        child: Text('Failed to load stats: ${snapshot.error}'),
                      ),
                    );
                  }
                  final stats = snapshot.data!.stats;
                  return _FeeStatusCard(
                    paid: stats.paidStudents,
                    unpaid: stats.unpaidStudents,
                  );
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================
// Fee status pie chart card — Paid vs Unpaid
// =============================================================
class _FeeStatusCard extends StatelessWidget {
  final int paid;
  final int unpaid;
  const _FeeStatusCard({required this.paid, required this.unpaid});

  static const Color _paidColor = Color(0xFF52DE76);
  static const Color _unpaidColor = Color(0xFFEF5350);

  @override
  Widget build(BuildContext context) {
    final total = paid + unpaid;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fee Status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: CustomPaint(
                  painter: _PiePainter(paid: paid, unpaid: unpaid),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$total',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'students',
                          style: TextStyle(fontSize: 10, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Legend(
                      color: _paidColor,
                      label: 'Paid',
                      value: paid,
                      total: total,
                    ),
                    const SizedBox(height: 12),
                    _Legend(
                      color: _unpaidColor,
                      label: 'Unpaid',
                      value: unpaid,
                      total: total,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  final int value;
  final int total;
  const _Legend({
    required this.color,
    required this.label,
    required this.value,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0 : (value / total * 100).round();
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ),
        Text(
          '$value ($pct%)',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

class _PiePainter extends CustomPainter {
  final int paid;
  final int unpaid;
  _PiePainter({required this.paid, required this.unpaid});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final total = paid + unpaid;

    // Empty state — draw a neutral ring so the chart isn't blank.
    if (total == 0) {
      canvas.drawArc(
        rect,
        0,
        2 * math.pi,
        true,
        Paint()..color = const Color(0xFFE0E0E0),
      );
      _drawHole(canvas, size);
      return;
    }

    const start = -math.pi / 2; // start at the top
    final paidSweep = paid / total * 2 * math.pi;

    canvas.drawArc(rect, start, paidSweep, true,
        Paint()..color = _FeeStatusCard._paidColor);
    canvas.drawArc(rect, start + paidSweep, 2 * math.pi - paidSweep, true,
        Paint()..color = _FeeStatusCard._unpaidColor);

    _drawHole(canvas, size);
  }

  // Punch a white hole to make it a donut (leaves room for the centre label).
  void _drawHole(Canvas canvas, Size size) {
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.28,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _PiePainter old) =>
      old.paid != paid || old.unpaid != unpaid;
}
