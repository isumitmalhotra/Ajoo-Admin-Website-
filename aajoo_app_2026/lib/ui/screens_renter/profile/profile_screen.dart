import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:animations/animations.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/controller/user_controller.dart';
import 'package:rent_home/ui/screens_renter/history/history_page.dart';
import 'package:rent_home/ui/screens_common/update_profile/update_profile_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../screens_common/auth/auth_controller.dart';
import '../../../controller/common_controller.dart';
import '../../../data/models/update_user_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final AuthController authController = Get.find<AuthController>();
  final UserController userController = Get.find<UserController>();
  final CommonController commonController = Get.find<CommonController>();
  late AnimationController _animationController;
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  Future<XFile?> _pickKycDocument() async {
    final pickedFile = await _picker.pickMedia();
    if (pickedFile != null) {
      return pickedFile;
    }
    return null;
  }

  // Form controllers
  final TextEditingController _fnameController = TextEditingController();
  final TextEditingController _lnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _zipcodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    try {
      _animationController.forward();
      _initializeControllers();
    } catch (e) {
      Get.snackbar('Error', 'Failed to initialize profile: $e');
    }
  }

  void _initializeControllers() {
    try {
      final userData = authController.userData.value;
      if (userData != null) {
        final names = userData.fullName.trim().split(' ');
        _fnameController.text = names.isNotEmpty ? names.first : '';
        _lnameController.text = names.length > 1 ? names.last : '';
        _phoneController.text = userData.phoneNumber;
        _addressController.text = userData.address;
        _cityController.text = userData.city;
        _zipcodeController.text = userData.zipcode;
      } else {
        Get.snackbar('Warning', 'User data not available');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to load user data: $e');
    }
  }

  // Helpers: document type specific validation
  String? _docTitleFromId(String id) {
    final docs = commonController.docTypes.value?.data ?? [];
    for (final d in docs) {
      if (d.dId.toString() == id) return d.dTitle;
    }
    return null;
  }

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

    // Driving License (common pattern: 2 letters + 2 digits + 11 digits; allow spaces)
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

  void _showKycBottomSheet(BuildContext context) {
    XFile? selectedFile;
    final TextEditingController cardNumberController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? selectedDocType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Upload KYC Document',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Iconsax.close_circle,
                              color: Colors.grey),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    // DIDIT identity status — once verified the manual upload
                    // below is no longer required.
                    Obx(() {
                      final verified =
                          authController.userData.value?.isKycVerified ?? false;
                      if (!verified) return const SizedBox.shrink();
                      return Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF15803D).withOpacity(0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified,
                                size: 16, color: Color(0xFF15803D)),
                            SizedBox(width: 6),
                            Text('Identity verified',
                                style: TextStyle(
                                    color: Color(0xFF15803D),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),

                    // Document Type Dropdown
                    Obx(() {
                      if (commonController.isLoading.value) {
                        return Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child:
                                CircularProgressIndicator(color: kprimaryColor),
                          ),
                        );
                      }

                      if (commonController.docTypes.value == null ||
                          commonController.docTypes.value!.data.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Text(
                            'Document types unavailable',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        );
                      }

                      return DropdownButtonFormField<String>(
                        value: selectedDocType,
                        decoration: InputDecoration(
                          labelText: 'Select Document Type',
                          prefixIcon: const Icon(Iconsax.document_text,
                              color: kprimaryColor),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select document type';
                          }
                          return null;
                        },
                        items: commonController.docTypes.value!.data
                            .map((docType) {
                          return DropdownMenuItem(
                            value: docType.dId.toString(),
                            child: Text(docType.dTitle),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedDocType = value;
                          });
                        },
                      );
                    }),

                    const SizedBox(height: 16),

                    // Document Upload Section
                    GestureDetector(
                      onTap: () async {
                        final file = await _pickKycDocument();
                        if (file != null) {
                          setState(() {
                            selectedFile = file;
                          });
                        }
                      },
                      child: Container(
                        height: 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kLine),
                        ),
                        child: Center(
                          child: selectedFile == null
                              ? const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Iconsax.document_upload,
                                        color: kprimaryColor, size: 30),
                                    SizedBox(height: 8),
                                    Text('Select Document',
                                        style: TextStyle(color: Colors.grey)),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Iconsax.tick_circle,
                                        color: Colors.green, size: 30),
                                    const SizedBox(height: 8),
                                    Text(
                                      selectedFile!.name,
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.black87),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Document Number Field
                    TextFormField(
                      controller: cardNumberController,
                      decoration: InputDecoration(
                        labelText: 'Document Number',
                        prefixIcon:
                            const Icon(Iconsax.card, color: kprimaryColor),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType: TextInputType.text,
                      validator: (value) {
                        final title = selectedDocType != null
                            ? _docTitleFromId(selectedDocType!)
                            : null;
                        return _validateDocNumber(value, docTypeTitle: title);
                      },
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState!.validate() &&
                              selectedFile != null) {
                            try {
                              authController
                                  .updateUserProfile(
                                UserUpdateRequest(
                                  userFname: _fnameController.text
                                          .trim()
                                          .isNotEmpty
                                      ? _fnameController.text.trim()
                                      : (authController.userData.value?.fullName
                                              .split(' ')
                                              .first ??
                                          ''),
                                  userLname: _lnameController.text
                                          .trim()
                                          .isNotEmpty
                                      ? _lnameController.text.trim()
                                      : (authController.userData.value?.fullName
                                                      .split(' ')
                                                      .length ??
                                                  0) >
                                              1
                                          ? authController
                                              .userData.value!.fullName
                                              .split(' ')
                                              .last
                                          : '',
                                  userPnumber:
                                      _phoneController.text.trim().isNotEmpty
                                          ? _phoneController.text.trim()
                                          : (authController.userData.value
                                                  ?.phoneNumber ??
                                              ''),
                                  userAddress:
                                      _addressController.text.trim().isNotEmpty
                                          ? _addressController.text.trim()
                                          : (authController
                                                  .userData.value?.address ??
                                              ''),
                                  userCity: _cityController.text
                                          .trim()
                                          .isNotEmpty
                                      ? _cityController.text.trim()
                                      : (authController.userData.value?.city ??
                                          ''),
                                  userZipcode:
                                      _zipcodeController.text.trim().isNotEmpty
                                          ? _zipcodeController.text.trim()
                                          : (authController
                                                  .userData.value?.zipcode ??
                                              ''),
                                  docNumber: cardNumberController.text.trim(),
                                  docType: selectedDocType,
                                  idDoc: selectedFile != null
                                      ? File(selectedFile!.path)
                                      : null,
                                ),
                              )
                                  .then((_) {
                                authController.getUserDetails();
                              });
                              Navigator.pop(context);

                              Get.snackbar(
                                'Success',
                                'KYC document submitted for verification',
                                backgroundColor: kprimaryColor,
                                colorText: Colors.white,
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            } catch (e) {
                              Get.snackbar(
                                'Error',
                                'Failed to submit KYC document: $e',
                                backgroundColor: Colors.red,
                                colorText: Colors.white,
                                snackPosition: SnackPosition.BOTTOM,
                              );
                            }
                          } else {
                            Get.snackbar(
                              'Error',
                              'Please fill all required fields and select a document',
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                              snackPosition: SnackPosition.BOTTOM,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kprimaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Submit',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDocumentViewer(BuildContext context) {
    final kycDocs = authController.userData.value?.kycDocs;
    if (kycDocs == null || kycDocs.imageUrl.isEmpty) {
      Get.snackbar('Error', 'No document available to view');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: kCream,
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
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Verified',
                      style: TextStyle(
                        color: kCream,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Document Details
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
                      const Row(
                        children: [
                          Icon(
                            Iconsax.document_text,
                            color: kprimaryColor,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Document Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDocumentInfoRow(
                          'Document Type', kycDocs.docTypeDTitle),
                      _buildDocumentInfoRow(
                          'Document Number', kycDocs.udNumber),
                      _buildDocumentInfoRow(
                          'File ID', kycDocs.udAfileId.toString()),
                    ],
                  ),
                ),
              ),
            ),
            // Document Image
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kLine),
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
                                        loadingProgress.expectedTotalBytes!
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
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Document preview unavailable',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Please check your internet connection',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
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
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUpdateDocumentBottomSheet(BuildContext context) {
    XFile? selectedFile;
    final TextEditingController docNumberController = TextEditingController();
    final updateFormKey = GlobalKey<FormState>();
    String? selectedDocTypeId; // use doc type ID as value

    // Ensure doc types are loaded
    if (commonController.docTypes.value == null ||
        (commonController.docTypes.value?.data.isEmpty ?? true)) {
      commonController.fetchDocTypes();
    }

    // Pre-fill with existing data if available
    final userData = authController.userData.value;
    final kycDocs = userData?.kycDocs;
    if (kycDocs != null) {
      docNumberController.text = kycDocs.udNumber;
      // We'll map the current title to an ID after doc types are available (inside builder)
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.95,
              decoration: const BoxDecoration(
                color: kCream,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  left: 16,
                  right: 16,
                  top: 16,
                ),
                child: Form(
                  key: updateFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Update KYC Document',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Iconsax.close_circle,
                                color: Colors.grey),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Document Type Dropdown (from CommonController)
                      const Text(
                        'Document Type',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Obx(() {
                        // Map existing KYC title to an ID once data is loaded
                        final docs =
                            commonController.docTypes.value?.data ?? [];
                        if (docs.isNotEmpty &&
                            selectedDocTypeId == null &&
                            kycDocs != null &&
                            kycDocs.docTypeDTitle.isNotEmpty) {
                          for (final d in docs) {
                            if (d.dTitle.trim().toLowerCase() ==
                                kycDocs.docTypeDTitle.trim().toLowerCase()) {
                              // ensure we set inside setState to rebuild dropdown with value
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                setState(() {
                                  selectedDocTypeId = d.dId.toString();
                                });
                              });
                              break;
                            }
                          }
                        }

                        if (commonController.isLoading.value) {
                          return Container(
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                  color: kprimaryColor),
                            ),
                          );
                        }

                        if (docs.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red[200]!),
                            ),
                            child: Text(
                              'Document types unavailable',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          );
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: selectedDocTypeId, // ID as value
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              prefixIcon:
                                  Icon(Iconsax.card, color: kprimaryColor),
                            ),
                            items: docs
                                .map((docType) => DropdownMenuItem<String>(
                                      value: docType.dId.toString(),
                                      child: Text(docType.dTitle),
                                    ))
                                .toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedDocTypeId = newValue;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a document type';
                              }
                              return null;
                            },
                          ),
                        );
                      }),
                      const SizedBox(height: 16),

                      // Document Number
                      const Text(
                        'Document Number',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: docNumberController,
                        decoration: InputDecoration(
                          hintText: 'Enter document number',
                          prefixIcon: const Icon(Iconsax.card_edit,
                              color: kprimaryColor),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        keyboardType: TextInputType.text,
                        validator: (value) {
                          final title = selectedDocTypeId != null
                              ? _docTitleFromId(selectedDocTypeId!)
                              : null;
                          return _validateDocNumber(value, docTypeTitle: title);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Document Upload
                      const Text(
                        'Upload Document',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final file = await _pickKycDocument();
                          if (file != null) {
                            setState(() {
                              selectedFile = file;
                            });
                          }
                        },
                        child: Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedFile != null
                                  ? kprimaryColor
                                  : Colors.grey[400]!,
                              width: selectedFile != null ? 2 : 1,
                            ),
                          ),
                          child: selectedFile == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Iconsax.document_upload,
                                      color: Colors.grey[600],
                                      size: 40,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Tap to select new document',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'JPG, PNG or PDF supported',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Iconsax.document_text,
                                      color: kprimaryColor,
                                      size: 40,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      selectedFile!.name,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Tap to change document',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const Spacer(),

                      // Update Button
                      Obx(() => SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: authController.isLoading.value
                                  ? null
                                  : () async {
                                      if (updateFormKey.currentState!
                                              .validate() &&
                                          selectedDocTypeId != null) {
                                        if (selectedFile == null) {
                                          Get.snackbar(
                                            'Error',
                                            'Please select a document to upload',
                                            backgroundColor: Colors.red,
                                            colorText: Colors.white,
                                            snackPosition: SnackPosition.BOTTOM,
                                          );
                                          return;
                                        }

                                        try {
                                          final userData =
                                              authController.userData.value!;
                                          await authController.updateDocument(
                                            userFullName: userData.fullName,
                                            userPnumber: userData.phoneNumber,
                                            userAddress: userData.address,
                                            userCity: userData.city,
                                            userZipcode: userData.zipcode,
                                            docType:
                                                int.parse(selectedDocTypeId!),
                                            docNumber:
                                                docNumberController.text.trim(),
                                            userIdDoc: File(selectedFile!.path),
                                          );

                                          if (authController
                                              .error.value.isEmpty) {
                                            Navigator.pop(context);
                                          }
                                        } catch (e) {
                                          Get.snackbar(
                                            'Error',
                                            'Failed to update document: $e',
                                            backgroundColor: Colors.red,
                                            colorText: Colors.white,
                                            snackPosition: SnackPosition.BOTTOM,
                                          );
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kprimaryColor,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: authController.isLoading.value
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: kCream,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Update Document',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          )),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState?.validate() != true) return;

    try {
      // Ensure document types are available so we can resolve current KYC type to its ID
      if (commonController.docTypes.value == null ||
          (commonController.docTypes.value?.data.isEmpty ?? true)) {
        await commonController.fetchDocTypes();
      }

      // Include current KYC details (if any) so backend validation passes
      final kyc = authController.userData.value?.kycDocs;
      String? docNumberToSend;
      String? docTypeIdToSend;

      if (kyc != null) {
        if (kyc.udNumber.isNotEmpty) {
          docNumberToSend = kyc.udNumber;
        }

        final docs = commonController.docTypes.value?.data ?? [];
        for (final d in docs) {
          if (d.dTitle.trim().toLowerCase() ==
              kyc.docTypeDTitle.trim().toLowerCase()) {
            docTypeIdToSend = d.dId.toString();
            break;
          }
        }
      }

      final request = UserUpdateRequest(
        userFname: _fnameController.text.trim(),
        userLname: _lnameController.text.trim(),
        userPnumber: _phoneController.text.trim(),
        userAddress: _addressController.text.trim(),
        userCity: _cityController.text.trim(),
        userZipcode: _zipcodeController.text.trim(),
        docType: docTypeIdToSend,
        docNumber: docNumberToSend,
      );

      final result = await authController.updateUserProfile(request);

      if (result.isSuccess) {
        showDialog(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Success'),
              content: Text(result.message ?? ''),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Error'),
            backgroundColor: Colors.red,
          ),
        );
      }

      // // Check if update was successful
      // if (authController.error.value.isEmpty) {
      //   Get.snackbar('Success', 'Profile updated successfully',
      //       snackPosition: SnackPosition.TOP, backgroundColor: Colors.green);
      //   // Refresh user data to keep local state in sync
      //   await authController.getUserDetails();
      // } else {
      //   Get.snackbar('Error', authController.error.value,
      //       snackPosition: SnackPosition.TOP, backgroundColor: Colors.red);
      // }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update profile: $e',
          snackPosition: SnackPosition.TOP, backgroundColor: Colors.red);
    }
  }

  /// Tapping the avatar / camera badge entry point. If a photo already
  /// exists, surface a Change / Remove / Cancel sheet so the user can drop
  /// the picture. If there's no photo yet, jump straight into the picker.
  Future<void> _onProfileImageTap() async {
    final user = authController.userData.value;
    final hasPhoto = user?.attachment != null && user!.attachment!.isNotEmpty;
    if (!hasPhoto) {
      await _pickAndUploadImage();
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: kCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: kprimaryColor),
              title: const Text('Change photo'),
              onTap: () async {
                Navigator.pop(sheetCtx);
                await _pickAndUploadImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: kDanger),
              title: const Text('Remove photo',
                  style: TextStyle(color: kDanger)),
              onTap: () async {
                Navigator.pop(sheetCtx);
                await _removeProfileImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.close, color: kMuted),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(sheetCtx),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxHeight: 800,
        maxWidth: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        Get.snackbar('Info', 'No image selected');
        return;
      }

      final imageFile = File(pickedFile.path);
      final newImageUrl = await userController.addProfileImage(imageFile);

      // Update the avatar immediately from the upload response. The Obx body
      // rebuilds, so the new picture shows even if the /user/detail refresh
      // below fails (e.g. for accounts the backend can't fully resolve).
      if (newImageUrl != null && newImageUrl.isNotEmpty) {
        final current = authController.userData.value;
        if (current != null) {
          authController.userData.value =
              current.copyWith(attachment: newImageUrl);
        }
      }

      // Best-effort refresh from server. Never log the user out if it fails —
      // the upload already succeeded.
      await authController.getUserDetails(skipLogoutOnError: true);
    } catch (e) {
      Get.snackbar('Error', 'Failed to upload image: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _removeProfileImage() async {
    try {
      final ok = await userController.removeProfileImage();
      if (ok) {
        // Clear the avatar immediately, then best-effort refresh without
        // risking a logout if /user/detail fails.
        final current = authController.userData.value;
        if (current != null) {
          authController.userData.value = current.copyWith(attachment: '');
        }
        await authController.getUserDetails(skipLogoutOnError: true);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to remove photo: $e',
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  @override
  void dispose() {
    try {
      _animationController.dispose();
      _fnameController.dispose();
      _lnameController.dispose();
      _phoneController.dispose();
      _addressController.dispose();
      _cityController.dispose();
      _zipcodeController.dispose();
      _scrollController.dispose();
    } catch (e) {
      debugPrint('Error during dispose: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print(authController.userData.value?.kycDocs?.toJson());
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Obx(() {
        final user = authController.userData.value;

        if (user == null) {
          // Only show shimmer if we're actively fetching the user
          // (i.e. a real login is in-flight). Otherwise show a clean
          // sign-in CTA — covers dev-skip + network-drop / 401 cases.
          if (authController.isLoading.value) {
            return _buildShimmerLoading();
          }
          return _buildSignedOutState(context);
        }

        return AnimationLimiter(
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.only(top: 80, bottom: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor.withOpacity(0.8),
                          ],
                        ),
                      ),
                      child: Center(
                        child: FadeScaleTransition(
                          animation: _animationController,
                          child: Hero(
                            tag: 'profile_picture',
                            child: GestureDetector(
                              onTap: () {
                                _onProfileImageTap();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: kCream,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 15,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircleAvatar(
                                      radius: 100,
                                      backgroundImage:
                                          user.attachment != null &&
                                                  user.attachment!.isNotEmpty
                                              ? NetworkImage(user.attachment!)
                                              : null,
                                      backgroundColor: Colors.white,
                                      child: user.attachment == null ||
                                              user.attachment!.isEmpty
                                          ? Text(
                                              user.fullName.isNotEmpty
                                                  ? user.fullName[0]
                                                      .toUpperCase()
                                                  : '',
                                              style: TextStyle(
                                                fontSize: 48,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                    .primaryColor,
                                              ),
                                            )
                                          : null,
                                    ),
                                    Obx(
                                      () => userController.isLoading.value
                                          ? const CircularProgressIndicator(
                                              color: kCream,
                                              backgroundColor: Colors.black26,
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: GestureDetector(
                                        onTap: () {
                                          _onProfileImageTap();
                                        },
                                        child: CircleAvatar(
                                          radius: 30,
                                          backgroundColor:
                                              Theme.of(context).primaryColor,
                                          child: const Icon(
                                            Iconsax.camera,
                                            color: kCream,
                                            size: 30,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: AnimationConfiguration.synchronized(
                  duration: const Duration(milliseconds: 500),
                  child: SlideAnimation(
                    verticalOffset: 50.0,
                    child: FadeInAnimation(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Card(
                            elevation: 8,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Personal Information',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  _buildAnimatedTextField(
                                    'First Name',
                                    _fnameController,
                                  ),
                                  _buildAnimatedTextField(
                                    'Last Name',
                                    _lnameController,
                                  ),
                                  _buildAnimatedTextField(
                                      'Phone', _phoneController,
                                      keyboardType: TextInputType.phone,
                                      maxlength: 10),
                                  _buildAnimatedTextField(
                                      'Address', _addressController,
                                      maxlength: 100),
                                  _buildAnimatedTextField(
                                      'City', _cityController),
                                  _buildAnimatedTextField(
                                      'Zipcode', _zipcodeController,
                                      maxlength: 6,
                                      keyboardType: TextInputType.number),
                                  const SizedBox(height: 20),
                                  // KYC Document Section
                                  if (authController.userData.value?.kycDocs ==
                                      null)
                                    Card(
                                      color: kCream,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      child: ListTile(
                                        leading: const Icon(
                                            Iconsax.document_upload,
                                            color: kprimaryColor,
                                            size: 24),
                                        title: const Text(
                                          'Upload KYC Document',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        subtitle: const Text(
                                          'Submit ID proof for government verification',
                                          style: TextStyle(
                                              fontSize: 14, color: Colors.grey),
                                        ),
                                        trailing: const Icon(
                                            Iconsax.arrow_right_3,
                                            color: kprimaryColor,
                                            size: 20),
                                        onTap: () =>
                                            _showKycBottomSheet(context),
                                      ),
                                    )
                                  else
                                    Card(
                                      color: Colors.green[50],
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      child: Column(
                                        children: [
                                          ListTile(
                                            leading: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.green,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Iconsax.document_text,
                                                color: kCream,
                                                size: 20,
                                              ),
                                            ),
                                            title: const Text(
                                              'KYC Document Uploaded',
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.green),
                                            ),
                                            subtitle: Text(
                                              'Document Type: ${authController.userData.value?.kycDocs?.docTypeDTitle ?? "Unknown"}\nDocument Number: ${authController.userData.value?.kycDocs?.udNumber ?? "Unknown"}',
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey),
                                            ),
                                            trailing: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                              decoration: BoxDecoration(
                                                color: Colors.green,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: const Text(
                                                'Verified',
                                                style: TextStyle(
                                                    color: kCream,
                                                    fontSize: 12,
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                          const Divider(
                                              height: 1, color: Colors.grey),
                                          ListTile(
                                            leading: const Icon(Iconsax.eye,
                                                color: kprimaryColor, size: 24),
                                            title: const Text(
                                              'View Document',
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: kprimaryColor),
                                            ),
                                            subtitle: const Text(
                                              'View your uploaded KYC document',
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey),
                                            ),
                                            trailing: const Icon(
                                                Iconsax.arrow_right_3,
                                                color: kprimaryColor,
                                                size: 20),
                                            onTap: () =>
                                                _showDocumentViewer(context),
                                          ),
                                          const Divider(
                                              height: 1, color: Colors.grey),
                                          ListTile(
                                            leading: const Icon(
                                                Iconsax.document_upload,
                                                color: kprimaryColor,
                                                size: 24),
                                            title: const Text(
                                              'Update Document',
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: kprimaryColor),
                                            ),
                                            subtitle: const Text(
                                              'Upload a new KYC document',
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey),
                                            ),
                                            trailing: const Icon(
                                                Iconsax.arrow_right_3,
                                                color: kprimaryColor,
                                                size: 20),
                                            onTap: () =>
                                                _showUpdateDocumentBottomSheet(
                                                    context),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 20),
                                  _buildUpdateButton(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // SliverList(
              //   delegate: SliverChildListDelegate(
              //     _buildSettingsItems().asMap().entries.map((entry) {
              //       final index = entry.key;
              //       final item = entry.value;
              //       return AnimationConfiguration.staggeredList(
              //         position: index,
              //         duration: const Duration(milliseconds: 500),
              //         child: SlideAnimation(
              //           horizontalOffset: 50.0,
              //           child: FadeInAnimation(child: item),
              //         ),
              //       );
              //     }).toList(),
              //   ),
              // ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildAnimatedTextField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    int? maxlength,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        maxLength: maxlength,
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return '$label is required';
          }
          if (label == 'Phone' &&
              !RegExp(r'^\+?[\d\s-]{10,}$').hasMatch(value)) {
            return 'Invalid phone number';
          }
          if (label == 'Zipcode' &&
              !RegExp(r'^\d{6}(-\d{4})?$').hasMatch(value)) {
            return 'Invalid zipcode';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildUpdateButton() {
    return Obx(() => SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: authController.isLoading.value ? null : _updateProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            child: authController.isLoading.value
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Update Profile',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ));
  }

  // Friendly empty state when there's no user (signed-out or dev-skip).
  // Tapping the CTA routes back to the auth screen so real users can sign in.
  Widget _buildSignedOutState(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Iconsax.user,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 20),
            Text(
              'Sign in to view your profile',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage bookings, KYC documents, and preferences once you’re signed in.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Get.offAllNamed('/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 14),
                shape: const StadiumBorder(),
              ),
              child: const Text('Sign in'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView(
        children: [
          Container(
            height: 240,
            color: Colors.white,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: List.generate(
                6,
                (index) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSettingsItems() {
    return [
      _buildSettingItem('Edit Profile', Icons.edit, () {
        Get.to(() => const UpdateProfileScreen());
      }),
      _buildSettingItem('Booking History', Icons.history, () {
        Get.to(() => const HistoryPage());
      }),
      _buildSettingItem('Payment Methods', Icons.payment, () {
        Get.snackbar('Info', 'Payment methods coming soon');
      }),
      _buildSettingItem('Notifications', Icons.notifications, () {
        Get.snackbar('Info', 'Notification settings coming soon');
      }),
      _buildSettingItem('Help & Support', Icons.help, () {
        try {
          Get.toNamed('/support');
        } catch (e) {
          Get.snackbar('Error', 'Failed to open support: $e');
        }
      }),
      _buildSettingItem('Logout', Icons.logout, () async {
        try {
          await authController.logout();
          Get.offAllNamed('/login');
        } catch (e) {
          Get.snackbar('Error', 'Failed to logout: $e');
        }
      }, isLogout: true),
    ];
  }

  Widget _buildSettingItem(String title, IconData icon, VoidCallback onTap,
      {bool isLogout = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: isLogout
              ? Colors.red.withOpacity(0.2)
              : Theme.of(context).primaryColor.withOpacity(0.2),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isLogout ? Colors.red : Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isLogout ? Colors.red : null,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
