import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sams/Controller/manage_coq_activity/subject_controller.dart';
import 'package:sams/screen/Manage_subject_coQ_activity/Lecturer/view_submission.dart';
import 'package:sams/Domain/subject.dart';
import 'package:firebase_core/firebase_core.dart';

final SubjectController _subjectController =
    SubjectController(); // Ini subject_controller

class LecturerSubjectPage extends StatefulWidget {
  final String subjectId;
  final String subjectCode;
  final String subjectName;

  const LecturerSubjectPage({
    super.key,
    required this.subjectId,
    required this.subjectCode,
    required this.subjectName,
  });

  @override
  State<LecturerSubjectPage> createState() => _LecturerSubjectPageState();
}

class _LecturerSubjectPageState extends State<LecturerSubjectPage> {
  void _showCreateDialog(String category) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return SAMSCreateDialog(
          category: category,
          onSave: (title, description, optionalText) async {
            await _subjectController.addContent(
              SubjectContent(
                id: '',
                subjectId: widget.subjectId,
                title: title.isNotEmpty ? title : 'Untitled',
                description: description,
                type: category,
                duration: category == 'Quiz'
                    ? (description.isNotEmpty ? description : '30 minute')
                    : null,
                link: optionalText,
                createdAt: DateTime.now(),
              ),
            );

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Successfully created new $category')),
              );
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF446BE6), // SAMS Blue
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'SAMS',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          size: 20,
                          color: Colors.black87,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Notes',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ],
                  ),
                  _buildSubActionButton(
                    label: '+ New Notes',
                    onPressed: () => _showCreateDialog('Note'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              //NOTE SECTION
              SizedBox(
                height: 140,
                child: StreamBuilder<List<SubjectContent>>(
                  stream: _subjectController.getNotes(widget.subjectId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final notes = snapshot.data!;

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: notes.length,
                      itemBuilder: (context, index) {
                        return _buildNotesCard(notes[index].title);
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Assignment',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  Row(
                    children: [
                      _buildHeaderWhiteButton(
                        label: 'View Submission',
                        onPressed: () {
                          // Navigasi ke halaman ViewSubmissionPage
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ViewSubmissionPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildSubActionButton(
                        label: '+ New Assignment',
                        onPressed: () => _showCreateDialog('Assignment'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              //ASSIGNMENT SECTION
              SizedBox(
                height: 140,
                child: StreamBuilder<List<SubjectContent>>(
                  stream: _subjectController.getAssignments(widget.subjectId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(
                        child: Text('No assignments available'),
                      );
                    }

                    final assignments = snapshot.data!;

                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: assignments.length,
                      itemBuilder: (context, index) {
                        return _buildAssignmentCard(assignments[index].title);
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Quizzes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  Row(
                    children: [
                      _buildHeaderWhiteButton(
                        label: 'View Submission',
                        onPressed: () {
                          // Navigasi ke halaman ViewSubmissionPage
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ViewSubmissionPage(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildSubActionButton(
                        label: '+ New Quiz',
                        onPressed: () => _showCreateDialog('Quiz'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // QUIZ SECTION
              StreamBuilder<List<SubjectContent>>(
                stream: _subjectController.getQuizzes(widget.subjectId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No quizzes available'));
                  }

                  final quizzes = snapshot.data!;

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: quizzes.length,
                    itemBuilder: (context, index) {
                      final quiz = quizzes[index];

                      return _buildQuizItemRow(
                        title: quiz.title,
                        duration: quiz.duration ?? '30 minute',
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubActionButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE5E7EB),
        foregroundColor: Colors.black87,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildHeaderWhiteButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        backgroundColor: Colors.white,
        side: const BorderSide(color: Color(0xFFD1D5DB)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildNotesCard(String title) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDE68A),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF78350F),
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: SizedBox(
              width: double.infinity,
              height: 28,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.7),
                  foregroundColor: Colors.black87,
                  side: BorderSide(color: Colors.black.withOpacity(0.12)),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: () {},
                child: const Text(
                  'Edit',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(String title) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFBFDBFE),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E3A8A),
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: SizedBox(
              width: double.infinity,
              height: 28,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.7),
                  foregroundColor: Colors.black87,
                  side: BorderSide(color: Colors.black.withOpacity(0.12)),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: () {},
                child: const Text(
                  'Edit',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizItemRow({required String title, required String duration}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFD1FAE5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFF10B981)),
            ),
            child: Text(
              title.toUpperCase(),
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF047857),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF065F46),
                  ),
                ),
                Text(
                  'Duration\n$duration',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF047857),
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 50,
            height: 28,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFF047857).withOpacity(0.1),
                foregroundColor: const Color(0xFF047857),
                side: const BorderSide(color: Color(0xFF059669)),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: () {},
              child: const Text(
                'Edit',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SAMSCreateDialog extends StatefulWidget {
  final String category;
  final Function(String title, String description, String optionalText) onSave;

  const SAMSCreateDialog({
    super.key,
    required this.category,
    required this.onSave,
  });

  @override
  State<SAMSCreateDialog> createState() => _SAMSCreateDialogState();
}

class _SAMSCreateDialogState extends State<SAMSCreateDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _optionalController = TextEditingController();
  bool _isFileUploaded = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _optionalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String actionLabel = widget.category == 'Quiz'
        ? 'Quiz'
        : (widget.category == 'Assignment' ? 'Assignment' : 'Note');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      elevation: 10,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
        ),
        width: MediaQuery.of(context).size.width * 0.9,

        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),

        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'New $actionLabel',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111827),
                    ),
                  ),
                  _buildPillEditButton(),
                ],
              ),
              const SizedBox(height: 16),

              const Text(
                'Title',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  hintText: 'Enter title...',
                ),
              ),
              const SizedBox(height: 16),

              Text(
                widget.category == 'Quiz'
                    ? 'Duration / Guidelines'
                    : 'Description',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _descriptionController,
                maxLines: widget.category == 'Quiz' ? 1 : 3,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  hintText: widget.category == 'Quiz'
                      ? 'e.g. 30 minute'
                      : 'Enter description...',
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Upload file',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.insert_drive_file_outlined,
                          color: Colors.grey[500],
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.picture_as_pdf_outlined,
                          color: Colors.red[400],
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.description_outlined,
                          color: Colors.blue[400],
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Icon(
                      _isFileUploaded
                          ? Icons.check_circle
                          : Icons.upload_outlined,
                      color: _isFileUploaded ? Colors.green : Colors.grey[400],
                      size: 28,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _isFileUploaded = true;
                        });
                      },
                      child: Text(
                        _isFileUploaded ? 'File Uploaded!' : '+ Upload file',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Optional (link, YouTube)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 4),
              TextField(
                controller: _optionalController,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                  ),
                  hintText: 'https://...',
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 90,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 90,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      onPressed: () {
                        widget.onSave(
                          _titleController.text,
                          _descriptionController.text,
                          _optionalController.text,
                        );
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillEditButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'Edit',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}
