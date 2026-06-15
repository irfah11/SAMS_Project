import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sams/Controller/Manage_Coq_and_Subject_Registration/RegistrationController.dart';
import 'package:sams/screen/Manage_Menu/lecture_menu.dart';

class ApprovalReg extends StatefulWidget {
  const ApprovalReg({super.key});

  @override
  State<ApprovalReg> createState() => _ApprovalRegState();
}

class _ApprovalRegState extends State<ApprovalReg> {
  final RegistrationController _controller = RegistrationController();

  String _toText(dynamic value) {
    if (value == null) return '-';
    return value.toString();
  }

  // ignore: unused_element
  String _shortText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  Future<void> _approveSubject(String regId) async {
    try {
      await _controller.approveRegistration(regId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Subject registration approved successfully!"),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to approve: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const LecturerDrawer(),

      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF4A69FF),
        elevation: 0,
        toolbarHeight: 64,
        titleSpacing: 27,
        title: const Text(
          'SAMS',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 24,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu, color: Colors.black, size: 32),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 28, 14, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header like Figma
            Row(
              children: const [
                Icon(Icons.menu_book_outlined, size: 72, color: Colors.black87),
                SizedBox(width: 18),
                Expanded(
                  child: Text(
                    'Approval\nCourse\nRegistration',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                      height: 1.15,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            StreamBuilder<QuerySnapshot>(
              stream: _controller.getCourseRegistrationsForLecturer(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(25),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text(
                    "No course registration found.",
                    style: TextStyle(color: Colors.grey),
                  );
                }

                final allRegistrations = snapshot.data!.docs;

                final Map<String, QueryDocumentSnapshot> uniqueMap = {};

                for (final doc in allRegistrations) {
                  final data = doc.data() as Map<String, dynamic>;

                  final studentId = (data['student_id'] ?? '')
                      .toString()
                      .trim();
                  final subjectId = (data['subject_id'] ?? '')
                      .toString()
                      .trim();
                  final subjectName = (data['subject_name'] ?? '')
                      .toString()
                      .trim();

                  final key = '$studentId-$subjectId-$subjectName';

                  if (!uniqueMap.containsKey(key)) {
                    uniqueMap[key] = doc;
                  } else {
                    final oldData =
                        uniqueMap[key]!.data() as Map<String, dynamic>;

                    final oldStatus = (oldData['status'] ?? '')
                        .toString()
                        .toLowerCase();
                    final newStatus = (data['status'] ?? '')
                        .toString()
                        .toLowerCase();

                    // If one duplicate is Approved, show the Approved one
                    if (oldStatus != 'approved' && newStatus == 'approved') {
                      uniqueMap[key] = doc;
                    }
                  }
                }

                final registrations = uniqueMap.values.toList();

                return Table(
                  border: TableBorder.all(
                    color: const Color(0xFFBDBDBD),
                    width: 0.7,
                  ),
                  columnWidths: const {
                    0: FixedColumnWidth(28),
                    1: FixedColumnWidth(48),
                    2: FlexColumnWidth(1.35),
                    3: FlexColumnWidth(1.25),
                    4: FixedColumnWidth(58),
                  },
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    _buildTableHeader(),

                    ...List.generate(registrations.length, (index) {
                      final doc = registrations[index];
                      final data = doc.data() as Map<String, dynamic>;

                      final String studentId = _toText(data['student_id']);
                      final String fullName = _toText(data['full_name']);
                      final String subjectName = _toText(data['subject_name']);
                      final String subjectId = _toText(data['subject_id']);
                      final String status = _toText(data['status']);

                      return _buildDataRow(
                        no: (index + 1).toString(),
                        regId: doc.id,
                        studentId: studentId,
                        name: fullName,
                        subject: '$subjectId\n$subjectName',
                        status: status,
                      );
                    }),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildTableHeader() {
    return TableRow(
      children: [
        _headerCell("no"),
        _headerCell("ID"),
        _headerCell("Name"),
        _headerCell("Subject"),
        _headerCell("Status"),
      ],
    );
  }

  Widget _headerCell(String text) {
    return Container(
      height: 32,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(3),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ),
    );
  }

  TableRow _buildDataRow({
    required String no,
    required String regId,
    required String studentId,
    required String name,
    required String subject,
    required String status,
  }) {
    final bool isPending = status.toLowerCase() == 'pending';

    return TableRow(
      children: [
        _bodyCell(no, height: 105),
        _bodyCell(studentId, height: 105),
        _bodyCell(name, height: 105, alignLeft: true),
        _bodyCell(subject, height: 105, alignLeft: true),

        SizedBox(
          height: 105,
          child: Center(
            child: isPending
                ? SizedBox(
                    width: 52,
                    height: 34,
                    child: ElevatedButton(
                      onPressed: () {
                        _approveSubject(regId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF81D4FA),
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: const BorderSide(
                          color: Color(0xFF4FA7C4),
                          width: 0.7,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      child: const Text(
                        "Approve\nNow",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          height: 1.05,
                        ),
                      ),
                    ),
                  )
                : const Text(
                    "Approved",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 10),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _bodyCell(String text, {double height = 90, bool alignLeft = false}) {
    return SizedBox(
      height: height,
      child: Align(
        alignment: alignLeft ? Alignment.centerLeft : Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Text(
            text,
            textAlign: alignLeft ? TextAlign.left : TextAlign.center,
            style: const TextStyle(
              fontSize: 10.5,
              color: Colors.black,
              height: 1.15,
            ),
          ),
        ),
      ),
    );
  }
}
