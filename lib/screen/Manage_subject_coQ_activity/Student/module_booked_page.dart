import 'dart:io'; // <-- REQUIRED for 'File'
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart'; // <-- REQUIRED for 'FilePicker' and 'PlatformFile'
import 'package:firebase_storage/firebase_storage.dart'; // <-- REQUIRED for 'FirebaseStorage'
import 'package:open_file/open_file.dart';
import 'package:sams/Domain/cocurriculum.dart';

class ModuleBookedPage extends StatefulWidget {
  const ModuleBookedPage({super.key});

  @override
  State<ModuleBookedPage> createState() => _ModuleBookedPageState();
}

class _ModuleBookedPageState extends State<ModuleBookedPage> {
  bool _showPopup = false;
  bool _isClaimed = false;

  File? _selectedFile;
  String _uploadedFile = '';

  Future<void> pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
      );

      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);

          _uploadedFile = result.files.single.name;
        });
      }
    } catch (e) {
      debugPrint('Pick File Error: $e');
    }
  }

  Future<String?> uploadFileToFirebase() async {
    if (_selectedFile == null) return null;

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('credit_claims')
          .child('${DateTime.now().millisecondsSinceEpoch}_$_uploadedFile');

      UploadTask uploadTask = storageRef.putFile(_selectedFile!);

      TaskSnapshot snapshot = await uploadTask;

      String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint('Upload Error: $e');
      return null;
    }
  }

  void _togglePopup() {
    setState(() {
      _showPopup = !_showPopup;
    });
  }

  Future<void> _submitClaim() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file first')),
      );
      return;
    }

    String? fileUrl = await uploadFileToFirebase();

    if (fileUrl == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to upload file')));
      return;
    }

    setState(() {
      _isClaimed = true;
      _showPopup = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Credit claim submitted successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    debugPrint('Uploaded URL: $fileUrl');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF4CE6FC), // Vivid Turquoise SAMS Header theme
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
          // Main Body Scrollable
          SingleChildScrollView(
            scrollDirection: Axis.vertical,
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Arrow + Header title match precisely
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
                      const Text(
                        'Modules Booked',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'Inter',
                          color: Colors.black,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Horizontal scrollable table container to hold the wide layout gracefully on small device screens
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade400,
                          width: 1.2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Table(
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        columnWidths: const {
                          0: FixedColumnWidth(130), // Module
                          1: FixedColumnWidth(75), // Campus
                          2: FixedColumnWidth(75), // Venue
                          3: FixedColumnWidth(110), // Class Date
                          4: FixedColumnWidth(85), // Attendance
                          5: FixedColumnWidth(110), // Credit Claim Button
                        },
                        border: TableBorder.symmetric(
                          inside: BorderSide(
                            color: Colors.grey.shade400,
                            width: 1.2,
                          ),
                        ),
                        children: [
                          // Table Header
                          TableRow(
                            decoration: const BoxDecoration(
                              color: Color(0xFFF8FAFC),
                            ),
                            children: [
                              _buildHeaderCell('Module'),
                              _buildHeaderCell('Campus'),
                              _buildHeaderCell('Venue'),
                              _buildHeaderCell('Class Date'),
                              _buildHeaderCell('Attendance'),
                              _buildHeaderCell('Credit Claim'),
                            ],
                          ),
                          // ONLY Row 1 as requested: HQD3012 3D DESIGN + 3D PRINTING
                          TableRow(
                            children: [
                              // Module column
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'HQD3012 3D DESIGN + 3D PRINTING',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Campus column
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'PEKAN',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                              // Venue column
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(
                                    'FKP-G-\nBK-06',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                              // Class Date column
                              const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Text(
                                  '16/03/2026\n08:00 AM -\n16/03/2026\n17:00 PM',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    height: 1.3,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              // Attendance column (Pill box styled)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                    horizontal: 4.0,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF4ADE80,
                                      ), // Vivid light green
                                      borderRadius: BorderRadius.circular(4),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 1,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: const Text(
                                      'PRESENT',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Credit Claim Button column
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: _isClaimed
                                      ? const Text(
                                          'Completed',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : SizedBox(
                                          height: 30,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFFE2E8F0,
                                              ), // light grey/white
                                              foregroundColor: Colors.black,
                                              shadowColor: Colors.black12,
                                              elevation: 2,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                side: const BorderSide(
                                                  color: Colors.black54,
                                                  width: 1,
                                                ),
                                              ),
                                            ),
                                            onPressed: _togglePopup,
                                            child: const Text(
                                              'Credit Claim',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Inter',
                                              ),
                                            ),
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
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Semitransparent Backdrop when popup is visible
          if (_showPopup)
            GestureDetector(
              onTap: _togglePopup,
              child: Container(
                color: Colors.black.withOpacity(0.35),
                width: double.infinity,
                height: double.infinity,
              ),
            ),

          // Pop up Box (Image 2)
          if (_showPopup)
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.88,
                padding: const EdgeInsets.all(18.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 15,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Heading title
                    const Text(
                      'Credit Claim',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Inter',
                        color: Colors.black,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Media file upload box container
                    Container(
                      width: double.infinity,
                      height: 160,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          // File toolbar
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: pickFile,
                                  icon: Icon(
                                    Icons.insert_drive_file_outlined,
                                    color: Colors.grey.shade700,
                                  ),
                                ),

                                IconButton(
                                  onPressed: pickFile,
                                  icon: Icon(
                                    Icons.note_add_outlined,
                                    color: Colors.grey.shade700,
                                  ),
                                ),

                                IconButton(
                                  onPressed: () async {
                                    if (_uploadedFile.isNotEmpty) {
                                      await OpenFile.open(_uploadedFile);
                                    }
                                  },
                                  icon: Icon(
                                    Icons.visibility_outlined,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Upload Area
                          Expanded(
                            child: InkWell(
                              onTap: pickFile,
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.file_upload_outlined,
                                        size: 32,
                                        color: Colors.grey.shade400,
                                      ),

                                      const SizedBox(height: 6),

                                      Text(
                                        _uploadedFile.isEmpty
                                            ? 'No files selected'
                                            : _uploadedFile.split('/').last,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: _uploadedFile.isEmpty
                                              ? Colors.grey.shade400
                                              : Colors.blueAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Action upload and edit buttons row
                    Row(
                      children: [
                        // + Upload file Button (Turquoise blue background with black text)
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
                                  width: 1.2,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _uploadedFile = 'Receipt_SAMS_Claim.jpg';
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
                        const SizedBox(width: 8),
                        // Edit button (Cyan-turquoise with black text)
                        SizedBox(
                          height: 32,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4ADECD), // Cyan
                              foregroundColor: Colors.black,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                                side: const BorderSide(
                                  color: Colors.black87,
                                  width: 1.2,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                            ),
                            onPressed: () {
                              if (_uploadedFile.isNotEmpty) {
                                setState(() {
                                  _uploadedFile = 'edited_claim_receipt.jpg';
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

                    // Double action buttons row: Cancel and Submit at bottom right
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Cancel (coral red)
                        SizedBox(
                          height: 34,
                          width: 80,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xFFF87171,
                              ), // soft coral red
                              foregroundColor: Colors.black,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                                side: const BorderSide(
                                  color: Colors.black87,
                                  width: 1.2,
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
                        // Submit (mint green)
                        SizedBox(
                          height: 34,
                          width: 80,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF86EFAC), // Green
                              foregroundColor: Colors.black,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                                side: const BorderSide(
                                  color: Colors.black87,
                                  width: 1.2,
                                ),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: _submitClaim,
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

  Widget _buildHeaderCell(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
      ),
    );
  }
}
