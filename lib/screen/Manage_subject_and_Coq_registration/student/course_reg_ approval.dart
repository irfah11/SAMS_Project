// ignore: file_names
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sams/Controller/Manage_Coq_and_Subject_Registration/RegistrationController.dart';
import 'package:sams/Domain/registration_subject.dart';
import 'package:sams/screen/Manage_Menu/student_menu.dart';

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
    // CHECK DUPLICATE BEFORE SAVE
    bool alreadyRegistered = await _controller.isSubjectAlreadyRegistered(
      currentStudentId,
      _selectedSubjectId!,
    );

    if (alreadyRegistered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This subject is already registered or waiting for approval.',
          ),
        ),
      );
      return;
    }

    String uniqueRegId = '${currentStudentId}_${_selectedSubjectId!}';

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
      drawer: const StudentDrawer(),

      // SAME AS SCREENSHOT: no back button, SAMS left, menu right
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
            // STUDENT INFO BOX
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

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('course_subjects')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const LinearProgressIndicator();
                }

                _allFacultyCourses = snapshot.data!.docs;

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
                    _buildDropdownRow(
                      "Course",
                      DropdownButton<String>(
                        isExpanded: true,
                        isDense: true,
                        value: _selectedSubjectId,
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.black,
                          size: 28,
                        ),
                        hint: const Text(
                          "Value",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
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
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
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
                                  orElse: () => <String, dynamic>{},
                                );
                          });
                        },
                      ),
                    ),

                    _buildDropdownRow(
                      "Section",
                      DropdownButton<String>(
                        isExpanded: true,
                        isDense: true,
                        value: _selectedSection,
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.black,
                          size: 28,
                        ),
                        hint: const Text(
                          "Value",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        items: availableSections.map((sec) {
                          return DropdownMenuItem<String>(
                            value: sec,
                            child: Text(
                              sec,
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedSection = val);
                        },
                      ),
                    ),

                    _buildDropdownRow(
                      "Tutorial/Lab",
                      DropdownButton<String>(
                        isExpanded: true,
                        isDense: true,
                        value: _selectedLab,
                        icon: const Icon(
                          Icons.keyboard_arrow_down,
                          color: Colors.black,
                          size: 28,
                        ),
                        hint: const Text(
                          "Value",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        items: availableLabs.map((lab) {
                          return DropdownMenuItem<String>(
                            value: lab,
                            child: Text(
                              lab,
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedLab = val);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 6),

            // ADD BUTTON SAME POSITION AS IMAGE
            Row(
              children: [
                const SizedBox(width: 85),
                SizedBox(
                  height: 29,
                  child: ElevatedButton(
                    onPressed: _addCourseToApproval,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6DD4E8),
                      foregroundColor: Colors.black,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 11),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: const BorderSide(color: Colors.black26),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    child: const Text("Add", style: TextStyle(fontSize: 10)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // TABLE TOP LABELS
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildHeaderLabel("Course Registration\nfor approval", 120),
                _buildHeaderLabel("Course\nRegistration", 78),
              ],
            ),

            StreamBuilder<List<RegistrationSubject>>(
              stream: _controller.getPendingRegistrations(currentStudentId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(18.0),
                    child: CircularProgressIndicator(),
                  );
                }

                var registeredList = snapshot.data ?? [];

                return Column(
                  children: [
                    _buildRegistrationTable(registeredList),
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

  // ---------------- UI HELPERS ----------------

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

  Widget _buildDropdownRow(String label, Widget dropdownWidget) {
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
      height: 32,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFBDBDBD), width: 0.8),
        color: Colors.white,
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11, color: Colors.blue, height: 1.05),
      ),
    );
  }

  Widget _buildRegistrationTable(List<RegistrationSubject> registeredList) {
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
          if (registeredList.isEmpty)
            _buildEmptyRow()
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
            "No subject registered.",
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ),
        SizedBox(),
        SizedBox(),
        SizedBox(),
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
                onPressed: () => _controller.dropRegisteredCourse(regId),
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

  Widget _buildBottomControls(List<RegistrationSubject> list) {
    int totalCredits = list.fold(0, (sum, item) => sum + item.creditHour);

    return Table(
      border: TableBorder.all(color: const Color(0xFFBDBDBD), width: 0.8),
      columnWidths: const {
        0: FlexColumnWidth(),
        1: FixedColumnWidth(45),
        2: FixedColumnWidth(58),
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

            Padding(
              padding: const EdgeInsets.all(4),
              child: SizedBox(
                width: 55,
                height: 30,
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
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  child: const FittedBox(
                    child: Text(
                      "notify",
                      maxLines: 1,
                      style: TextStyle(fontSize: 10),
                    ),
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
