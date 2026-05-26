import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rent_home/ui/screens_common/auth/emergency_number/emergency_number_screen.dart';
import '../auth_controller.dart';

class GovernmentIdScreen extends StatefulWidget {
  const GovernmentIdScreen({super.key});

  @override
  _GovernmentIdScreenState createState() => _GovernmentIdScreenState();
}

class _GovernmentIdScreenState extends State<GovernmentIdScreen> {
  final AuthController authController = Get.find<AuthController>();
  final _formKey = GlobalKey<FormState>();
  final idNumberController = TextEditingController();
  XFile? _idImage;
  String? selectedIdType;

  // Regex patterns for different ID types
  final Map<String, RegExp> _idPatterns = {
    'Aadhaar Card': RegExp(r'^\d{12}$'), // 12 digits
    'PAN Card':
        RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$'), // 5 letters + 4 digits + 1 letter
    'Driving License': RegExp(
        r'^(([A-Z]{2}[0-9]{2})( )|([A-Z]{2}-[0-9]{2}))((19|20)[0-9][0-9])[0-9]{7}$'), // Format: XX00 00000000
  };

  // Helper method to validate ID number based on selected type
  String? _validateIdNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your government ID number';
    }

    if (selectedIdType == null) {
      return 'Please select an ID type first';
    }

    final pattern = _idPatterns[selectedIdType];
    if (pattern != null && !pattern.hasMatch(value)) {
      switch (selectedIdType) {
        case 'Aadhaar Card':
          return 'Please enter a valid 12-digit Aadhaar number';
        case 'PAN Card':
          return 'Please enter a valid PAN number (ABCDE1234F format)';
        case 'Driving License':
          return 'Please enter a valid Driving License number';
        default:
          return 'Invalid ID number format';
      }
    }
    return null;
  }

  Future<void> _pickIdImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _idImage = image);
    }
  }

  void _handleNext() {
    if (_formKey.currentState!.validate() && _idImage != null) {
      authController.updateGovernmentId(
        docType: selectedIdType!,
        docNumber: idNumberController.text,
        idImage: File(_idImage!.path),
      );
      print(authController.signupData);
      Get.to(() => const EmergencyNumberScreen());
    } else if (_idImage == null) {
      Get.snackbar(
        'Error',
        'Please select a government ID image',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final w = size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(5, (index) {
                        return Container(
                          height: 6,
                          width: (w - 48) / 5 - 10,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: index <= 1
                                ? theme.primaryColor
                                : Colors.grey[350],
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        color: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Upload Government ID",
                      style: TextStyle(color: theme.primaryColor, fontSize: 25),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: _pickIdImage,
                  child: Container(
                    height: 150,
                    width: w * 0.7,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.grey[300],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: _idImage == null
                          ? const Icon(Icons.picture_as_pdf, color: Colors.grey)
                          : Image.file(
                              File(_idImage!.path),
                              fit: BoxFit.cover,
                              width: w * 0.7,
                              height: 150,
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                GestureDetector(
                  onTap: _pickIdImage,
                  child: Text(
                    "Upload your Government ID",
                    style: TextStyle(color: theme.primaryColor),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedIdType,
                  decoration: InputDecoration(
                    hintText: "Select ID Type",
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 18, horizontal: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: <String>['Aadhaar Card', 'PAN Card', 'Driving License']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedIdType = newValue!;
                      // Clear the ID number when type changes
                      idNumberController.clear();
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Please select an ID type' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: idNumberController,
                  decoration: InputDecoration(
                    hintText: "Government ID Number",
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 18, horizontal: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: _validateIdNumber,
                  // Convert to uppercase for PAN Card
                  onChanged: (value) {
                    if (selectedIdType == 'PAN Card') {
                      idNumberController.value = TextEditingValue(
                        text: value.toUpperCase(),
                        selection: idNumberController.selection,
                      );
                    }
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(
                      "Next",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
