import 'package:flutter/material.dart';
import 'package:moon_design/moon_design.dart';

class MyFeesPage extends StatelessWidget {
  const MyFeesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with SAMS logo + menu
            _Header(),

            // Body content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // "My Fees" link/title
                    Text(
                      "My Fees",
                      style: MoonTypography.typography.heading.text20.copyWith(
                        decoration: TextDecoration.underline,
                        color: MoonColors.light.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Fee Card
                    _FeeCard(
                      amount: "RM 1,510.00",
                      semester: "Semester 2 2025/2026",
                      dueWeek: "Due Week 5",
                      status: "ACTIVE",
                    ),

                    const Spacer(),

                    // Action buttons
                    MoonOutlinedButton(
                      buttonSize: MoonButtonSize.lg,
                      isFullWidth: true,
                      onTap: () {
                        // Handle pay tuition
                      },
                      label: const Text("Pay tuition"),
                    ),
                    const SizedBox(height: 12),
                    MoonOutlinedButton(
                      buttonSize: MoonButtonSize.lg,
                      isFullWidth: true,
                      onTap: () {
                        // Handle view transactions
                      },
                      label: const Text("View transactions"),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      color: const Color(0xFF5EE7E7), // cyan/teal from the design
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // SAMS logo
          Text(
            "SAMS",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              letterSpacing: 1,
              shadows: [
                Shadow(
                  offset: const Offset(2, 2),
                  color: Colors.black.withOpacity(0.3),
                ),
              ],
            ),
          ),
          // Menu icon
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.menu, color: Colors.black, size: 28),
          ),
        ],
      ),
    );
  }
}

class _FeeCard extends StatelessWidget {
  final String amount;
  final String semester;
  final String dueWeek;
  final String status;

  const _FeeCard({
    required this.amount,
    required this.semester,
    required this.dueWeek,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFCE4E4), // soft pink background
        borderRadius: BorderRadius.circular(MoonBorders.borders.interactiveSm.topLeft.x),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Amount
          Text(
            amount,
            style: MoonTypography.typography.heading.text32.copyWith(
              color: const Color(0xFFE74C4C), // red
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),

          // Semester + Due
          Text(
            "$semester · $dueWeek",
            style: MoonTypography.typography.body.text14.copyWith(
              color: const Color(0xFFE74C4C),
            ),
          ),
          const SizedBox(height: 12),

          // Status tag (Moon Tag)
          MoonTag(
            tagSize: MoonTagSize.xs,
            backgroundColor: const Color(0xFF2E7D32), // green
            label: Text(
              status,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}