import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sams/Controller/Manage_Coq_and_Subject_Registration/RegistrationController.dart';
import 'package:sams/screen/Manage_Menu/student_menu.dart';

class BookedCoqScreen extends StatefulWidget {
  const BookedCoqScreen({super.key});

  @override
  State<BookedCoqScreen> createState() => _BookedCoqScreenState();
}

class _BookedCoqScreenState extends State<BookedCoqScreen> {
  final RegistrationController _controller = RegistrationController();

  final String currentStudentId = "CB23041";

  int _toInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? defaultValue;
  }

  String _toText(dynamic value) {
    if (value == null) return '-';

    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }

    return value.toString();
  }

  String _toTimeText(dynamic value) {
    if (value == null) return '-';

    if (value is Timestamp) {
      final date = value.toDate();
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }

    return value.toString();
  }

  // ignore: unused_element
  dynamic _getField(Map<String, dynamic> data, List<String> keys) {
    for (final key in keys) {
      if (data.containsKey(key) && data[key] != null) {
        return data[key];
      }
    }
    return null;
  }

  Future<void> _handleBook({
    required String moduleDocId,
    required Map<String, dynamic> moduleData,
  }) async {
    try {
      await _controller.bookCoQ(
        studentId: currentStudentId,
        moduleDocId: moduleDocId,
        moduleData: moduleData,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Co-Q registration successful!")),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))),
      );
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
        padding: const EdgeInsets.fromLTRB(22, 20, 16, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.workspace_premium_outlined, size: 58),
                SizedBox(width: 14),
                Text(
                  'MY Co-Q',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Text(
              'Booking Slot',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),

            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              stream: _controller.getCoQBookingSlots(),
              builder: (context, moduleSnapshot) {
                if (moduleSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (!moduleSnapshot.hasData ||
                    moduleSnapshot.data!.docs.isEmpty) {
                  return const Text("No Co-Q slot available.");
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: _controller.getStudentCoQRegistrations(
                    currentStudentId,
                  ),
                  builder: (context, regSnapshot) {
                    final regDocs = regSnapshot.data?.docs ?? [];

                    final Set<String> registeredCoqIds = regDocs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return _toText(data['coq_id']);
                    }).toSet();

                    final modules = moduleSnapshot.data!.docs;

                    return Table(
                      border: TableBorder.all(
                        color: Colors.grey.shade400,
                        width: 0.5,
                      ),
                      columnWidths: const {
                        0: FixedColumnWidth(28),
                        1: FlexColumnWidth(1.8),
                        2: FlexColumnWidth(1.5),
                        3: FlexColumnWidth(1.5),
                        4: FlexColumnWidth(1.4),
                      },
                      children: [
                        _buildTableHeader(),

                        ...List.generate(modules.length, (index) {
                          final doc = modules[index];
                          final data = doc.data() as Map<String, dynamic>;

                          final String coqId = _toText(data['coq_id']) == '-'
                              ? doc.id
                              : _toText(data['coq_id']);

                          final String subject = _toText(data['activity_name']);

                          final String date = _toText(
                            _getField(data, [
                              'date',
                              'activity_date',
                              'booking_date',
                              'module_date',
                            ]),
                          );

                          final String time = _toTimeText(
                            _getField(data, [
                              'time',
                              'activity_time',
                              'booking_time',
                              'module_time',
                            ]),
                          );

                          final String location = _toText(
                            _getField(data, ['location', 'place', 'venue']),
                          );

                          final int booked = _toInt(
                            data['booked'],
                            defaultValue: 0,
                          );

                          final int quota = _toInt(
                            data['booking_quota'],
                            defaultValue: 50,
                          );

                          final bool isFull = booked >= quota;
                          final bool alreadyRegistered = registeredCoqIds
                              .contains(coqId);

                          return _buildTableRow(
                            no: (index + 1).toString(),
                            subject: subject,
                            dateTime: '$date\n$time',
                            location: location,
                            bookingText: '$booked/$quota',
                            isFull: isFull,
                            alreadyRegistered: alreadyRegistered,
                            onBook: () {
                              _handleBook(
                                moduleDocId: doc.id,
                                moduleData: data,
                              );
                            },
                          );
                        }),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

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

  TableRow _buildTableRow({
    required String no,
    required String subject,
    required String dateTime,
    required String location,
    required String bookingText,
    required bool isFull,
    required bool alreadyRegistered,
    required VoidCallback onBook,
  }) {
    return TableRow(
      children: [
        _CellText(no),
        _CellText(subject),
        _CellText(dateTime),
        _CellText(location),

        Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(bookingText, style: const TextStyle(fontSize: 10)),

              const SizedBox(height: 5),

              if (alreadyRegistered)
                const Text(
                  "Registered",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 9, color: Colors.green),
                )
              else if (isFull)
                const SizedBox(height: 28)
              else
                SizedBox(
                  width: 43,
                  height: 28,
                  child: ElevatedButton(
                    onPressed: onBook,
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
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: const Text("Book", style: TextStyle(fontSize: 9)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CellText extends StatelessWidget {
  final String text;
  final bool isHeader;

  const _CellText(this.text, {this.isHeader = false});

  @override
  Widget build(BuildContext context) {
    return TableCell(
      verticalAlignment: TableCellVerticalAlignment.middle,
      child: SizedBox(
        height: 80,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isHeader ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
