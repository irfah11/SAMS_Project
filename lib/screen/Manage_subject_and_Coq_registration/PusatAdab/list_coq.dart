import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sams/Domain/module_coq.dart';
import 'create_module_coq.dart';
import 'edit_coq.dart';
import 'delete_coq.dart';
import 'package:sams/screen/Manage_Menu/pusat_adab_menu.dart';

class ListCoQ extends StatelessWidget {
  const ListCoQ({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const PusatAdabMenu(),

      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFA96366),
        elevation: 0,
        toolbarHeight: 64,
        titleSpacing: 24,
        title: const Text(
          'SAMS',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 28,
            letterSpacing: 2,
            shadows: [
              Shadow(
                color: Colors.black38,
                offset: Offset(2, 2),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        actions: [
          Builder(
            builder: (context) {
              return IconButton(
                icon: const Icon(Icons.menu, color: Colors.black, size: 34),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('module_coq').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Column(
              children: [
                _buildAddButton(context),
                const Expanded(
                  child: Center(
                    child: Text(
                      'No Co-Q activities registered yet.',
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                ),
              ],
            );
          }

          final docs = snapshot.data!.docs;

          return Column(
            children: [
              _buildAddButton(context),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(36, 16, 36, 30),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final Color cardColor = index % 2 == 0
                        ? const Color(0xFFD46BEF)
                        : const Color(0xFFE34DA7);

                    return _buildCoQCard(
                      context: context,
                      docId: doc.id,
                      data: data,
                      color: cardColor,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, right: 22),
      child: Align(
        alignment: Alignment.centerRight,
        child: SizedBox(
          width: 55,
          height: 30,
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateModuleCoQ(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3F63D7),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
                side: const BorderSide(color: Colors.black54, width: 1),
              ),
            ),
            child: const Text(
              '+ Add',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCoQCard({
    required BuildContext context,
    required String docId,
    required Map<String, dynamic> data,
    required Color color,
  }) {
    final String activityName = data['activity_name'] ?? 'No Name';
    final String coqId = data['coq_id'] ?? docId;
    final int quota = _toInt(data['booking_quota']);
    final String location = data['location'] ?? 'Not Set';
    final String lecturer = data['lecturer_name'] ?? 'No Lecturer';

    final dynamic rawDate = data['date'] ?? data['time'];
    final dynamic rawTime = data['time'];

    final String dateText = _formatDate(rawDate);
    final String timeText = _formatTime(rawTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      padding: const EdgeInsets.fromLTRB(24, 22, 16, 24),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.13),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            activityName,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 14),

          _buildInfoRow('Date', dateText),
          _buildInfoRow('Time', timeText),
          _buildInfoRow('Location', location),
          _buildInfoRow('Capacity', quota.toString()),
          _buildInfoRow('Lecturer', lecturer),

          const SizedBox(height: 28),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildActionButton(
                label: 'Edit',
                color: const Color(0xFF4CAF50),
                onTap: () {
                  final ModuleCoQ currentCoQ = ModuleCoQ(
                    coqId: coqId,
                    activityName: activityName,
                    bookingQuota: quota,
                    location: location,
                    lecturerName: lecturer,
                    date: data['date'] is Timestamp ? data['date'] : null,
                    time: data['time'] is Timestamp ? data['time'] : null,
                    day: data['day'] ?? '',
                    booked: _toInt(data['booked']),
                    status: data['status'] ?? 'Available',
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditCoQ(coq: currentCoQ),
                    ),
                  );
                },
              ),

              const SizedBox(width: 14),

              _buildActionButton(
                label: 'Delete',
                color: const Color(0xFFE53935),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          DeleteCoQ(coqId: coqId, activityName: activityName),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 74,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          const Text(
            ': ',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black,
              fontWeight: FontWeight.w400,
            ),
          ),

          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 42,
      height: 31,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: const BorderSide(color: Colors.black54, width: 0.8),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse((value ?? '0').toString()) ?? 0;
  }

  String _formatDate(dynamic value) {
    if (value == null) return '-';

    if (value is Timestamp) {
      final DateTime date = value.toDate();

      final String day = date.day.toString();
      final String month = date.month.toString();
      final String year = date.year.toString();

      return '$day / $month / $year';
    }

    return value.toString();
  }

  String _formatTime(dynamic value) {
    if (value == null) return '-';

    if (value is Timestamp) {
      final DateTime date = value.toDate();

      int hour = date.hour;
      final int minute = date.minute;

      final String period = hour >= 12 ? 'pm' : 'am';

      if (hour == 0) {
        hour = 12;
      } else if (hour > 12) {
        hour = hour - 12;
      }

      final String minuteText = minute.toString().padLeft(2, '0');

      return '$hour.$minuteText $period';
    }

    return value.toString();
  }
}
