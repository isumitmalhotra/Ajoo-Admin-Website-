import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:animations/animations.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/utils/input_sanitizers.dart';
import 'package:rent_home/ui/screens_renter/guest_shell.dart';
import 'package:rent_home/ui/screens_renter/negotiations/guest_negotiations_screen.dart';
import 'package:rent_home/controller/user_controller.dart';
import 'package:rent_home/ui/screens_common/about/about_page.dart';
import 'package:rent_home/ui/screens_renter/bookmark_properties/bookmark_properties_page.dart';
import 'package:rent_home/ui/screens_renter/dashboard/dashboard_screen.dart';
import 'package:rent_home/ui/screens_renter/history/history_page.dart';
import 'package:rent_home/ui/screens_renter/safety/safety_page.dart';
import 'package:rent_home/ui/widgets/email_otp_sheet.dart';
import 'package:rent_home/utils/address_autofill.dart';
import 'package:shimmer/shimmer.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../screens_common/auth/auth_controller.dart';
import '../../../controller/common_controller.dart';
import '../../../data/models/update_user_model.dart';
import '../../../data/models/user_models.dart';
import 'package:rent_home/ui/screens_host/add_property/widgets/state_city_dropdowns.dart';

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

  /// Preview-first: the tab opens on a read-only view of the saved record —
  /// same pattern as the host profile — and this flips to true only when the
  /// user explicitly asks to edit. Just checking your profile no longer means
  /// staring at an editable form.
  bool _editing = false;

  // Form controllers
  final TextEditingController _fnameController = TextEditingController();
  final TextEditingController _lnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
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
      // Server truth first: the preview must show the saved record, not
      // whatever was cached at login. skipLogout keeps a flaky refresh from
      // signing the user out of a tab they only opened to look at.
      if (authController.isLoggedIn.value) {
        authController.getUserDetails(skipLogoutOnError: true);
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to initialize profile: $e');
    }
  }

  /// Seed the edit form from the CURRENT userData. Called at edit-entry time
  /// (not once in initState) so the form always starts from the freshest
  /// fetched record — a form seeded from stale or missing data and then
  /// saved is a data-wipe machine.
  void _seedControllersFromUser() {
    final userData = authController.userData.value;
    if (userData == null) return;
    // Everything after the first word is the last name — "Anna Maria Jose"
    // must not lose its middle on a round-trip through this form.
    final names = userData.fullName.trim().split(RegExp(r'\s+'));
    _fnameController.text = names.isNotEmpty ? names.first : '';
    _lnameController.text = names.length > 1 ? names.sublist(1).join(' ') : '';
    _phoneController.text = userData.phoneNumber;
    _addressController.text = userData.address;
    _cityController.text = userData.city;
    _stateController.text = userData.state;
    _zipcodeController.text = userData.zipcode;
  }

  void _enterEditMode() {
    if (authController.userData.value == null) return;
    _seedControllersFromUser();
    setState(() => _editing = true);
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

  /// A-66 — redo identity verification from the profile.
  ///
  /// Goes through DIDIT, the same check that verified the user in the first
  /// place, with force set so the server does not skip it for someone who is
  /// already verified. Refreshes the profile afterwards so the badge and the
  /// document details reflect the new decision rather than the old one.
  Future<void> _reRunKyc() async {
    await Get.toNamed('/kyc', arguments: {
      'context': 'renter_kyc',
      'isHost': false,
      'returnResult': true,
      'force': true,
    });
    await authController.getUserDetails(skipLogoutOnError: true);
    if (mounted) setState(() {});
  }

  /// A-67 — fill the address without typing it.
  ///
  /// Two ways in, because they fail in different situations: GPS is precise
  /// but needs permission and a fix, a PIN code works indoors and offline of
  /// GPS but only determines the city. Neither overwrites a field the lookup
  /// had nothing for.
  bool _autofillBusy = false;

  Future<void> _autofillFromLocation() async {
    if (_autofillBusy) return;
    setState(() => _autofillBusy = true);
    final res = await addressFromCurrentLocation();
    if (!mounted) return;
    setState(() {
      _autofillBusy = false;
      final p = res.parts;
      if (p != null) {
        if (p.address.trim().isNotEmpty) _addressController.text = p.address;
        if (p.city.trim().isNotEmpty) _cityController.text = p.city;
        if (p.state.trim().isNotEmpty) _stateController.text = p.state;
        if (p.postalCode.trim().isNotEmpty) {
          _zipcodeController.text = p.postalCode;
        }
      }
    });
    if (!res.ok) {
      Get.snackbar('Location', addressLookupMessage(res.error));
    }
  }

  Future<void> _autofillFromZip() async {
    if (_autofillBusy) return;
    final pin = _zipcodeController.text.trim();
    if (pin.length < 6) {
      Get.snackbar('PIN code', 'Enter a 6-digit PIN code first.');
      return;
    }
    setState(() => _autofillBusy = true);
    final res = await addressFromPostalCode(pin);
    if (!mounted) return;
    setState(() {
      _autofillBusy = false;
      final p = res.parts;
      // A PIN determines the city, not the street — the address field is
      // left exactly as the user had it.
      if (p != null && p.city.trim().isNotEmpty) _cityController.text = p.city;
      if (p != null && p.state.trim().isNotEmpty) _stateController.text = p.state;
    });
    if (!res.ok) {
      Get.snackbar('PIN code', addressLookupMessage(res.error));
    }
  }

  Widget _buildAddressAutofill() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _autofillBusy ? null : _autofillFromLocation,
              icon: _autofillBusy
                  ? const SizedBox(
                      height: 15,
                      width: 15,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: kIndigo))
                  : const Icon(Icons.my_location, size: 17),
              label: const Text('Use my location',
                  overflow: TextOverflow.ellipsis),
              style: OutlinedButton.styleFrom(
                foregroundColor: kIndigo600,
                side: const BorderSide(color: kLine),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _autofillBusy ? null : _autofillFromZip,
              icon: const Icon(Icons.pin_drop_outlined, size: 17),
              label: const Text('Fill from PIN',
                  overflow: TextOverflow.ellipsis),
              style: OutlinedButton.styleFrom(
                foregroundColor: kIndigo600,
                side: const BorderSide(color: kLine),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
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

      // Changing the phone is a sensitive change: the server emails a
      // one-time code to the account's registered address and refuses the
      // new number without it. An unchanged phone saves exactly as before.
      final currentPhone =
          (authController.userData.value?.phoneNumber ?? '').trim();
      final newPhone = _phoneController.text.trim();
      String? otp;
      if (newPhone != currentPhone) {
        final sent =
            await authController.authService.requestSecurityOtp('phone');
        if (!sent.success) {
          Get.snackbar('Error', sent.message,
              snackPosition: SnackPosition.TOP,
              backgroundColor: Colors.red[100],
              colorText: Colors.red[900]);
          return;
        }
        otp = await showEmailOtpSheet(
          email: authController.userData.value?.email ?? 'your email',
          title: 'Confirm your new number',
          resend: () => authController.authService.requestSecurityOtp('phone'),
        );
        // Backing out of the code sheet abandons the save — nothing changes.
        if (otp == null) return;
      }

      final request = UserUpdateRequest(
        userFname: _fnameController.text.trim(),
        userLname: _lnameController.text.trim(),
        userPnumber: newPhone,
        userAddress: _addressController.text.trim(),
        userCity: _cityController.text.trim(),
        userState: _stateController.text.trim(),
        userZipcode: _zipcodeController.text.trim(),
        docType: docTypeIdToSend,
        docNumber: docNumberToSend,
        otp: otp,
      );

      final result = await authController.updateUserProfile(request);

      if (result.isSuccess) {
        // Back to the read-only view showing the freshly saved record
        // (updateUserProfile refetched /user/detail already).
        if (mounted) setState(() => _editing = false);
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
      _stateController.dispose();
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
        // A back arrow only when there is something to go back to. As the
        // shell's Profile tab this is a root route, so the arrow was drawn but
        // maybePop had nothing to pop — a control that visibly did nothing.
        automaticallyImplyLeading: false,
        leading: (GuestShellScope.maybeOf(context) == null &&
                Navigator.of(context).canPop())
            ? const BackButton(color: Colors.white)
            : null,
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
          // Signed in but the fetch failed and nothing is cached: say so and
          // offer a retry, rather than pretending the account is empty.
          if (authController.isLoggedIn.value &&
              authController.error.value.isNotEmpty) {
            return _buildErrorState(context);
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
                        child: _editing
                            ? _buildEditCard()
                            : _buildPreviewCard(user),
                      ),
                    ),
                  ),
                ),
              ),
              // Account actions. This list was commented out during the
              // redesign and never restored, which took Logout with it — and
              // the bottom-nav shell dropped the drawer that used to hold the
              // other copy. A signed-in renter had no way to sign out of the
              // app at all.
              //
              // Hidden while editing — a form with Save/Cancel should not sit
              // above ten unrelated navigation rows.
              if (!_editing)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(
                    _buildSettingsItems().asMap().entries.map((entry) {
                      return AnimationConfiguration.staggeredList(
                        position: entry.key,
                        duration: const Duration(milliseconds: 500),
                        child: SlideAnimation(
                          horizontalOffset: 50.0,
                          child: FadeInAnimation(child: entry.value),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  /// Read-only view of the saved record — what "just checking my profile"
  /// shows. Values come straight from the fetched userData, never from the
  /// form controllers, so it can't display half-edited state.
  Widget _buildPreviewCard(UserDetail user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          elevation: 8,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Personal Information',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (user.isKycVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: kSuccess,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, color: kCream, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Verified',
                              style: TextStyle(
                                  color: kCream,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _previewRow(Icons.person_outline, 'Name', user.fullName),
                _previewRow(Icons.email_outlined, 'Email', user.email),
                _previewRow(Icons.phone_outlined, 'Phone', user.phoneNumber),
                _previewRow(Icons.map_outlined, 'State', user.state),
                _previewRow(
                    Icons.location_city_outlined, 'City', user.city),
                _previewRow(Icons.home_outlined, 'Address', user.address),
                _previewRow(Icons.markunread_mailbox_outlined, 'PIN code',
                    user.zipcode),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _enterEditMode,
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text(
                      'Edit Profile',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildKycSection(),
      ],
    );
  }

  Widget _previewRow(IconData icon, String label, String value) {
    final trimmed = value.trim();
    final missing = trimmed.isEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: kIndigo600),
          const SizedBox(width: 12),
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 13, color: kMuted, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              missing ? 'Not added yet' : trimmed,
              style: TextStyle(
                fontSize: 14,
                fontWeight: missing ? FontWeight.w400 : FontWeight.w600,
                fontStyle: missing ? FontStyle.italic : FontStyle.normal,
                color: missing ? kMuted : kInk,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The editable form — reached only through "Edit Profile", seeded from a
  /// successfully fetched record just before it opens.
  Widget _buildEditCard() {
    return Form(
      key: _formKey,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Edit Profile',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton(
                    // Discards the draft; the preview still shows the saved
                    // record, and re-entering edit re-seeds from it.
                    onPressed: authController.isLoading.value
                        ? null
                        : () => setState(() => _editing = false),
                    child: const Text('Cancel',
                        style: TextStyle(color: kMuted)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildAnimatedTextField(
                'First Name',
                _fnameController,
                inputFormatters: AppInputFormatters.name,
              ),
              _buildAnimatedTextField(
                'Last Name',
                _lnameController,
                inputFormatters: AppInputFormatters.name,
              ),
              _buildAnimatedTextField('Phone', _phoneController,
                  keyboardType: TextInputType.phone,
                  maxlength: 10,
                  inputFormatters: AppInputFormatters.mobile),
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  "Changing your mobile number? We'll email a code to your "
                  'registered address to confirm it.',
                  style: TextStyle(fontSize: 12, color: kMuted),
                ),
              ),
              _buildAddressAutofill(),
              _buildAnimatedTextField('Address', _addressController,
                  maxlength: 100),
              // Same reference-table dropdowns as the listing wizard — this
              // screen had a lone free-text City with no state at all.
              StateCityDropdowns(
                stateController: _stateController,
                cityController: _cityController,
              ),
              _buildAnimatedTextField('Zipcode', _zipcodeController,
                  maxlength: 6,
                  keyboardType: TextInputType.number,
                  inputFormatters: AppInputFormatters.pincode),
              const SizedBox(height: 20),
              _buildUpdateButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// KYC section (preview only).
  ///
  /// A-82 removed the identity check from signup, so this is now the only
  /// place a renter can verify ahead of time rather than being stopped at
  /// checkout. It runs DIDIT — the same check the booking gate runs —
  /// instead of the legacy manual upload, which produced a document nothing
  /// verified.
  Widget _buildKycSection() {
    if (authController.userData.value?.kycDocs == null) {
      return Card(
        color: kCream,
        elevation: 0,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: const Icon(Icons.verified_user_outlined,
              color: kprimaryColor, size: 24),
          title: const Text(
            'Verify your identity',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          subtitle: const Text(
            'Do it now and checkout stays instant later',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          trailing: const Icon(Iconsax.arrow_right_3,
              color: kprimaryColor, size: 20),
          onTap: _reRunKyc,
        ),
      );
    }
    return Card(
      color: Colors.green[50],
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(8),
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
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            // This chip said "Verified" for anyone who had uploaded a file.
            // Uploading a document is not being verified — it reads the
            // DIDIT decision, and says "Under review" until there is one.
            trailing: Builder(builder: (_) {
              final verified =
                  authController.userData.value?.isKycVerified ?? false;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: verified ? Colors.green : kClay,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  verified ? 'Verified' : 'Under review',
                  style: const TextStyle(
                      color: kCream,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              );
            }),
          ),
          const Divider(height: 1, color: Colors.grey),
          ListTile(
            leading: const Icon(Iconsax.eye, color: kprimaryColor, size: 24),
            title: const Text(
              'View Document',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kprimaryColor),
            ),
            subtitle: const Text(
              'View your uploaded KYC document',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            trailing: const Icon(Iconsax.arrow_right_3,
                color: kprimaryColor, size: 20),
            onTap: () => _showDocumentViewer(context),
          ),
          const Divider(height: 1, color: Colors.grey),
          ListTile(
            leading: const Icon(Iconsax.document_upload,
                color: kprimaryColor, size: 24),
            title: const Text(
              'Update documents',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kprimaryColor),
            ),
            subtitle: const Text(
              'Verify your identity again with a new document',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            trailing: const Icon(Iconsax.arrow_right_3,
                color: kprimaryColor, size: 20),
            // Runs DIDIT again rather than the manual upload sheet (A-66) —
            // a new document must go through the same check that verified
            // the first one.
            onTap: _reRunKyc,
          ),
        ],
      ),
    );
  }

  /// Signed in, fetch failed, nothing cached: an honest error with a retry,
  /// never blank editable fields.
  Widget _buildErrorState(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                "Couldn't load your profile",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w600, color: kInk),
              ),
              const SizedBox(height: 8),
              Text(
                authController.error.value,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: kMuted),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () =>
                    authController.getUserDetails(skipLogoutOnError: true),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Try again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kIndigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 12),
                  shape: const StadiumBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedTextField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    int? maxlength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        maxLength: maxlength,
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        // Matches the web's field treatment: a filled warm surface with a
        // quiet border, and teal only on focus. A full-strength teal outline
        // on every field at rest made the form read as eight things all
        // demanding attention at once.
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: kCream,
          // The "10/10" and "53/100" counters were pure noise on a profile
          // form; the limit is still enforced.
          counterText: '',
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kLine),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kLine),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kIndigo, width: 1.6),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kDanger),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kDanger, width: 1.6),
          ),
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

  /// Every page the app has, in one place (A-64).
  ///
  /// These used to be split between here and a right-hand drawer opened by
  /// tapping the logo on the home screen — an unmarked target, so Dashboard,
  /// Bookmarks, Safety, Settings and About were reachable only by guessing.
  /// The drawer is gone; this is the menu.
  List<Widget> _buildSettingsItems() {
    return [
      // Flips this same screen into edit mode (seeded from the fetched
      // record) instead of pushing the legacy UpdateProfileScreen — one edit
      // surface, one save pipeline.
      _buildSettingItem('Edit Profile', Icons.edit, _enterEditMode),
      _buildSettingItem('Dashboard', Icons.dashboard_outlined, () {
        Get.to(() => const RenterDashboardScreen());
      }),
      _buildSettingItem('Booking History', Icons.history, () {
        Get.to(() => const HistoryPage());
      }),
      _buildSettingItem('Bookmarks', Icons.bookmark_border, () {
        Get.to(() => const BookmarkedPropertiesPage());
      }),
      // The guest half of the product's whole point. There was no entry
      // anywhere in the app, so an offer once sent vanished from the guest's
      // view — including a host's counter.
      _buildSettingItem('My Negotiations', Icons.handshake_outlined, () {
        Get.to(() => const GuestNegotiationsScreen());
      }),
      // "Payment Methods" lived here and only raised a "coming soon"
      // snackbar. A row that answers nothing is worse than no row — it is out
      // until there is a screen behind it.
      _buildSettingItem('Notifications', Icons.notifications, () {
        Get.toNamed('/notifications');
      }),
      _buildSettingItem('Safety', Icons.security, () {
        Get.to(() => const SafetyPage());
      }),
      _buildSettingItem('Settings', Icons.settings, () {
        Get.toNamed('/settings');
      }),
      _buildSettingItem('Help & Support', Icons.help, () {
        try {
          Get.toNamed('/support');
        } catch (e) {
          Get.snackbar('Error', 'Failed to open support: $e');
        }
      }),
      _buildSettingItem('About', Icons.info_outline, () {
        Get.to(() => const AboutPage());
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
