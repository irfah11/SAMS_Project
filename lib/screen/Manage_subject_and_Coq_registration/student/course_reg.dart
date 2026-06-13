import 'package:flutter/material.dart';
import 'package:sams/screen/Manage_Menu/student_menu.dart';

class CourseRegScreen extends StatefulWidget {
  final String semester;

  const CourseRegScreen({super.key, required this.semester});

  @override
  State<CourseRegScreen> createState() => _CourseRegScreenState();
}

class _CourseRegScreenState extends State<CourseRegScreen> {
  // Dropdown variables
  String? selectedCourse;
  String? selectedSection;
  String? selectedLab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const StudentDrawer(),

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
            const SizedBox(height: 20),

            // 2. Selection UI (This was missing in your emulator!)
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

            // 3. Add Button
            ElevatedButton(
              onPressed: () {
                // Logic to add more to the list can go here
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF64D2EC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 30),
              ),
              child: const Text("Add", style: TextStyle(color: Colors.black)),
            ),
            const SizedBox(height: 25),

            // 4. Labels above Table
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildHeaderLabel("Course Registration\nfor approval", 115),
                _buildHeaderLabel("Course\nRegistration", 85),
              ],
            ),

            // 5. Registration Table (Populated as per Figma)
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
                _buildTableRow(
                  "1",
                  "BCS3133 Software\nEngineering Practices",
                  "01\n01B",
                  "3",
                ),
                _buildTableRow(
                  "2",
                  "BCS3153 Software Evolution\nMaintenance",
                  "02\n02B",
                  "3",
                ),
              ],
            ),

            // 6. Total and Notify (Total is fixed to align with Credit Hour column)
            _buildBottomControls(),
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
                  items: ["Data 1", "Data 2"]
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
                onPressed: () {},
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
            const TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  "6",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
