import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:rent_home/ui/screens_common/auth/emergency_number/emergency_number_screen.dart';
import 'package:rent_home/ui/screens_common/auth/referral_code_screen.dart';

import '../auth_controller.dart';

class HouseAgreementScreen extends StatefulWidget {
  const HouseAgreementScreen({super.key});

  @override
  _HouseAgreementScreenState createState() => _HouseAgreementScreenState();
}

class _HouseAgreementScreenState extends State<HouseAgreementScreen> {
  final AuthController authController = Get.find<AuthController>();
  String? _agreementFilePath;

  Future<void> _pickAgreementFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() => _agreementFilePath = result.files.single.path);
    }
  }

  void _handleNext() {
    if (_agreementFilePath != null) {
      authController.updateHouseAgreement(File(_agreementFilePath!));
      print(authController.signupData);
      Get.to(() => const ReferralCodeScreen());
    } else {
      Get.snackbar(
        'Error',
        'Please select a house agreement PDF',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
      );
    }
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

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
                            color: index <= 3
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
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        color: theme.primaryColor,
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      "Upload House Agreement",
                      style: TextStyle(color: theme.primaryColor, fontSize: 25),
                    ),
                  ],
                ),
                SizedBox(height: 50),

                // Centered PDF Picker for House Agreement
                GestureDetector(
                  onTap: _pickAgreementFile,
                  child: Container(
                    height: 150,
                    width: w * 0.7,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      color: Colors.grey[300],
                    ),
                    child: Center(
                      child: _agreementFilePath == null
                          ? const Icon(Icons.picture_as_pdf,
                              color: Colors.grey) // Placeholder icon
                          : Text(
                              'Selected: ${_agreementFilePath!.split('/').last}', // Show the file name
                              style: TextStyle(color: Colors.black),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 5),
                GestureDetector(
                  onTap: _pickAgreementFile,
                  child: Container(
                    child: Text(
                      "Upload your House Agreement PDF",
                      style: TextStyle(color: theme.primaryColor),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Upload Button
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
