import 'package:flutter/material.dart';
import 'package:sams/screen/Manage_subject_coQ_activity/Lecturer/lecturer_subject_page.dart';

class ViewSubmissionPage extends StatefulWidget {
  const ViewSubmissionPage({super.key});

  @override
  State<ViewSubmissionPage> createState() => _ViewSubmissionPageState();
}

class _ViewSubmissionPageState extends State<ViewSubmissionPage> {
  // Mock data list matching your exact table from the image
  final List<Map<String, dynamic>> _submissions = [
    {
      'no': '1',
      'id': 'CB23028',
      'name': 'Nurul Balqis binti Azman',
      'hasSubmitted': true,
    },
    {'no': '2', 'id': 'CB23040', 'name': 'Wardah Wafin', 'hasSubmitted': false},
    {'no': '3', 'id': 'CD23011', 'name': 'Naim Aqasha', 'hasSubmitted': false},
    {'no': '4', 'id': 'CS23048', 'name': 'Afiq Aiman', 'hasSubmitted': true},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF446BE6), // SAMS Vibrant Blue
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'SAMS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 24,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white, size: 28),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Back Arrow + Title
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Row(
                children: [
                  const Icon(Icons.arrow_back, color: Colors.black87, size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'View Submission',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Table Box Wrapper with subtle Border and Radius
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE5E7EB)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Table(
                  border: TableBorder.all(
                    color: const Color(0xFFE5E7EB),
                    style: BorderStyle.solid,
                    width: 1,
                  ),
                  columnWidths: const {
                    0: FlexColumnWidth(0.8), // "no"
                    1: FlexColumnWidth(1.4), // "ID"
                    2: FlexColumnWidth(2.5), // "Name"
                    3: FlexColumnWidth(1.5), // "Status"
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    // TABLE HEADERS row
                    TableRow(
                      decoration: const BoxDecoration(color: Color(0xFFF9FAFB)),
                      children: [
                        _buildHeaderCell('no'),
                        _buildHeaderCell('ID'),
                        _buildHeaderCell('Name'),
                        _buildHeaderCell('Status'),
                      ],
                    ),

                    // Table items loop
                    ..._submissions.map((submission) {
                      return TableRow(
                        children: [
                          _buildTableCell(
                            submission['no'],
                            alignment: Alignment.center,
                          ),
                          _buildTableCell(
                            submission['id'],
                            alignment: Alignment.center,
                          ),
                          _buildTableCell(
                            submission['name'],
                            alignment: Alignment.centerLeft,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF111827),
                            ),
                          ),
                          _buildStatusCell(submission['hasSubmitted']),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget to construct standard Table Header Cells
  Widget _buildHeaderCell(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4B5563),
        ),
      ),
    );
  }

  // Helper widget to construct cell structures
  Widget _buildTableCell(
    String text, {
    required Alignment alignment,
    TextStyle? style,
  }) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      alignment: alignment,
      child: Text(
        text,
        style: style ?? const TextStyle(fontSize: 12, color: Color(0xFF374151)),
      ),
    );
  }

  // Helper widget to paint the Submit / Unsubmitted status pill/button matching layout
  Widget _buildStatusCell(bool hasSubmitted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 12.0),
      alignment: Alignment.center,
      child: Container(
        decoration: BoxDecoration(
          color: hasSubmitted
              ? const Color(0xFFD1FAE5)
              : const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: hasSubmitted
                ? const Color(0xFF10B981)
                : const Color(0xFFEF4444),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          hasSubmitted ? 'Submit' : 'Unsubmitted',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: hasSubmitted
                ? const Color(0xFF065F46)
                : const Color(0xFF991B1B),
          ),
        ),
      ),
    );
  }
}
