import 'dart:io'; // <-- REQUIRED for 'File'
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart'; // <-- REQUIRED for 'FilePicker' and 'PlatformFile'
import 'package:firebase_storage/firebase_storage.dart'; // <-- REQUIRED for 'FirebaseStorage'

//MODULE BOOKED PAGE
class ModuleBookedPage extends StatefulWidget {
  const ModuleBookedPage({super.key});

  @override
  State<ModuleBookedPage> createState() => _ModuleBookedPageState();
}

class _ModuleBookedPageState extends State<ModuleBookedPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SAMS")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('modules').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                "Modules Booked",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text("Module")),
                      DataColumn(label: Text("Campus")),
                      DataColumn(label: Text("Venue")),
                      DataColumn(label: Text("Class Date")),
                      DataColumn(label: Text("Attendance")),
                      DataColumn(label: Text("Credit Claim")),
                    ],
                    rows: snapshot.data!.docs.map((doc) {
                      return DataRow(
                        cells: [
                          DataCell(Text(doc['moduleName'] ?? '')),
                          DataCell(Text(doc['campus'] ?? '')),
                          DataCell(Text(doc['venue'] ?? '')),
                          DataCell(Text(doc['classDate'] ?? '')),
                          DataCell(Text(doc['attendance'] ?? '')),
                          DataCell(
                            ElevatedButton(
                              onPressed: () {
                                showClaimDialog(doc.id);
                              },
                              child: const Text("Claim"),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              ElevatedButton(onPressed: () {}, child: const Text("Print")),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  //CREDIT CLAIM POP-UP
  Future<void> showClaimDialog(String moduleId) async {
    PlatformFile? selectedFile;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Credit Claim"),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        FilePickerResult? result = await FilePicker.platform
                            .pickFiles();

                        if (result != null) {
                          setDialogState(() {
                            selectedFile = result.files.first;
                          });
                        }
                      },
                      child: const Text("Upload File"),
                    ),
                    const SizedBox(height: 15),
                    Text(selectedFile?.name ?? "No file selected"),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedFile == null || selectedFile!.path == null) return;

                File file = File(selectedFile!.path!);
                String fileName = selectedFile!.name;

                // 1. Upload file to Firebase Storage
                TaskSnapshot storageSnapshot = await FirebaseStorage.instance
                    .ref()
                    .child("credit_claims")
                    .child(fileName)
                    .putFile(file);

                String url = await storageSnapshot.ref.getDownloadURL();

                // 2. Add metadata to Firestore
                await FirebaseFirestore.instance
                    .collection('module_claims')
                    .add({
                      'moduleId': moduleId,
                      'fileUrl': url,
                      'fileName': fileName,
                      'status': 'Pending',
                      'submittedAt': Timestamp.now(),
                    });

                // 3. Asynchronous Guard: Verify widget is still active before context manipulation
                if (!mounted) return;

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Claim Submitted")),
                );
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }
}
