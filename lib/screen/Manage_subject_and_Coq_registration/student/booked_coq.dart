import 'package:flutter/material.dart';

class BookedCoqScreen extends StatelessWidget {
  const BookedCoqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF64D2EC),
        elevation: 0,
        title: const Text(
          'SAMS',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black, size: 28),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. My Co-Q Header with Badge Icon
            Row(
              children: [
                const Icon(
                  Icons.military_tech_outlined,
                  size: 60,
                ), // Mockup badge icon
                const SizedBox(width: 15),
                const Text(
                  'MY Co-Q',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // 2. Section Title
            const Text(
              'Booking Slot',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 15),

            // 3. Booking Table
            Table(
              border: TableBorder.all(color: Colors.grey.shade400, width: 0.5),
              columnWidths: const {
                0: IntrinsicColumnWidth(), // no
                1: FlexColumnWidth(2), // Subject
                2: FlexColumnWidth(2), // Date & Time
                3: FlexColumnWidth(1.5), // Location
                4: FlexColumnWidth(1.5), // Booking
              },
              children: [
                // Table Header
                _buildTableHeader(),

                // Table Data Rows
                _buildTableRow(
                  "1",
                  "Memanah",
                  "30/12/26\n9.00",
                  "Gambang",
                  "48/50",
                  true,
                ),
                _buildTableRow(
                  "2",
                  "Chess",
                  "31/12/26\n9.00",
                  "Pekan",
                  "50/50",
                  false,
                ), // Full
                _buildTableRow(
                  "3",
                  "3D\nModelling",
                  "25/5/26\n9.00",
                  "Pekan",
                  "35/50",
                  true,
                ),
                _buildTableRow(
                  "4",
                  "Mobile\nPhotography",
                  "26/5/26\n9.00",
                  "Gambang",
                  "17/50",
                  true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Table Helper Methods ---

  TableRow _buildTableHeader() {
    return const TableRow(
      children: [
        _CellText("no", isHeader: true),
        _CellText("Subject", isHeader: true),
        _CellText("Date&\nTime", isHeader: true),
        _CellText("location", isHeader: true),
        _CellText("Booking", isHeader: true),
      ],
    );
  }

  TableRow _buildTableRow(
    String no,
    String subject,
    String dateTime,
    String loc,
    String status,
    bool canBook,
  ) {
    return TableRow(
      children: [
        _CellText(no),
        _CellText(subject),
        _CellText(dateTime),
        _CellText(loc),
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 15, bottom: 5),
              child: Text(status, style: const TextStyle(fontSize: 12)),
            ),
            if (canBook)
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: SizedBox(
                  height: 30,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF81D4FA),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text("Book", style: TextStyle(fontSize: 10)),
                  ),
                ),
              )
            else
              const SizedBox(
                height: 34,
              ), // Keeps alignment if button is missing
          ],
        ),
      ],
    );
  }
}

// Helper widget for table cell text alignment
class _CellText extends StatelessWidget {
  final String text;
  final bool isHeader;
  const _CellText(this.text, {this.isHeader = false});

  @override
  Widget build(BuildContext context) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isHeader ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
