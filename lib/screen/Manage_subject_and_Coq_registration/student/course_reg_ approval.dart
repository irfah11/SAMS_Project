// ignore: file_names
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sams/Controller/Manage_Coq_and_Subject_Registration/RegistrationController.dart';
import 'package:sams/Domain/registration_subject.dart';

class CourseRegApprovalScreen extends StatefulWidget {
  final String semester;

  const CourseRegApprovalScreen({super.key, required this.semester});

  @override
  State<CourseRegApprovalScreen> createState() =>
      _CourseRegApprovalScreenState();
}

class _CourseRegApprovalScreenState extends State<CourseRegApprovalScreen> {
  // 1. ID Pelajar aktif berdasarkan String unik pangkalan data Firebase
  final String currentStudentId = "CB23041";

  // Pembolehubah untuk menyimpan maklumat profil pelajar dari database secara dinamik
  String studentName = "Loading...";
  String studentProgramme = "Loading...";
  String studentAdvisor = "Loading...";

  // Pembolehubah untuk menjejak pilihan dropdown subjek
  List<QueryDocumentSnapshot> _allFacultyCourses = [];
  String? _selectedSubjectId;
  String? _selectedSection;
  String? _selectedLab;
  Map<String, dynamic>? _currentSelectedCourseData;

  final RegistrationController _controller = RegistrationController();

  @override
  void initState() {
    super.initState();
    _fetchStudentProfile();
  }

