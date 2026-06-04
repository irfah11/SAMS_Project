import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sams/Controller/Manage_Coq_and_Subject_Registration/RegistrationController.dart';
import 'package:sams/Domain/module_coq.dart';
import 'list_coq.dart';

class CreateModuleCoQ extends StatefulWidget {
  const CreateModuleCoQ({super.key});

  @override
  State<CreateModuleCoQ> createState() => _CreateModuleCoQState();
}

class _CreateModuleCoQState extends State<CreateModuleCoQ> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _quotaController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String? _selectedLecturerName;
  final RegistrationController _controller = RegistrationController();

  void _submitForm() async {
    if (_selectedLecturerName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sila pilih pensyarah penasihat!')),
      );
      return;
    }

    ModuleCoQ newCoQ = ModuleCoQ(
      coqId: _idController.text,
      activityName: _nameController.text,
      bookingQuota: int.tryParse(_quotaController.text) ?? 0,
      location: _locationController.text,
      lecturerName: _selectedLecturerName!,
    );

    try {
      await _controller.createCoQ(newCoQ);
      if (mounted) {
        _showSuccessDialog(context);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pop(context);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ListCoQ()),
            );
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ralat: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE67E33),
        title: const Text(
          'Register Co-Q',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.sports_basketball_outlined, size: 70),
                  const SizedBox(width: 15),
                  const Text(
                    'Register\nCo-Q Activity',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              _buildInputField('Co-Q ID', _idController),
              _buildInputField('Activity Name', _nameController),
              _buildInputField(
                'Booking Quota',
                _quotaController,
                isNumber: true,
              ),
              _buildInputField('Location', _locationController),

              // Dropdown Lecturer
              Padding(
                padding: const EdgeInsets.only(bottom: 15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Advisor / Lecturer Name',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 5),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('lecturer')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData)
                          return const LinearProgressIndicator();
                        List<DropdownMenuItem<String>> lecturerItems = snapshot
                            .data!
                            .docs
                            .map((doc) {
                              var data = doc.data() as Map<String, dynamic>;
                              String fullName = data['full_name'] ?? 'No Name';
                              return DropdownMenuItem(
                                value: fullName,
                                child: Text(fullName),
                              );
                            })
                            .toList();

                        return DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 15,
                            ),
                          ),
                          hint: const Text("Select Advisor"),
                          value: _selectedLecturerName,
                          items: lecturerItems,
                          onChanged: (value) =>
                              setState(() => _selectedLecturerName = value),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF333333),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Submit',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller, {
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 5),
          TextField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              hintText: 'Value',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 60),
            SizedBox(height: 20),
            Text(
              'Registration Successful',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Co-Q Activity has been added successfully.'),
          ],
        ),
      ),
    );
  }
}
