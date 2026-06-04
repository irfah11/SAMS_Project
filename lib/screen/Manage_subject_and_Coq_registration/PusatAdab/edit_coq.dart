import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sams/Controller/Manage_Coq_and_Subject_Registration/RegistrationController.dart';
import 'package:sams/Domain/module_coq.dart';
import 'list_coq.dart';

class EditCoQ extends StatefulWidget {
  final ModuleCoQ coq;
  const EditCoQ({super.key, required this.coq});

  @override
  State<EditCoQ> createState() => _EditCoQState();
}

class _EditCoQState extends State<EditCoQ> {
  late TextEditingController _idController;
  late TextEditingController _nameController;
  late TextEditingController _quotaController;
  late TextEditingController _locationController;

  String? _selectedLecturerName;
  final RegistrationController _controller = RegistrationController();

  @override
  void initState() {
    super.initState();
    _idController = TextEditingController(text: widget.coq.coqId);
    _nameController = TextEditingController(text: widget.coq.activityName);
    _quotaController = TextEditingController(
      text: widget.coq.bookingQuota.toString(),
    );
    _locationController = TextEditingController(text: widget.coq.location);
    _selectedLecturerName = widget.coq.lecturerName;
  }

  void _updateForm() async {
    ModuleCoQ updatedCoQ = ModuleCoQ(
      coqId: _idController.text,
      activityName: _nameController.text,
      bookingQuota: int.tryParse(_quotaController.text) ?? 0,
      location: _locationController.text,
      lecturerName: _selectedLecturerName ?? 'No Advisor',
    );

    try {
      await _controller.updateCoQ(updatedCoQ);
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
        title: const Text('Edit Co-Q Activity'),
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
              _buildInputField('Co-Q ID', _idController, readOnly: true),
              _buildInputField('Activity Name', _nameController),
              _buildInputField(
                'Booking Quota',
                _quotaController,
                isNumber: true,
              ),
              _buildInputField('Location', _locationController),

              // Dropdown Advisor
              Padding(
                padding: const EdgeInsets.only(bottom: 15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Advisor Name',
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
                        return DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 15,
                            ),
                          ),
                          value: _selectedLecturerName,
                          items: snapshot.data!.docs.map((doc) {
                            var data = doc.data() as Map<String, dynamic>;
                            String name = data['full_name'] ?? 'No Name';
                            return DropdownMenuItem(
                              value: name,
                              child: Text(name),
                            );
                          }).toList(),
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
                  onPressed: _updateForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF333333),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Save Changes',
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
    bool readOnly = false,
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
            readOnly: readOnly,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
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
              'Update Successful',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Activity modified successfully.'),
          ],
        ),
      ),
    );
  }
}
