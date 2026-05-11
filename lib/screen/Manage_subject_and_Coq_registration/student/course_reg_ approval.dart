// ignore: file_names
import 'package:flutter/material.dart';
// IMPORTANT: Make sure this matches your actual filename for the second screen
import 'course_reg.dart';

class CourseRegApprovalScreen extends StatefulWidget {
  final String semester;

  const CourseRegApprovalScreen({super.key, required this.semester});

  @override
  State<CourseRegApprovalScreen> createState() =>
      _CourseRegApprovalScreenState();
}

class _CourseRegApprovalScreenState extends State<CourseRegApprovalScreen> {
  // Logic to track registered subjects
  List<Map<String, String>> registeredSubjects = [];

  // Dropdown variables
  String? selectedCourse;
  String? selectedSection;
  String? selectedLab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF64D2EC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
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
          children: [
            // 1. Student Profile Section
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildDisabledField("Name", "Value"),
                  _buildDisabledField("Programme", "Value"),
                  _buildDisabledField("Advisor", "Value"),
                  _buildDisabledField("Semester", widget.semester),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // 2. Selection UI
            _buildDropdown(
              "Course",
              selectedCourse,
              (val) => setState(() => selectedCourse = val),
            ),
            _buildDropdown(
              "Section",
              selectedSection,
              (val) => setState(() => selectedSection = val),
            ),
            _buildDropdown(
              "Tutorial/Lab",
              selectedLab,
              (val) => setState(() => selectedLab = val),
            ),
            const SizedBox(height: 15),

            // 3. THE ADD BUTTON (Navigation logic added here)
            ElevatedButton(
              onPressed: () {
                // This is the "Magic Link" that sends the user to the second page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CourseRegScreen(semester: widget.semester),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF64D2EC), // Blue color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 30),
              ),
              child: const Text("Add", style: TextStyle(color: Colors.black)),
            ),

            const SizedBox(height: 30),

            // 4. Labels above Table
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildHeaderLabel("Course Registration\nfor approval", 115),
                _buildHeaderLabel("Course\nRegistration", 85),
              ],
            ),

            // 5. Registration Table with Empty State Logic
            Table(
              border: TableBorder.all(color: Colors.grey.shade400),
              columnWidths: const {
                0: IntrinsicColumnWidth(),
                1: FlexColumnWidth(4),
                2: FlexColumnWidth(1.5),
                3: FlexColumnWidth(1),
                4: FlexColumnWidth(2),
              },
              children: [
                _buildTableHeader(),
                if (registeredSubjects.isEmpty)
                  TableRow(
                    children: [
                      const SizedBox(),
                      TableCell(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          alignment: Alignment.center,
                          child: const Text(
                            "You haven't registered any subjects yet.",
                            style: TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(),
                      const SizedBox(),
                      const SizedBox(),
                    ],
                  )
                else
                  ...registeredSubjects
                      .map(
                        (sub) => _buildTableRow(
                          sub['no']!,
                          sub['subject']!,
                          sub['section']!,
                          sub['credit']!,
                        ),
                      )
                      .toList(),
              ],
            ),

            // Only show bottom total/notify if there are subjects
            if (registeredSubjects.isNotEmpty) _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  // --- UI Helper Methods ---

  Widget _buildDisabledField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(
            width: 85,
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            child: Container(
              height: 35,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String? value,
    ValueChanged<String?> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        children: [
          SizedBox(
            width: 85,
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: value,
                  isExpanded: true,
                  hint: const Text(
                    "Value",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  items: ["Subject A", "Subject B"]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: onChanged,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderLabel(String text, double width) {
    return Container(
      width: width,
      height: 45,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        color: const Color(0xFFF0F4FF),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 10,
          color: Colors.blue,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  TableRow _buildTableHeader() {
    return const TableRow(
      children: [
        Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            "no",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            "Subject Code & Subject Name",
            style: TextStyle(fontSize: 11),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            "Section & Lab",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            "Credit Hour",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11),
          ),
        ),
        Padding(
          padding: EdgeInsets.all(8),
          child: Text(
            "Action",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11),
          ),
        ),
      ],
    );
  }

  TableRow _buildTableRow(
    String no,
    String subject,
    String section,
    String credit,
  ) {
    return TableRow(
      children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Text(no, textAlign: TextAlign.center),
        ),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(subject, style: const TextStyle(fontSize: 11)),
          ),
        ),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Text(
            section,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11),
          ),
        ),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Text(credit, textAlign: TextAlign.center),
        ),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Container(
              height: 30,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    registeredSubjects.removeWhere((item) => item['no'] == no);
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  foregroundColor: Colors.black,
                  elevation: 0,
                  side: BorderSide(color: Colors.grey.shade400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: const Text("Drop", style: TextStyle(fontSize: 10)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomControls() {
    int totalCredits = registeredSubjects.fold(
      0,
      (sum, item) => sum + int.parse(item['credit']!),
    );
    return Table(
      border: TableBorder.all(color: Colors.grey.shade400),
      columnWidths: const {
        0: FlexColumnWidth(6.6),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(2),
      },
      children: [
        TableRow(
          children: [
            const SizedBox(),
            TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  totalCredits.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: Container(
                height: 38,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00D084),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    "notify",
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
