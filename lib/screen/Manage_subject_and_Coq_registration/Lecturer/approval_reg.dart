import 'package:flutter/material.dart';

class ApprovalReg extends StatelessWidget {
  const ApprovalReg({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4A69FF), // Biru Lecturer
        elevation: 0,
        title: const Text(
          'SAMS',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row dengan Ikon Buku
              Row(
                children: [
                  const Icon(Icons.menu_book_outlined, size: 80),
                  const SizedBox(width: 20),
                  const Expanded(
                    child: Text(
                      'Approval\nCourse\nRegistration',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Jadual (DataTable)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DataTable(
                  columnSpacing: 12,
                  horizontalMargin: 10,
                  headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                  columns: const [
                    DataColumn(label: Text('no', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Subject', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: [
                    _buildDataRow('1', 'CB23041', 'Nik Nor Irfah...', 'Software Eng...', true),
                    _buildDataRow('2', 'CB23040', 'Wardah Wafin', 'Software Eng...', false),
                    _buildDataRow('3', 'CD23011', 'Naim Aqasha', 'Software Eng...', false),
                    _buildDataRow('4', 'CS23048', 'Afiq Aiman', 'Software Eng...', true),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  DataRow _buildDataRow(String no, String id, String name, String subject, bool needsApprove) {
    return DataRow(cells: [
      DataCell(Text(no)),
      DataCell(Text(id)),
      DataCell(Text(name, overflow: TextOverflow.ellipsis)),
      DataCell(Text(subject, overflow: TextOverflow.ellipsis)),
      DataCell(
        needsApprove
            ? ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF81D4FA), // Warna biru butang
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: const Text('Approve\nNow', textAlign: TextAlign.center),
              )
            : const Text('Approved', style: TextStyle(color: Colors.grey, fontSize: 12)),
      ),
    ]);
  }
}