  // 2. Fungsi membaca dokumen profil dari koleksi 'student'
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
          studentAdvisor = "CB23041";
        });
      }
    } catch (e) {
      setState(() {
        studentName = "Ralat: $e";
      });
    }
  }

  // Fungsi menyimpan pendaftaran subjek dan terus dipaparkan pada jadual secara real-time
  void _addCourseToApproval() async {
    if (_selectedSubjectId == null ||
        _selectedSection == null ||
        _selectedLab == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sila pilih Course, Section dan Tutorial/Lab!'),
        ),
      );
      return;
    }

    String uniqueRegId = 'REG_${DateTime.now().millisecondsSinceEpoch}';

    // Menukar String ID "CB23041" kepada Integer untuk memenuhi keperluan jenis data domain model
    int parsedStudentId =
        int.tryParse(currentStudentId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

    RegistrationSubject newReg = RegistrationSubject(
      regId: uniqueRegId,
      studentId: parsedStudentId, // Nilai integer untuk entiti model domain
      fullName: studentName,
      programme: studentProgramme,
      advisorName: studentAdvisor,
      semester: int.tryParse(widget.semester) ?? 1,
      subjectId: _currentSelectedCourseData!['subject_id'] ?? '',
      subjectName: _currentSelectedCourseData!['subject_name'] ?? '',
      section: _selectedSection!,
      tutorialLab: _selectedLab!,
      creditHour: 3,
      status: 'Pending',
    );

    try {
      // PERUBAHAN UTAMA: Menyimpan transaksi pendaftaran baharu ke Firebase
      await _controller.submitCourseRegistration(newReg);

      // Mengemaskini field 'student_id' secara nyata dalam dokumen transaksi kepada String "CB23041"
      // supaya sepadan dengan struktur kueri carian getPendingRegistrations()
      await FirebaseFirestore.instance
          .collection('course_registrations')
          .doc(uniqueRegId)
          .update({'student_id': currentStudentId});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subjek berjaya dihantar untuk kelulusan!'),
        ),
      );

      // Mengosongkan semula pilihan input dropdown selepas berjaya ditambah
      setState(() {
        _selectedSubjectId = null;
        _selectedSection = null;
        _selectedLab = null;
        _currentSelectedCourseData = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ralat semasa mendaftar: $e')));
    }
  }

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
            // 1. Dynamic Student Profile Section
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
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
            const SizedBox(height: 25),

            // 2. Selection UI (Menarik data dari Faculty Registrar)
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('course_subjects')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();

                _allFacultyCourses = snapshot.data!.docs;

                // Tapis kod subjek unik untuk dimasukkan ke Dropdown Course
                Set<String> uniqueSubjectIds = {};
                List<Map<String, dynamic>> uniqueCoursesList = [];

                for (var doc in _allFacultyCourses) {
                  var data = doc.data() as Map<String, dynamic>;
                  String sId = data['subject_id'] ?? data['subjectId'] ?? '';
                  if (sId.isNotEmpty && !uniqueSubjectIds.contains(sId)) {
                    uniqueSubjectIds.add(sId);
                    uniqueCoursesList.add(data);
                  }
                }

                // Tapis Section & Lab secara dinamik mengikut subjek yang dipilih
                List<String> availableSections = [];
                List<String> availableLabs = [];

                if (_selectedSubjectId != null) {
                  for (var doc in _allFacultyCourses) {
                    var data = doc.data() as Map<String, dynamic>;
                    if ((data['subject_id'] ?? data['subjectId']) ==
                        _selectedSubjectId) {
                      if (data['section'] != null &&
                          !availableSections.contains(data['section'])) {
                        availableSections.add(data['section']);
                      }
                      String labKey =
                          data['tutorial_lab'] ?? data['TutorialLab'] ?? '';
                      if (labKey.isNotEmpty &&
                          !availableLabs.contains(labKey)) {
                        availableLabs.add(labKey);
                      }
                    }
                  }
                }

                return Column(
                  children: [
                    // DROPDOWN: Course
                    _buildDropdownRow(
                      "Course",
                      DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text(
                          "Value",
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        value: _selectedSubjectId,
                        items: uniqueCoursesList.map((course) {
                          String sId =
                              course['subject_id'] ?? course['subjectId'] ?? '';
                          String sName =
                              course['subject_name'] ??
                              course['subjectName'] ??
                              'No Name';
                          return DropdownMenuItem<String>(
                            value: sId,
                            child: Text(
                              '$sId $sName',
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedSubjectId = val;
                            _selectedSection = null;
                            _selectedLab = null;
                            _currentSelectedCourseData = uniqueCoursesList
                                .firstWhere(
                                  (c) =>
                                      (c['subject_id'] ?? c['subjectId']) ==
                                      val,
                                );
                          });
                        },
                      ),
                    ),

                    // DROPDOWN: Section
                    _buildDropdownRow(
                      "Section",
                      DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text(
                          "Value",
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        value: _selectedSection,
                        items: availableSections.map((sec) {
                          return DropdownMenuItem<String>(
                            value: sec,
                            child: Text(
                              sec,
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => _selectedSection = val),
                      ),
                    ),

                    // DROPDOWN: Tutorial/Lab
                    _buildDropdownRow(
                      "Tutorial/Lab",
                      DropdownButton<String>(
                        isExpanded: true,
                        hint: const Text(
                          "Value",
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        value: _selectedLab,
                        items: availableLabs.map((lab) {
                          return DropdownMenuItem<String>(
                            value: lab,
                            child: Text(
                              lab,
                              style: const TextStyle(fontSize: 13),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedLab = val),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 15),

            // 3. THE ADD BUTTON
            ElevatedButton(
              onPressed: _addCourseToApproval,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF64D2EC),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 30),
              ),
              child: const Text("Add", style: TextStyle(color: Colors.black)),
            ),
            const SizedBox(height: 30),

            // 4. Table Headers Label
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildHeaderLabel("Course Registration\nfor approval", 115),
                _buildHeaderLabel("Course\nRegistration", 85),
              ],
            ),

            // 5. Real-Time Registration Table (StreamBuilder)
            StreamBuilder<List<RegistrationSubject>>(
              stream: _controller.getPendingRegistrations(currentStudentId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  );
                }

                var registeredList = snapshot.data ?? [];

                return Column(
                  children: [
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
                        if (registeredList.isEmpty)
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
                          ...List.generate(registeredList.length, (index) {
                            var sub = registeredList[index];
                            return _buildTableRow(
                              (index + 1).toString(),
                              '${sub.subjectId}\n${sub.subjectName}',
                              '${sub.section}\n${sub.tutorialLab}',
                              sub.creditHour.toString(),
                              sub.regId,
                            );
                          }),
                      ],
                    ),

                    // 6. Tampilkan kawalan bawah (Total & Notify) sekiranya jadual tidak kosong
                    if (registeredList.isNotEmpty)
                      _buildBottomControls(registeredList),
                  ],
                );
              },
            ),
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
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownRow(String label, Widget dropdownWidget) {
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
              child: DropdownButtonHideUnderline(child: dropdownWidget),
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
    String regId,
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
            child: SizedBox(
              height: 30,
              child: ElevatedButton(
                onPressed: () => _controller.dropRegisteredCourse(regId),
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

  Widget _buildBottomControls(List<RegistrationSubject> list) {
    int totalCredits = list.fold(0, (sum, item) => sum + item.creditHour);

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
              child: SizedBox(
                height: 38,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Academic Advisor has been notified successfully!',
                        ),
                      ),
                    );
                  },
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
