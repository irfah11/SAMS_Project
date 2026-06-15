import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sams/Controller/Manage_Coq_and_Subject_Registration/RegistrationController.dart';
import 'package:sams/Domain/registration_subject.dart';
import 'package:sams/screen/Manage_Menu/student_menu.dart';

class CourseRegScreen extends StatefulWidget {
  final String semester;

  const CourseRegScreen({super.key, required this.semester});

  @override
  State<CourseRegScreen> createState() => _CourseRegScreenState();
}

class _CourseRegScreenState extends State<CourseRegScreen> {
  final String currentStudentId = "CB23041";

  String studentName = "Loading...";
  String studentProgramme = "Loading...";
  String studentAdvisor = "Loading...";

  final RegistrationController _controller = RegistrationController();

  @override
  void initState() {
    super.initState();
    _fetchStudentProfile();
  }

  void _fetchStudentProfile() async {
    try {
      var studentQuery = await FirebaseFirestore.instance
          .collection('student')
          .where('student_id', isEqualTo: currentStudentId)
          .get();

      if (studentQuery.docs.isNotEmpty && mounted) {
        var data = studentQuery.docs.first.data();

        setState(() {
          studentName = data['full_name'] ?? 'No Name';
          studentProgramme = data['programme'] ?? 'No Programme';
          studentAdvisor = data['advisor_name'] ?? 'No Advisor';
        });
      } else {
        setState(() {
          studentName = "Pelajar Tidak Dijumpai";
          studentProgramme = "Sila semak ID";
          studentAdvisor = currentStudentId;
        });
      }
    } catch (e) {
      setState(() {
        studentName = "Ralat: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const StudentDrawer(),

      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF55D3E7),
        elevation: 0,
        toolbarHeight: 64,
        titleSpacing: 27,
        title: const Text(
          'SAMS',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 26,
            letterSpacing: 2,
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
        padding: const EdgeInsets.fromLTRB(18, 10, 10, 24),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(left: 8, right: 2),
              padding: const EdgeInsets.fromLTRB(18, 13, 18, 14),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFD8D8D8)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                children: [
                  _buildDisabledField("Name", studentName),
                  _buildDisabledField("Programme", studentProgramme),
                  _buildDisabledField("Advisor", studentAdvisor),
                  _buildDisabledField("Semester", widget.semester),
                ],
              ),
            ),

            const SizedBox(height: 17),

            _buildDisplayRow("Course"),
            _buildDisplayRow("Section"),
            _buildDisplayRow("Tutorial/Lab"),

            const SizedBox(height: 45),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildHeaderLabel(
                  "Course Registration\nfor approval",
                  120,
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
                _buildHeaderLabel("Course\nRegistration", 78),
              ],
            ),

            StreamBuilder<List<RegistrationSubject>>(
              stream: _controller.getApprovedRegistrations(currentStudentId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(18.0),
                    child: CircularProgressIndicator(),
                  );
                }

                final approvedList = snapshot.data ?? [];

                return Column(
                  children: [
                    _buildRegistrationTable(approvedList),
                    if (approvedList.isNotEmpty)
                      _buildBottomTotal(approvedList),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisabledField(String label, String value) {
    final bool showPlaceholder =
        value.trim().isEmpty || value.toLowerCase().contains("loading");

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
          Expanded(
            child: Container(
              height: 22,
              padding: const EdgeInsets.symmetric(horizontal: 11),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFDADADA), width: 0.8),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.centerLeft,
              child: Text(
                showPlaceholder ? "Value" : value,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: showPlaceholder ? Colors.grey : Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayRow(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
          Expanded(
            child: Container(
              height: 38,
              padding: const EdgeInsets.only(left: 11, right: 5),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFDADADA), width: 0.9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Value",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.black,
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderLabel(String text, double width, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: width,
        height: 32,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFBDBDBD), width: 0.8),
          color: Colors.white,
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.blue,
            height: 1.05,
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrationTable(List<RegistrationSubject> approvedList) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      child: Table(
        border: TableBorder.all(color: const Color(0xFFBDBDBD), width: 0.8),
        columnWidths: const {
          0: FixedColumnWidth(28),
          1: FlexColumnWidth(),
          2: FixedColumnWidth(48),
          3: FixedColumnWidth(42),
          4: FixedColumnWidth(70),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          _buildTableHeader(),
          if (approvedList.isEmpty)
            _buildEmptyRow()
          else
            ...List.generate(approvedList.length, (index) {
              final sub = approvedList[index];

              return _buildTableRow(
                no: (index + 1).toString(),
                subject: '${sub.subjectId}\n${sub.subjectName}',
                section: '${sub.section}\n${sub.tutorialLab}',
                credit: sub.creditHour.toString(),
                regId: sub.regId,
              );
            }),
        ],
      ),
    );
  }

  TableRow _buildTableHeader() {
    return TableRow(
      children: [
        _tableHeaderCell("no", center: true),
        _tableHeaderCell("Subject Code &\nSubject Name"),
        _tableHeaderCell("Section\n& Lab", center: true),
        _tableHeaderCell("Credit\nHour", center: true),
        _tableHeaderCell("Action", center: true),
      ],
    );
  }

  Widget _tableHeaderCell(String text, {bool center = false}) {
    return SizedBox(
      height: 38,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Align(
          alignment: center ? Alignment.center : Alignment.centerLeft,
          child: Text(
            text,
            textAlign: center ? TextAlign.center : TextAlign.left,
            softWrap: true,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black,
              height: 1.1,
            ),
          ),
        ),
      ),
    );
  }

  TableRow _buildEmptyRow() {
    return const TableRow(
      children: [
        SizedBox(height: 60),
        Padding(
          padding: EdgeInsets.all(6),
          child: Text(
            "No approved subject yet.",
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ),
        SizedBox(),
        SizedBox(),
        SizedBox(),
      ],
    );
  }

  TableRow _buildTableRow({
    required String no,
    required String subject,
    required String section,
    required String credit,
    required String regId,
  }) {
    return TableRow(
      children: [
        SizedBox(
          height: 65,
          child: Center(child: Text(no, style: const TextStyle(fontSize: 12))),
        ),

        Padding(
          padding: const EdgeInsets.all(5),
          child: Text(
            subject,
            style: const TextStyle(fontSize: 11, height: 1.05),
          ),
        ),

        Text(
          section,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, height: 1.1),
        ),

        Text(
          credit,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12),
        ),

        Padding(
          padding: const EdgeInsets.all(4),
          child: Center(
            child: SizedBox(
              width: 52,
              height: 29,
              child: ElevatedButton(
                onPressed: () async {
                  await _controller.dropRegisteredCourse(regId);

                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Subject dropped successfully."),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE9E9E9),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: const BorderSide(color: Color(0xFFB7B7B7), width: 0.8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "Drop",
                    maxLines: 1,
                    style: TextStyle(fontSize: 10),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomTotal(List<RegistrationSubject> list) {
    int totalCredits = list.fold(0, (sum, item) => sum + item.creditHour);

    return Table(
      border: TableBorder.all(color: const Color(0xFFBDBDBD), width: 0.8),
      columnWidths: const {
        0: FlexColumnWidth(),
        1: FixedColumnWidth(45),
        2: FixedColumnWidth(70),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          children: [
            const SizedBox(height: 48),
            Center(
              child: Text(
                totalCredits.toString(),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(),
          ],
        ),
      ],
    );
  }
}
