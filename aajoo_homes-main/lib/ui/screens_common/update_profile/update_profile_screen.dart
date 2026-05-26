import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../constants.dart';
import '../auth/auth_controller.dart';
import '../../../controller/common_controller.dart';
import '../../../data/models/update_user_model.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final AuthController authController = Get.find<AuthController>();
  final CommonController commonController = Get.find<CommonController>();
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _zipcodeController = TextEditingController();
  final TextEditingController _docNumberController = TextEditingController();

  // State variables
  // Store selected document type as ID (string) for Dropdown value parity
  String? selectedDocTypeId;
  File? selectedDocument;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Ensure doc types are loaded
    if (commonController.docTypes.value == null ||
        (commonController.docTypes.value?.data.isEmpty ?? true)) {
      commonController.fetchDocTypes();
    }
  }

  void _showDocumentViewer() {
    final kycDocs = authController.userData.value?.kycDocs;
    if (kycDocs == null || (kycDocs.imageUrl.isEmpty)) {
      _showSnackBar('No document available to view', isError: true);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'KYC Document',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Type: ${kycDocs.docTypeDTitle}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Details
            Container(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.description, color: kprimaryColor),
                          const SizedBox(width: 8),
                          const Text(
                            'Document Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _infoRow('Document Type', kycDocs.docTypeDTitle),
                      _infoRow('Document Number', kycDocs.udNumber),
                      _infoRow('File ID', kycDocs.udAfileId.toString()),
                    ],
                  ),
                ),
              ),
            ),
            // Image
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: InteractiveViewer(
                    panEnabled: true,
                    boundaryMargin: const EdgeInsets.all(20),
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: Image.network(
                      kycDocs.imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        (loadingProgress.expectedTotalBytes ??
                                            1)
                                    : null,
                                color: kprimaryColor,
                              ),
                              const SizedBox(height: 16),
                              const Text('Loading document...'),
                            ],
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              const Text('Failed to load document'),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Pinch to zoom • Drag to pan',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _loadUserData() {
    final user = authController.userData.value;
    if (user != null) {
      // Split full name into first and last name
      final nameParts = user.fullName.split(' ');
      _firstNameController.text = nameParts.isNotEmpty ? nameParts[0] : '';
      _lastNameController.text =
          nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      _phoneController.text = user.phoneNumber;
      _addressController.text = user.address;
      _cityController.text = user.city;
      _zipcodeController.text = user.zipcode;

      // Load existing document info if available
      if (user.kycDocs != null) {
        _docNumberController.text = user.kycDocs!.udNumber;
        // Map existing title to ID once doc types are available (handled in Obx in dropdown)
      }
    }
  }

  // Helpers: map doc type ID (string) to its title
  String? _docTitleFromId(String id) {
    final docs = commonController.docTypes.value?.data ?? [];
    for (final d in docs) {
      if (d.dId.toString() == id) return d.dTitle;
    }
    return null;
  }

  // Document number validation by type
  String? _validateDocNumber(String? value, {String? docTypeTitle}) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter the document number';
    }

    final title = (docTypeTitle ?? '').toLowerCase();
    final raw = value.trim();
    final compact = raw.replaceAll(RegExp(r'[\s-]'), '');
    final upper = compact.toUpperCase();

    // Aadhaar
    if (title.contains('aadhaar') ||
        title.contains('aadhar') ||
        title.contains('adhar')) {
      if (!RegExp(r'^\d{12}$').hasMatch(compact)) {
        return 'Enter a valid Aadhaar number (12 digits)';
      }
      return null;
    }

    // PAN
    if (title.contains('pan')) {
      if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$').hasMatch(upper)) {
        return 'Enter a valid PAN (e.g., ABCDE1234F)';
      }
      return null;
    }

    // Passport (Indian typical: 1 letter + 7 digits; excluding O/Q)
    if (title.contains('passport')) {
      if (!RegExp(r'^[A-PR-WY][0-9]{7}$').hasMatch(upper)) {
        return 'Enter a valid Passport number (1 letter + 7 digits)';
      }
      return null;
    }

    // Driving License (common pattern: 2 letters + 2 digits + 11 digits)
    if (title.contains('driving') ||
        title.contains('license') ||
        title.contains('dl')) {
      if (!RegExp(r'^[A-Z]{2}[0-9]{2}[0-9]{11}$').hasMatch(upper)) {
        return 'Enter a valid Driving License number';
      }
      return null;
    }

    // Voter ID (EPIC): 3 letters + 7 digits
    if (title.contains('voter') || title.contains('epic')) {
      if (!RegExp(r'^[A-Z]{3}[0-9]{7}$').hasMatch(upper)) {
        return 'Enter a valid Voter ID (e.g., ABC1234567)';
      }
      return null;
    }

    // Ration Card: 8-15 alphanumeric
    if (title.contains('ration')) {
      if (!RegExp(r'^[A-Z0-9]{8,15}$').hasMatch(upper)) {
        return 'Enter a valid Ration Card number (8-15 alphanumeric)';
      }
      return null;
    }

    // Generic fallback
    if (upper.length < 6) {
      return 'Document number seems too short';
    }
    return null;
  }

  Future<void> _pickDocument() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          selectedDocument = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showSnackBar('Error picking document: ${e.toString()}', isError: true);
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      // Ensure doc types are available for mapping existing KYC
      if (commonController.docTypes.value == null ||
          (commonController.docTypes.value?.data.isEmpty ?? true)) {
        await commonController.fetchDocTypes();
      }

      // Resolve doc type and number to send
      final kyc = authController.userData.value?.kycDocs;
      String? docTypeToSend = selectedDocTypeId; // already ID as string
      String? docNumberToSend = _docNumberController.text.trim().isNotEmpty
          ? _docNumberController.text.trim()
          : null;

      // If user didn't change selection/number, pull from existing KYC
      if (docTypeToSend == null && kyc != null) {
        final docs = commonController.docTypes.value?.data ?? [];
        for (final d in docs) {
          if (d.dTitle.trim().toLowerCase() ==
              kyc.docTypeDTitle.trim().toLowerCase()) {
            docTypeToSend = d.dId.toString();
            break;
          }
        }
      }
      if (docNumberToSend == null && kyc != null && kyc.udNumber.isNotEmpty) {
        docNumberToSend = kyc.udNumber;
      }

      final request = UserUpdateRequest(
        userFname: _firstNameController.text.trim(),
        userLname: _lastNameController.text.trim(),
        userPnumber: _phoneController.text.trim(),
        userAddress: _addressController.text.trim(),
        userCity: _cityController.text.trim(),
        userZipcode: _zipcodeController.text.trim(),
        docType: docTypeToSend,
        docNumber: docNumberToSend,
        idDoc: selectedDocument,
      );

      await authController.updateUserProfile(request);

      // Check if the update was successful by checking if there's no error
      if (authController.error.value.isEmpty) {
        _showSnackBar('Profile updated successfully!', isError: false);
        // Wait a bit for user to see the success message, then navigate back
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Get.back();
        }
      } else {
        _showSnackBar(authController.error.value, isError: true);
      }
    } catch (e) {
      _showSnackBar('Failed to update profile: ${e.toString()}', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildDocumentSection() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Identity Document',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Document Type Dropdown (uses IDs from CommonController)
            Obx(() {
              final docs = commonController.docTypes.value?.data ?? [];
              if (docs.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              // Map existing user's KYC title to ID on first build
              final user = authController.userData.value;
              if (selectedDocTypeId == null && user?.kycDocs != null) {
                for (final d in docs) {
                  if (d.dTitle.trim().toLowerCase() ==
                      user!.kycDocs!.docTypeDTitle.trim().toLowerCase()) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          selectedDocTypeId = d.dId.toString();
                        });
                      }
                    });
                    break;
                  }
                }
              }

              return DropdownButtonFormField<String>(
                value: selectedDocTypeId,
                decoration: const InputDecoration(
                  labelText: 'Document Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                items: docs
                    .map((docType) => DropdownMenuItem<String>(
                          value: docType.dId.toString(),
                          child: Text(docType.dTitle),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedDocTypeId = value;
                  });
                },
                validator: (val) {
                  // If user provides a document number, require type as well
                  if (_docNumberController.text.trim().isNotEmpty &&
                      (val == null || val.isEmpty)) {
                    return 'Please select document type';
                  }
                  return null;
                },
              );
            }),

            const SizedBox(height: 16),

            // Document Number
            TextFormField(
              controller: _docNumberController,
              decoration: const InputDecoration(
                labelText: 'Document Number',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                // Only allow alphanumeric characters (no emojis/symbols)
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              ],
              validator: (value) {
                // If user selected a type (or has existing type mapped), validate against pattern
                final title = selectedDocTypeId != null
                    ? _docTitleFromId(selectedDocTypeId!)
                    : null;
                if ((selectedDocTypeId != null) ||
                    (authController.userData.value?.kycDocs != null &&
                        value != null &&
                        value.isNotEmpty)) {
                  final err = _validateDocNumber(value, docTypeTitle: title);
                  if (err != null) return err;
                }
                // If a number is provided without type, apply a generic check
                if ((value ?? '').isNotEmpty && title == null) {
                  if (!RegExp(r'^[A-Za-z0-9]{6,}$')
                      .hasMatch(value!.trim().toUpperCase())) {
                    return 'Invalid document number';
                  }
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Current Document Status
            Obx(() {
              final user = authController.userData.value;
              if (user?.kycDocs != null) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Current Document: ${user!.kycDocs!.docTypeDTitle}\nNumber: ${user.kycDocs!.udNumber}',
                          style: const TextStyle(color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'No document uploaded yet',
                      style: TextStyle(color: Colors.orange),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),

            // Document Upload
            ElevatedButton.icon(
              onPressed: _pickDocument,
              icon: const Icon(Icons.cloud_upload),
              label: Text(selectedDocument != null
                  ? 'Document Selected'
                  : 'Upload New Document'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    selectedDocument != null ? Colors.green : kprimaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
              ),
            ),

            const SizedBox(height: 8),

            // View current document (if any)
            Obx(() {
              final hasDoc = authController.userData.value?.kycDocs != null &&
                  (authController.userData.value!.kycDocs!.imageUrl.isNotEmpty);
              if (!hasDoc) return const SizedBox.shrink();
              return OutlinedButton.icon(
                onPressed: _showDocumentViewer,
                icon: const Icon(Icons.visibility),
                label: const Text('View Current Document'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kprimaryColor,
                  side: const BorderSide(color: kprimaryColor),
                  minimumSize: const Size(double.infinity, 45),
                ),
              );
            }),

            if (selectedDocument != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.attach_file, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        selectedDocument!.path.split('/').last,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          selectedDocument = null;
                        });
                      },
                      icon: const Icon(Icons.close, color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Profile'),
        backgroundColor: kprimaryColor,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (authController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Personal Information Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Personal Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _firstNameController,
                                decoration: const InputDecoration(
                                  labelText: 'First Name',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.person),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter first name';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _lastNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Last Name',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter last name';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone),
                          ),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter phone number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          maxLines: 2,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _cityController,
                                decoration: const InputDecoration(
                                  labelText: 'City',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.location_city),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter city';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _zipcodeController,
                                decoration: const InputDecoration(
                                  labelText: 'Zipcode',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.local_post_office),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter zipcode';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Document Section
                _buildDocumentSection(),

                const SizedBox(height: 24),

                // Update Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kprimaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Update Profile',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _zipcodeController.dispose();
    _docNumberController.dispose();
    super.dispose();
  }
}
