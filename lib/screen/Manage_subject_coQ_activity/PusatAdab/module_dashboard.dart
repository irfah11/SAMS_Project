import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:sams/Controller/manage_coq_activity/module_controller.dart';
import 'package:sams/screen/Manage_subject_coQ_activity/PusatAdab/coq_page.dart';
import 'package:sams/Domain/module_coq.dart';

class ModuleDashboard extends StatelessWidget {
  const ModuleDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SAMS Dashboard")),

      body: Padding(
        padding: const EdgeInsets.all(16),

        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.5,

          children: [
            dashboardCard(
              context,
              "CoQ Physics",
              "CQ001",
              "Lecture Hall A",
              "Dr Awanis",
              30,
            ),

            dashboardCard(
              context,
              "CoQ Math",
              "CQ002",
              "Room B",
              "Dr Azman",
              25,
            ),

            dashboardCard(context, "CoQ IT", "CQ003", "Lab 1", "Dr Farah", 40),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // DASHBOARD CARD
  // =====================================================
  Widget dashboardCard(
    BuildContext context,
    String title,
    String coqId,
    String location,
    String lecturer,
    int quota,
  ) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),

          builder: (context) {
            return Padding(
              padding: const EdgeInsets.all(20),

              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text("CoQ ID: $coqId"),
                  Text("Quota: $quota"),
                  Text("Location: $location"),
                  Text("Lecturer: $lecturer"),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,

                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text("Close"),
                      ),

                      const SizedBox(width: 10),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                        ),

                        onPressed: () {
                          Navigator.pop(context);

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CoQPage(
                                coqId: coqId,
                                activityName: title,
                                location: location,
                                lecturerName: lecturer,
                                bookingQuota: quota,
                              ),
                            ),
                          );
                        },

                        child: const Text("Open Session"),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },

      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),

        child: Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
