import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:sams/Controller/manage_coq_activity/submission_controller.dart';

class SubmissionPage extends StatefulWidget {
  final String subjectId;
  final String assignmentId;

  const SubmissionPage({
    super.key,
    required this.subjectId,
    required this.assignmentId,
  });

  @override
  State<SubmissionPage> createState() => _SubmissionPageState();
}

class _SubmissionPageState extends State<SubmissionPage> {
  bool _showPopup = false;
  bool _isSubmitted = false;
  String _uploadedFileName = '';

  void _togglePopup() {
    setState(() {
      _showPopup = !_showPopup;
    });
  }

  void _submitSubmission() {
    setState(() {
      _isSubmitted = true;
      _uploadedFileName = 'SRS_Version_2.pdf';
      _showPopup = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Submission submitted successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _deleteSubmission() {
    setState(() {
      _isSubmitted = false;
      _uploadedFileName = '';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Submission removed.'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF4CE6FC), // Vivid turquoise/cyan from SAMS design
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.only(top: 24, left: 16, right: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SAMS',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Inter',
                  color: Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.black, size: 30),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          // Main Scrollable Screen
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Arrow + Title Row
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                          size: 28,
                        ),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Submission SRS',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Inter',
                            color: Colors.black,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Info Box (Open / Due date details)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14.0),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFF1F5F9,
                      ), // Light grey matching design
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black.withOpacity(0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Open : Monday, 16/3/2026, 11:59 pm',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontFamily: 'Inter',
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Due : Monday, 6/4/2026, 1.00 pm',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Add Submission Button (Solid Blue)
                  SizedBox(
                    height: 38,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF60A5FA), // Accent Blue
                        foregroundColor: Colors.black,
                        elevation: 4,
                        shadowColor: Colors.black.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: const BorderSide(
                            color: Colors.black87,
                            width: 1.2,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onPressed: _togglePopup,
                      child: const Text(
                        'Add Submission',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Submission Status Section Title
                  const Text(
                    'Submission Status',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Inter',
                      color: Colors.black,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Edit Submission Button (Mint Green)
                  SizedBox(
                    height: 38,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF5EEAD4,
                        ), // Mint Green/Turquoise
                        foregroundColor: Colors.black,
                        elevation: 3,
                        shadowColor: Colors.black.withOpacity(0.15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: const BorderSide(
                            color: Colors.black87,
                            width: 1.2,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      onPressed: _togglePopup,
                      child: const Text(
                        'Edit Submission',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Table of Submission details
                  Table(
                    border: TableBorder.all(
                      color: Colors.grey.shade400,
                      width: 1.2,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    columnWidths: const {
                      0: FractionColumnWidth(0.38),
                      1: FractionColumnWidth(0.62),
                    },
                    children: [
                      _buildTableRow(
                        'Submission status',
                        _isSubmitted
                            ? _uploadedFileName
                            : 'No submission have been done yet',
                        isHighlight: !_isSubmitted,
                      ),
                      _buildTableRow(
                        'Grade status',
                        _isSubmitted ? 'Graded (95/100)' : 'No graded',
                      ),
                      _buildTableRow(
                        'Time remaining',
                        _isSubmitted
                            ? 'Submitted 12 days early'
                            : '2 days 22 hours',
                      ),
                      _buildTableRow(
                        'Last modified',
                        _isSubmitted ? 'Monday, 25/3/2026, 3:45 pm' : '-',
                      ),
                      _buildTableRow(
                        'Submission comment',
                        _isSubmitted ? 'comment (1)' : 'comment (0)',
                      ),
                    ],
                  ),

                  const SizedBox(height: 48),

                  // Back to the course button (Centered Grey Button)
                  Center(
                    child: SizedBox(
                      width: 160,
                      height: 42,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFFE2E8F0,
                          ), // Slate grey
                          foregroundColor: Colors.black,
                          elevation: 3,
                          shadowColor: Colors.black.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Back to the course',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Dialog Overlay Backing (Blur / Semitransparent screen dimmer)
          if (_showPopup)
            GestureDetector(
              onTap: _togglePopup,
              child: Container(
                color: Colors.black.withOpacity(0.35),
                width: double.infinity,
                height: double.infinity,
              ),
            ),

          // Custom Add Submission Dialog Box (Image 2)
          if (_showPopup)
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.88,
                padding: const EdgeInsets.all(18.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Popup Heading
                    const Text(
                      'Add Submission',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Inter',
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // File upload container
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Top utility bar (Document icons)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.insert_drive_file_outlined,
                                  color: Colors.grey.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.note_add_outlined,
                                  color: Colors.grey.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.delete_outline,
                                  color: Colors.grey.shade700,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),

                          // Big Drop area with Arrow Up icon
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 36.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.file_upload_outlined,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                if (_uploadedFileName.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    _uploadedFileName,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Below attachment action buttons
                    Row(
                      children: [
                        // + Upload file
                        SizedBox(
                          height: 32,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6), // Blue
                              foregroundColor: Colors.black,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                                side: const BorderSide(
                                  color: Colors.black87,
                                  width: 1,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _uploadedFileName = 'SRS_Submission_Final.pdf';
                              });
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.add,
                                  size: 14,
                                  color: Colors.black87,
                                ),
                                SizedBox(width: 2),
                                Text(
                                  'Upload file',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Edit
                        SizedBox(
                          height: 32,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xFF4ADECD,
                              ), // Turquoise
                              foregroundColor: Colors.black,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                                side: const BorderSide(
                                  color: Colors.black87,
                                  width: 1,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                            ),
                            onPressed: () {
                              if (_uploadedFileName.isNotEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Renamed files in submission to: final_edit.pdf',
                                    ),
                                    backgroundColor: Colors.blue,
                                  ),
                                );
                                setState(() {
                                  _uploadedFileName = 'final_edit.pdf';
                                });
                              }
                            },
                            child: const Text(
                              'Edit',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Cancel & Submit Row at bottom-right
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Cancel (Pinkish red)
                        SizedBox(
                          height: 34,
                          width: 80,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xFFF87171,
                              ), // Soft red/pink
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                                side: const BorderSide(
                                  color: Colors.black87,
                                  width: 1,
                                ),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: _togglePopup,
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Submit (Green)
                        SizedBox(
                          height: 34,
                          width: 80,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xFF86EFAC,
                              ), // Soft Green
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                                side: const BorderSide(
                                  color: Colors.black87,
                                  width: 1,
                                ),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: _submitSubmission,
                            child: const Text(
                              'Submit',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(
    String title,
    String value, {
    bool isHighlight = false,
  }) {
    return TableRow(
      children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 11.0,
            ),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 10.0,
              vertical: 11.0,
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
                color: isHighlight ? Colors.black54 : Colors.black87,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
