import 'package:rent_home/constants.dart';
import 'dart:io';
import '../../../../utils/csc_picker/csc_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_holo_date_picker/flutter_holo_date_picker.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:rent_home/controller/common_controller.dart';
import 'package:rent_home/data/models/doc_type_response_model.dart';
import 'package:rent_home/ui/screens_common/auth/create_account_loading_screen.dart';
import '../auth_controller.dart';

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  _InfoScreenState createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  // Controllers
  final AuthController authController = Get.find<AuthController>();
  final CommonController commonController = Get.find<CommonController>();

  // Form keys
  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();
  final _step3FormKey = GlobalKey<FormState>();

  // Text controllers
  final fullNameController = TextEditingController();
  final dobController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final pincodeController = TextEditingController();
  final documentNumberController = TextEditingController();

  // State variables
  int currentStep = 0;
  String selectedGender = '';
  String selectedCountryCode = '+91';
  String selectedCountry = 'India';
  String selectedState = '';
  String selectedCity = '';
  String selectedDocType = '';
  File? selectedDocument;
  String documentFileName = '';

  // Constants
  static const List<String> genders = ['Male', 'Female', 'Other'];
  static const List<String> countryCodes = ['+91'];
  static const int minAge = 18;
  static const int maxFileSizeMB = 5;

  // Validation regex patterns
  static final RegExp _nameRegex = RegExp(r'^[a-zA-Z\s]{2,50}$');
  static final RegExp _pincodeRegex = RegExp(r'^\d{6}$');
  static final RegExp _phoneRegex = RegExp(r'^\d{10}$');

  // Document validation patterns
  static final Map<String, RegExp> _documentPatterns = {
    'aadhaar': RegExp(r'^\d{12}$'),
    'driving_license_1': RegExp(r'^[A-Z]{2}[0-9]{2}[0-9]{4}[0-9]{7}$'),
    'driving_license_2': RegExp(r'^[A-Z]{2}-[0-9]{13}$'),
    'passport': RegExp(r'^[A-Z][0-9]{7}$'),
    'voter_id': RegExp(r'^[A-Z]{3}[0-9]{7}$'),
  };

  @override
  void dispose() {
    fullNameController.dispose();
    dobController.dispose();
    phoneController.dispose();
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    pincodeController.dispose();
    documentNumberController.dispose();
    super.dispose();
  }

  // ==================== VALIDATION METHODS ====================

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name';
    }
    if (!_nameRegex.hasMatch(value.trim())) {
      return 'Name should contain only letters and spaces (2-50 characters)';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter phone number';
    }
    if (!_phoneRegex.hasMatch(value.trim())) {
      return 'Please enter a valid 10-digit phone number';
    }
    return null;
  }

  String? _validatePincode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter pincode';
    }
    if (!_pincodeRegex.hasMatch(value.trim())) {
      return 'Please enter a valid 6-digit pincode';
    }
    return null;
  }

  String? _validateDOB(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please select your date of birth';
    }

    try {
      DateTime dob = DateFormat('dd/MM/yyyy').parseStrict(value.trim());
      DateTime today = DateTime.now();
      int age = today.year - dob.year;

      if (today.month < dob.month ||
          (today.month == dob.month && today.day < dob.day)) {
        age--;
      }

      if (age < minAge) {
        return 'You must be at least $minAge years old';
      }

      if (dob.isAfter(today)) {
        return 'Date of birth cannot be in the future';
      }

      return null;
    } catch (e) {
      return 'Please enter a valid date in dd/MM/yyyy format';
    }
  }

  String? _validateGender(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select your gender';
    }
    return null;
  }

  String? _validateDocumentType(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select document type';
    }
    return null;
  }

  String? _validateDocumentNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter document number';
    }

    if (selectedDocType.isEmpty) {
      return 'Please select document type first';
    }

    String docNumber = value.trim().replaceAll(' ', '').toUpperCase();
    String? docTypeName = _getDocumentTypeName();

    if (docTypeName == null) {
      return 'Invalid document type';
    }

    return _validateDocumentByType(docNumber, docTypeName);
  }

  String? _validateDocumentByType(String docNumber, String docTypeName) {
    switch (docTypeName.toLowerCase()) {
      case 'adhar card':
      case 'aadhar card':
        if (!_documentPatterns['aadhaar']!.hasMatch(docNumber)) {
          return 'Aadhaar number must be exactly 12 digits';
        }
        break;

      case 'driving license':
      case 'driving licence':
        if (!_documentPatterns['driving_license_1']!.hasMatch(docNumber) &&
            !_documentPatterns['driving_license_2']!.hasMatch(docNumber)) {
          return 'Invalid format. Use: DL1420110012345 or HR-0619850034761';
        }
        break;

      case 'passport':
        if (!_documentPatterns['passport']!.hasMatch(docNumber)) {
          return 'Passport: 1 letter + 7 digits (e.g., A1234567)';
        }
        break;

      case 'voter card':
      case 'voter id':
      case 'epic':
        if (!_documentPatterns['voter_id']!.hasMatch(docNumber)) {
          return 'Voter ID: 3 letters + 7 digits (e.g., ABC1234567)';
        }
        break;

      default:
        if (docNumber.length < 6) {
          return 'Document number must be at least 6 characters';
        }
        if (docNumber.length > 20) {
          return 'Document number cannot exceed 20 characters';
        }
    }

    return null;
  }

  String? _validateDocument() {
    if (selectedDocument == null) {
      return 'Please upload a document';
    }

    int fileSizeInBytes = selectedDocument!.lengthSync();
    int fileSizeInMB = fileSizeInBytes ~/ (1024 * 1024);

    if (fileSizeInMB > maxFileSizeMB) {
      return 'File size must not exceed ${maxFileSizeMB}MB';
    }

    return null;
  }

  bool _validateStep2() {
    if (!_step2FormKey.currentState!.validate()) {
      return false;
    }

    if (selectedState.isEmpty) {
      _showErrorSnackbar('Please select a state');
      return false;
    }

    if (selectedCity.isEmpty) {
      _showErrorSnackbar('Please select a city');
      return false;
    }

    return true;
  }

  // ==================== HELPER METHODS ====================

  String? _getDocumentTypeName() {
    if (commonController.docTypes.value == null || selectedDocType.isEmpty) {
      return null;
    }

    try {
      var docType = commonController.docTypes.value!.data.firstWhere(
        (doc) => doc.dId.toString() == selectedDocType,
        orElse: () => DocTypeData(dId: 0, dTitle: ''),
      );
      return docType.dTitle;
    } catch (e) {
      return null;
    }
  }

  int _getDocumentNumberMaxLength() {
    String? docTypeName = _getDocumentTypeName()?.toLowerCase();

    switch (docTypeName) {
      case 'adhar card':
      case 'aadhar card':
        return 12;
      case 'driving license':
      case 'driving licence':
        return 16;
      case 'passport':
        return 8;
      case 'voter card':
      case 'voter id':
      case 'epic':
        return 10;
      default:
        return 20;
    }
  }

  IconData _getFileIcon(String fileName) {
    String extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Iconsax.document;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Iconsax.gallery;
      default:
        return Iconsax.document_text;
    }
  }

  String _getFileSize(File file) {
    int bytes = file.lengthSync();
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    int i = (bytes.bitLength - 1) ~/ 10;
    return '${(bytes / (1 << (i * 10))).toStringAsFixed(1)} ${suffixes[i]}';
  }

  // ==================== UI INTERACTION METHODS ====================

  Future<void> _selectDate(BuildContext context) async {
    DateTime selectedDate = DateTime.now();

    await showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300,
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with title and done button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.separator.resolveFrom(context),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Date',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.of(context).pop(selectedDate),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // The date picker
            Expanded(
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: DateTime.now(),
                minimumDate: DateTime(1900),
                maximumDate: DateTime.now(),
                onDateTimeChanged: (DateTime newDate) {
                  selectedDate = newDate;
                },
              ),
            ),
          ],
        ),
      ),
    ).then((pickedDate) {
      if (pickedDate != null) {
        setState(() {
          dobController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
        });
      }
    });
  }

  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);

        int fileSizeInBytes = file.lengthSync();
        int fileSizeInMB = fileSizeInBytes ~/ (1024 * 1024);

        if (fileSizeInMB > maxFileSizeMB) {
          _showErrorSnackbar('File size must not exceed ${maxFileSizeMB}MB');
          return;
        }

        setState(() {
          selectedDocument = file;
          documentFileName = result.files.single.name;
        });
      }
    } catch (e) {
      _showErrorSnackbar('Error picking document: $e');
    }
  }

  void _handleNext() {
    switch (currentStep) {
      case 0:
        if (_step1FormKey.currentState!.validate()) {
          // Save step 1 data immediately
          authController.signupData.addAll({
            'user_fullName': fullNameController.text.trim(),
            'user_dob': dobController.text.trim(),
            'user_gender': selectedGender,
            'user_pnumber': phoneController.text.trim(),
            'user_countryCode': selectedCountryCode,
          });
          setState(() => currentStep = 1);
        }
        break;
      case 1:
        if (_validateStep2()) {
          // Save step 2 data immediately
          authController.signupData.addAll({
            'user_address': addressController.text.trim(),
            'user_country': selectedCountry,
            'user_city': selectedCity,
            'user_state': selectedState,
            'user_pincode': pincodeController.text.trim(),
          });
          setState(() => currentStep = 2);
        }
        break;
      case 2:
        if (_step3FormKey.currentState!.validate()) {
          String? docError = _validateDocument();
          if (docError != null) {
            _showErrorSnackbar(docError);
            return;
          }
          _saveAllData();
        }
        break;
    }
  }

  Future<void> _saveAllData() async {
    authController.signupData.addAll({
      'user_fullName': fullNameController.text.trim(),
      'user_dob': dobController.text.trim(),
      'user_gender': selectedGender,
      'user_pnumber': phoneController.text.trim(),
      'user_countryCode': selectedCountryCode,
      'user_address': addressController.text.trim(),
      'user_country': selectedCountry,
      'user_city': selectedCity,
      'user_state': selectedState,
      'user_pincode': pincodeController.text.trim(),
      'doc_type': selectedDocType,
      'doc_number': documentNumberController.text.trim().toUpperCase(),
    });

    authController.governmentIdImage.value = selectedDocument;

    final email = authController.signupData['user_email'] ?? '';
    final password = authController.signupData['user_password'] ?? '';
    final confirmPassword =
        authController.signupData['user_confirmPassword'] ?? '';
    final isHost = authController.signupData['user_isHost'] ?? false;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateAccountLoadingScreen(
          email: email,
          password: password,
          confirmPassword: confirmPassword,
          isHost: isHost,
        ),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ==================== BUILD METHODS ====================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(theme),
      body: Column(
        children: [
          _buildProgressIndicator(theme),
          Expanded(
            child: SingleChildScrollView(
              child: _buildStepContent(theme),
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(ThemeData theme) {
    return AppBar(
      elevation: 0,
      backgroundColor: kCream,
      foregroundColor: theme.primaryColor,
      title: Text(
        'Complete Your Profile',
        style: TextStyle(
          color: theme.primaryColor,
          fontWeight: FontWeight.w600,
          fontSize: 20,
        ),
      ),
      leading: IconButton(
        icon: Icon(Iconsax.arrow_left_2, color: theme.primaryColor),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      actions: [
        TextButton(
          onPressed: _skipAll,
          child: Text(
            'Skip',
            style: TextStyle(
              color: kMuted,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  void _skipAll() {
    // Preserve whatever partial data the user already entered
    if (fullNameController.text.isNotEmpty) {
      authController.signupData['user_fullName'] = fullNameController.text.trim();
    }
    if (phoneController.text.isNotEmpty) {
      authController.signupData['user_pnumber'] = phoneController.text.trim();
    }
    if (dobController.text.isNotEmpty) {
      authController.signupData['user_dob'] = dobController.text.trim();
    }
    // Ensure all required signupData keys have at least empty defaults
    authController.signupData.putIfAbsent('user_fullName', () => '');
    authController.signupData.putIfAbsent('user_pnumber', () => '');
    authController.signupData.putIfAbsent('user_dob', () => '');
    authController.signupData.putIfAbsent('user_gender', () => '');
    authController.signupData.putIfAbsent('user_address', () => '');
    authController.signupData.putIfAbsent('user_city', () => '');
    authController.signupData.putIfAbsent('user_state', () => '');
    authController.signupData.putIfAbsent('user_pincode', () => '');
    authController.signupData.putIfAbsent('user_country', () => 'India');
    authController.signupData.putIfAbsent('doc_type', () => '0');
    authController.signupData.putIfAbsent('doc_number', () => '');

    final email = authController.signupData['user_email'] ?? '';
    final password = authController.signupData['user_password'] ?? '';
    final confirmPassword = authController.signupData['user_confirmPassword'] ?? '';
    final isHost = authController.signupData['user_isHost'] ?? false;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateAccountLoadingScreen(
          email: email,
          password: password,
          confirmPassword: confirmPassword,
          isHost: isHost,
          skipMode: true,
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      color: kCream,
      child: Column(
        children: [
          Row(
            children: List.generate(3, (index) {
              final isActive = index <= currentStep;
              final isCompleted = index < currentStep;

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: isActive
                              ? LinearGradient(
                                  colors: [
                                    theme.primaryColor,
                                    theme.primaryColor.withOpacity(0.7),
                                  ],
                                )
                              : null,
                          color: isActive ? null : Colors.grey[300],
                        ),
                      ),
                    ),
                    if (index < 2)
                      Container(
                        width: 8,
                        height: 4,
                        color: Colors.transparent,
                      ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStepLabel('Personal', 0, theme),
              _buildStepLabel('Address', 1, theme),
              _buildStepLabel('Document', 2, theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepLabel(String label, int step, ThemeData theme) {
    final isActive = step == currentStep;
    final isCompleted = step < currentStep;

    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
        color: isActive || isCompleted ? theme.primaryColor : Colors.grey[500],
      ),
    );
  }

  Widget _buildStepContent(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kCream,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(theme),
          const SizedBox(height: 24),
          _buildCurrentStep(theme),
          const SizedBox(height: 32),
          _buildStepperControls(theme),
        ],
      ),
    );
  }

  Widget _buildStepHeader(ThemeData theme) {
    final titles = [
      'Personal Information',
      'Address Details',
      'Document Verification'
    ];
    final subtitles = [
      'Please provide your basic information',
      'Enter your current address details',
      'Upload a government-issued ID for verification'
    ];
    final icons = [Iconsax.user, Iconsax.location, Iconsax.document_text_1];

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icons[currentStep],
            color: theme.primaryColor,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titles[currentStep],
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitles[currentStep],
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStep(ThemeData theme) {
    switch (currentStep) {
      case 0:
        return _buildStep1(theme);
      case 1:
        return _buildStep2(theme);
      case 2:
        return _buildStep3(theme);
      default:
        return const SizedBox();
    }
  }

  Widget _buildStepperControls(ThemeData theme) {
    return Row(
      children: [
        if (currentStep > 0) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => setState(() => currentStep = currentStep - 1),
              icon: Icon(Iconsax.arrow_left_2, size: 18),
              label: const Text('Previous'),
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.primaryColor,
                side: BorderSide(color: theme.primaryColor, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          flex: currentStep > 0 ? 1 : 2,
          child: ElevatedButton.icon(
            onPressed: _handleNext,
            icon: Icon(
              currentStep == 2 ? Iconsax.tick_circle : Iconsax.arrow_right_3,
              size: 18,
            ),
            label: Text(currentStep == 2 ? 'Save' : 'Save & Continue'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep1(ThemeData theme) {
    return Form(
      key: _step1FormKey,
      child: Column(
        children: [
          _buildTextField(
            controller: fullNameController,
            label: "Full Name",
            hint: "Enter your full name",
            icon: Iconsax.user,
            validator: _validateName,
            textCapitalization: TextCapitalization.words,
            maxLength: 30,
            theme: theme,
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => _selectDate(context),
            child: AbsorbPointer(
              child: _buildTextField(
                controller: dobController,
                label: "Date of Birth",
                hint: "Select your date of birth",
                icon: Iconsax.calendar_1,
                validator: _validateDOB,
                readOnly: true,
                theme: theme,
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildDropdownField(
            value: selectedGender.isEmpty ? null : selectedGender,
            label: "Gender",
            hint: "Select your gender",
            icon: Iconsax.profile_2user,
            items: genders,
            onChanged: (value) => setState(() => selectedGender = value!),
            validator: _validateGender,
            theme: theme,
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 90,
                child: _buildCountryCodePicker(theme),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: phoneController,
                  label: "Phone Number",
                  hint: "Enter phone number",
                  icon: Iconsax.call,
                  keyboardType: TextInputType.phone,
                  validator: _validatePhone,
                  maxLength: 10,
                  theme: theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep2(ThemeData theme) {
    return Form(
      key: _step2FormKey,
      child: Column(
        children: [
          _buildTextField(
            controller: addressController,
            label: "Full Address",
            hint: "Enter your complete address",
            icon: Iconsax.house,
            validator: (value) => _validateRequired(value, 'address'),
            textCapitalization: TextCapitalization.sentences,
            maxLines: 3,
            maxLength: 100,
            theme: theme,
          ),
          const SizedBox(height: 24),
          _buildCSCPicker(theme),
          const SizedBox(height: 20),
          _buildTextField(
            controller: pincodeController,
            label: "Pincode",
            hint: "Enter 6-digit pincode",
            icon: Iconsax.location,
            keyboardType: TextInputType.number,
            validator: _validatePincode,
            maxLength: 6,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildStep3(ThemeData theme) {
    return Form(
      key: _step3FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() {
            if (commonController.isLoading.value) {
              return _buildLoadingDropdown(theme);
            }

            if (commonController.docTypes.value == null ||
                commonController.docTypes.value!.data.isEmpty) {
              return _buildErrorContainer(
                  'Error loading document types. Please try again.', theme);
            }

            return _buildDropdownField(
              value: selectedDocType.isEmpty ? null : selectedDocType,
              label: "Document Type",
              hint: "Select document type",
              icon: Iconsax.document_text,
              items: commonController.docTypes.value!.data
                  .map((docType) => docType.dId.toString())
                  .toList(),
              itemLabels: commonController.docTypes.value!.data
                  .map((docType) => docType.dTitle ?? 'Unknown Document')
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedDocType = value!;
                  documentNumberController.clear();
                });
              },
              validator: _validateDocumentType,
              theme: theme,
            );
          }),
          const SizedBox(height: 20),
          _buildTextField(
            controller: documentNumberController,
            label: "Document Number",
            hint: "Enter document number",
            icon: Iconsax.card,
            validator: _validateDocumentNumber,
            textCapitalization: TextCapitalization.characters,
            maxLength: _getDocumentNumberMaxLength(),
            enabled: selectedDocType.isNotEmpty,
            theme: theme,
          ),
          const SizedBox(height: 24),
          _buildDocumentUploadSection(theme),
          const SizedBox(height: 20),
          _buildDocumentGuidelines(theme),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ThemeData theme,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int? maxLength,
    int maxLines = 1,
    bool readOnly = false,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          maxLength: maxLength,
          maxLines: maxLines,
          readOnly: readOnly,
          enabled: enabled,
          style: TextStyle(
            fontSize: 15,
            color: enabled ? Colors.black87 : Colors.grey[500],
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            prefixIcon: Icon(
              icon,
              color: enabled ? theme.primaryColor : Colors.grey[400],
              size: 20,
            ),
            filled: true,
            fillColor: enabled ? Colors.grey[50] : Colors.grey[100],
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red[400]!, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red[600]!, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            counterText: '',
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String label,
    required String hint,
    required IconData icon,
    required List<String> items,
    List<String>? itemLabels,
    required void Function(String?) onChanged,
    required String? Function(String?)? validator,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(icon, color: theme.primaryColor, size: 20),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: theme.primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red[400]!, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red[600]!, width: 2),
            ),
          ),
          items: List.generate(items.length, (index) {
            return DropdownMenuItem(
              value: items[index],
              child: Text(
                itemLabels != null ? itemLabels[index] : items[index],
                style: const TextStyle(fontSize: 15),
              ),
            );
          }),
          onChanged: onChanged,
          icon: Icon(Iconsax.arrow_down_1, size: 20, color: theme.primaryColor),
        ),
      ],
    );
  }

  Widget _buildCountryCodePicker(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Code',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kLine, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedCountryCode,
              isExpanded: true,
              items: countryCodes.map((code) {
                return DropdownMenuItem(
                  value: code,
                  child: Text(
                    code,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                );
              }).toList(),
              onChanged: (value) =>
                  setState(() => selectedCountryCode = value!),
              icon: Icon(Iconsax.arrow_down_1,
                  size: 16, color: theme.primaryColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCSCPicker(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kLine, width: 1),
          ),
          child: CSCPicker(
            layout: Layout.vertical,
            flagState: CountryFlag.DISABLE,
            defaultCountry: CscCountry.India,
            showStates: true,
            showCities: true,
            disableCountry: false,
            stateDropdownLabel: "Select State *",
            cityDropdownLabel: "Select City *",
            dropdownDecoration: BoxDecoration(
              color: kCream,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kLine, width: 1),
            ),
            selectedItemStyle: TextStyle(
              color: Colors.grey[800],
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            dropdownHeadingStyle: TextStyle(
              color: theme.primaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
            dropdownItemStyle: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
            ),
            onCountryChanged: (country) {
              setState(() {
                selectedCountry = 'India';
                selectedState = '';
                selectedCity = '';
              });
            },
            onStateChanged: (state) {
              setState(() {
                selectedState = state ?? '';
                stateController.text = selectedState;
                selectedCity = '';
                cityController.clear();
              });
            },
            onCityChanged: (city) {
              setState(() {
                selectedCity = city ?? '';
                cityController.text = selectedCity;
              });
            },
          ),
        ),
        if (selectedState.isEmpty ||
            (selectedState.isNotEmpty && selectedCity.isEmpty))
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Row(
              children: [
                Icon(Iconsax.info_circle, size: 14, color: Colors.red[600]),
                const SizedBox(width: 6),
                Text(
                  selectedState.isEmpty
                      ? 'Please select a state'
                      : 'Please select a city',
                  style: TextStyle(
                    color: Colors.red[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDocumentUploadSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload Document',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _pickDocument,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color:
                  selectedDocument != null ? Colors.green[50] : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selectedDocument != null
                    ? Colors.green[400]!
                    : Colors.grey[300]!,
                width: selectedDocument != null ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: selectedDocument != null
                        ? Colors.green[100]
                        : theme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    selectedDocument != null
                        ? Iconsax.document_upload
                        : Iconsax.document_upload,
                    size: 32,
                    color: selectedDocument != null
                        ? Colors.green[700]
                        : theme.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  selectedDocument != null
                      ? 'Document Uploaded Successfully'
                      : 'Tap to Upload Document',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: selectedDocument != null
                        ? Colors.green[700]
                        : theme.primaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  selectedDocument != null
                      ? documentFileName
                      : 'Supported: PDF, JPG, PNG (Max ${maxFileSizeMB}MB)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        if (selectedDocument != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kCream,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kLine, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getFileIcon(documentFileName),
                    color: Colors.green[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        documentFileName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getFileSize(selectedDocument!),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      selectedDocument = null;
                      documentFileName = '';
                    });
                  },
                  icon: Icon(Iconsax.close_circle, color: Colors.red[400]),
                  tooltip: 'Remove document',
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDocumentGuidelines(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.info_circle, color: Colors.blue[700], size: 18),
              const SizedBox(width: 8),
              Text(
                'Document Guidelines',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildGuidelineItem(
              'Document should be clear and readable', Colors.blue),
          _buildGuidelineItem('All four corners must be visible', Colors.blue),
          _buildGuidelineItem(
              'Maximum file size: ${maxFileSizeMB}MB', Colors.blue),
          _buildGuidelineItem(
              'Accepted formats: PDF, JPG, JPEG, PNG', Colors.blue),
        ],
      ),
    );
  }

  Widget _buildGuidelineItem(String text, MaterialColor color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: color[600],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: color[700],
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingDropdown(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Document Type',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kLine, width: 1),
          ),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorContainer(String message, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!, width: 1),
      ),
      child: Row(
        children: [
          Icon(Iconsax.close_circle, color: Colors.red[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red[700],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
