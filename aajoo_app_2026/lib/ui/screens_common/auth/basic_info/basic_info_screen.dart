import 'package:flutter/services.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/utils/input_sanitizers.dart';
import '../../../../utils/csc_picker/csc_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:rent_home/controller/common_controller.dart';
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

  // Text controllers
  final fullNameController = TextEditingController();
  final dobController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final pincodeController = TextEditingController();

  // State variables
  int currentStep = 0;
  String selectedGender = '';
  String selectedCountryCode = '+91';
  String selectedCountry = 'India';
  String selectedState = '';
  String selectedCity = '';
  String documentFileName = '';

  // Constants
  static const List<String> genders = ['Male', 'Female', 'Other'];
  static const List<String> countryCodes = ['+91'];
  static const int minAge = 18;

  // Validation regex patterns — the same rules the rest of the platform uses:
  // names may carry . ' -, a PIN cannot start with 0, a mobile starts 6-9.
  static final RegExp _nameRegex = RegExp(r"^[a-zA-Z .'’-]{2,50}$");
  static final RegExp _pincodeRegex = RegExp(r'^[1-9]\d{5}$');
  static final RegExp _phoneRegex = RegExp(r'^[6-9]\d{9}$');

  @override
  void dispose() {
    fullNameController.dispose();
    dobController.dispose();
    phoneController.dispose();
    addressController.dispose();
    cityController.dispose();
    stateController.dispose();
    pincodeController.dispose();
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


  void _handleNext() {
    switch (currentStep) {
      case 0:
        if (_step1FormKey.currentState!.validate()) {
          setState(() => currentStep = 1);
        }
        break;
      case 1:
        // Signing up used to end on a third step collecting an ID type, an ID
        // number and a scan of the document — the same document DIDIT reads
        // for itself during verification, and the same one the listing wizard
        // asked hosts for a third time. Nothing downstream trusted the typed
        // copy. The step is gone; identity is established once, by the check
        // built for it.
        if (_validateStep2()) {
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
    });


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
      backgroundColor: kSand,
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
        onPressed: () => Get.back(),
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
            children: List.generate(2, (index) {
              final isActive = index <= currentStep;

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
                    if (index < 1)
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kLine),
        boxShadow: [
          BoxShadow(
            color: kInk.withOpacity(0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
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
    ];
    final subtitles = [
      'Please provide your basic information',
      'Enter your current address details',
    ];
    final icons = [Iconsax.user, Iconsax.location];

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [kIndigo, kIndigo600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: kIndigo.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            icons[currentStep],
            color: kCream,
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
                style: fraunces(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: kInk,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitles[currentStep],
                style: inter(
                  fontSize: 13,
                  color: kMuted,
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
      default:
        return const SizedBox();
    }
  }

  Widget _buildStepperControls(ThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            if (currentStep > 0) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => currentStep = currentStep - 1),
                  icon: const Icon(Iconsax.arrow_left_2, size: 18),
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
                  currentStep == 1 ? Iconsax.tick_circle : Iconsax.arrow_right_3,
                  size: 18,
                ),
                label: Text(currentStep == 1 ? 'Complete' : 'Next'),
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
        ),
      ],
    );
  }

  Widget _buildStep1(ThemeData theme) {
    return Form(
      key: _step1FormKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        children: [
          _buildTextField(
            controller: fullNameController,
            label: "Full Name",
            hint: "Enter your full name",
            icon: Iconsax.user,
            validator: _validateName,
            textCapitalization: TextCapitalization.words,
            // 50 to match _nameRegex — the old 30 cap rejected names the
            // validator itself allowed.
            maxLength: 50,
            inputFormatters: AppInputFormatters.name,
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
              SizedBox(
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
                  inputFormatters: AppInputFormatters.mobile,
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
      autovalidateMode: AutovalidateMode.onUserInteraction,
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
            inputFormatters: AppInputFormatters.pincode,
            theme: theme,
          ),
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
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: kInk2,
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
          inputFormatters: inputFormatters,
          cursorColor: kIndigo,
          style: inter(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: enabled ? kInk : kMuted,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: inter(color: kMuted, fontSize: 14),
            prefixIcon: Container(
              margin: const EdgeInsets.only(left: 6, right: 4),
              child: Icon(
                icon,
                color: enabled ? kIndigo : kMuted,
                size: 20,
              ),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 44, minHeight: 44),
            filled: true,
            fillColor: enabled ? kCream : kSand.withOpacity(0.5),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kLine, width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kLine, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kIndigo, width: 1.6),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kDanger, width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kDanger, width: 1.6),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: kLine.withOpacity(0.6), width: 1.2),
            ),
            errorStyle: inter(fontSize: 12, color: kDanger),
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
          style: inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: kInk2,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          validator: validator,
          isExpanded: true,
          dropdownColor: kCream,
          borderRadius: BorderRadius.circular(14),
          style: inter(fontSize: 15, fontWeight: FontWeight.w500, color: kInk),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: inter(color: kMuted, fontSize: 14),
            prefixIcon: Container(
              margin: const EdgeInsets.only(left: 6, right: 4),
              child: Icon(icon, color: kIndigo, size: 20),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 44, minHeight: 44),
            filled: true,
            fillColor: kCream,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kLine, width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kLine, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kIndigo, width: 1.6),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kDanger, width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: kDanger, width: 1.6),
            ),
            errorStyle: inter(fontSize: 12, color: kDanger),
          ),
          items: List.generate(items.length, (index) {
            return DropdownMenuItem(
              value: items[index],
              child: Text(
                itemLabels != null ? itemLabels[index] : items[index],
                style: inter(fontSize: 15, color: kInk),
              ),
            );
          }),
          onChanged: onChanged,
          icon: const Icon(Iconsax.arrow_down_1, size: 20, color: kIndigo),
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





}
