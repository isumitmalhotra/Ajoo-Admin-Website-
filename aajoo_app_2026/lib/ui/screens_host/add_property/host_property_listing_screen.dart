import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/controller/common_controller.dart';
import 'package:rent_home/ui/screens_common/auth/auth_controller.dart';
import 'package:rent_home/ui/screens_common/location_picker/pick_location_screen.dart';
import 'package:rent_home/ui/screens_host/add_property/document_upload_section.dart';
import 'package:rent_home/ui/screens_host/add_property/new_property_controller_legacy.dart';
import 'package:rent_home/ui/screens_host/add_property/property_image_picker.dart';
import 'package:rent_home/ui/screens_host/host_controller.dart';
import 'package:rent_home/ui/screens_host/host_tab_provider.dart';

import 'widgets/property_form_widgets.dart';
import 'package:rent_home/widgets/app_ui.dart' show AppCard;

import 'widgets/terms_bottom_sheet.dart';

class HostPropertyListingScreen extends StatefulWidget {
  const HostPropertyListingScreen({super.key});

  @override
  State<HostPropertyListingScreen> createState() =>
      _HostPropertyListingScreenState();
}

class _HostPropertyListingScreenState extends State<HostPropertyListingScreen> {
  // ── Form ──────────────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();

  // ── Controllers ───────────────────────────────────────────────────────────
  final _propertyNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _exactPriceController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();
  final _weeklyMinPriceController = TextEditingController();
  final _weeklyMaxPriceController = TextEditingController();
  final _monthlySecurityAmountController = TextEditingController();
  final _monthlyMaxPriceController = TextEditingController();
  final _monthlyMinPriceController = TextEditingController();
  final _houseRulesController = TextEditingController();
  final _numberOfBedsController = TextEditingController();
  final _numberOfGuestsController = TextEditingController();

  // ── H1 parity controllers (new wizard fields) ──────────────────────────────
  final _areaLocalityController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _floorNoController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _quietHoursController = TextEditingController();
  final _securityDepositController = TextEditingController();
  final _weekendPriceController = TextEditingController();
  final _cleaningFeeController = TextEditingController();
  final _extraGuestChargeController = TextEditingController();
  final _minBookingAmountController = TextEditingController();
  // PG sub-form
  final _pgMonthlyRentController = TextEditingController();
  final _pgDepositController = TextEditingController();
  final _pgLockInController = TextEditingController();
  final _pgCurfewController = TextEditingController();
  final _pgVisitorPolicyController = TextEditingController();
  // Party sub-form
  final _partyMaxPeopleController = TextEditingController();
  final _partyChargesController = TextEditingController();
  final _partyEndTimeController = TextEditingController();

  // H1 selections / toggles
  String _bookingPref = 'request'; // instant | request
  String? _ownershipType; // owned | leased | managed
  String? _pgRoomType; // single | double | triple | dorm
  String? _pgGenderPref; // male | female | any
  bool _coupleFriendly = false;
  bool _localIdAllowed = false;
  bool _pgFoodIncluded = false;
  bool _partyLoudMusic = false;

  // ── GetX ──────────────────────────────────────────────────────────────────
  final newPropertyController = Get.put(NewPropertyController());
  final authController = Get.find<AuthController>();
  final commonController = Get.find<CommonController>();

  // ── State ─────────────────────────────────────────────────────────────────
  List<XFile> images = [];
  List<String> amenities = []; // selected amenity labels (for the JSON)
  final Set<int> _selectedAmenityIds = {}; // admin amenity IDs
  final Set<int> _selectedTagIds = {}; // admin tag IDs
  List<String> hotelTypes = [];
  List<String> tempSelected = [];
  TimeOfDay? checkInTime;
  TimeOfDay? checkOutTime;
  bool isPetFriendly = false;
  bool isSmokingAllowed = false;
  bool isSharingSelected = false;
  bool isPartySelected = false;
  bool termsAccepted = false;

  // ── Wizard ────────────────────────────────────────────────────────────────
  // All steps stay mounted in an IndexedStack, so the single Form validates
  // every field and all TextEditingControllers persist across steps.
  int _step = 0;
  static const List<String> _stepNames = [
    'Property Type',
    'Location',
    'Photos',
    'Pricing',
    'Preferences',
    'Publish',
  ];

  // First step (in order) whose required inputs are still missing — used to
  // jump the user to the problem when publish-time validation fails.
  int _firstInvalidStep() {
    if (_propertyNameController.text.trim().isEmpty || tempSelected.isEmpty) {
      return 0;
    }
    if (_addressController.text.trim().isEmpty ||
        _cityController.text.trim().isEmpty ||
        _stateController.text.trim().isEmpty ||
        _countryController.text.trim().isEmpty ||
        _zipCodeController.text.trim().isEmpty) {
      return 1;
    }
    if (images.length < 2) return 2;
    if (_descriptionController.text.trim().isEmpty ||
        _exactPriceController.text.trim().isEmpty ||
        _minPriceController.text.trim().isEmpty) {
      return 3;
    }
    if (_contactController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty) {
      return 5;
    }
    return _step;
  }

  // ── Documents ─────────────────────────────────────────────────────────────
  XFile? fireAndSafetyNOC;
  XFile? jamaBandhiDoc;
  XFile? partyLicenseDoc;
  XFile? nocDocument;
  XFile? policeVerificationDoc;

  // ── Computed ──────────────────────────────────────────────────────────────
  int get _docsCount =>
      (fireAndSafetyNOC != null ? 1 : 0) +
      (jamaBandhiDoc != null ? 1 : 0) +
      (nocDocument != null ? 1 : 0) +
      (policeVerificationDoc != null ? 1 : 0);

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    hotelTypes = commonController.cats.value?.data.categories
            .map((e) => e.catTitle)
            .toList() ??
        [];
    hotelTypes.removeWhere((t) => t.toLowerCase() == 'apartment');
    hotelTypes.add('Family');

    final user = authController.userData.value;
    _emailController.text = user?.email ?? '';
    _contactController.text = user?.phoneNumber ?? '';

    _houseRulesController.addListener(() => setState(() {}));
    _stateController.addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ever(newPropertyController.latitude, (_) => _onLocationChanged());
  }

  @override
  void dispose() {
    _houseRulesController.dispose();
    _stateController.dispose();
    _areaLocalityController.dispose();
    _landmarkController.dispose();
    _floorNoController.dispose();
    _bathroomsController.dispose();
    _videoUrlController.dispose();
    _quietHoursController.dispose();
    _securityDepositController.dispose();
    _weekendPriceController.dispose();
    _cleaningFeeController.dispose();
    _extraGuestChargeController.dispose();
    _minBookingAmountController.dispose();
    _pgMonthlyRentController.dispose();
    _pgDepositController.dispose();
    _pgLockInController.dispose();
    _pgCurfewController.dispose();
    _pgVisitorPolicyController.dispose();
    _partyMaxPeopleController.dispose();
    _partyChargesController.dispose();
    _partyEndTimeController.dispose();
    super.dispose();
  }

  // ── Location ──────────────────────────────────────────────────────────────

  Future<void> _onLocationChanged() async {
    final lat = newPropertyController.latitude.value;
    final lng = newPropertyController.longitude.value;
    if (lat == 0.0 || lng == 0.0) return;
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return;
      final place = placemarks.first;
      setState(() {
        _addressController.text =
            '${place.street ?? ''}, ${place.subLocality ?? ''}'.trim();
        _cityController.text = place.locality ?? '';
        _stateController.text = place.administrativeArea ?? '';
        _countryController.text = place.country ?? '';
        _zipCodeController.text = place.postalCode ?? '';
      });
    } catch (_) {}
  }

  // ── Document picking ──────────────────────────────────────────────────────

  Future<void> _pickDocument(String documentType) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() {
      switch (documentType) {
        case 'fireAndSafety':
          fireAndSafetyNOC = picked;
          break;
        case 'jamaBandhi':
          jamaBandhiDoc = picked;
          break;
        case 'noc':
          nocDocument = picked;
          break;
        case 'partyLicense':
          partyLicenseDoc = picked;
          break;
        case 'policeVerification':
          policeVerificationDoc = picked;
          break;
      }
    });
    _showSnackBar('$documentType document selected', isError: false);
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _saveProperty() async {
    final hostController = Get.put(HostController());
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please complete all required fields', isError: true);
      setState(() => _step = _firstInvalidStep());
      return;
    }

    if (images.length < 2) {
      _showSnackBar('Please upload at least 2 photos of your property',
          isError: true);
      setState(() => _step = 2);
      return;
    }
    if (_docsCount < 3) {
      _showSnackBar('Please upload at least 3 property documents',
          isError: true);
      setState(() => _step = 5);
      return;
    }

    if (isPartySelected && partyLicenseDoc == null) {
      _showSnackBar(
          'Please upload the Party License document for party properties',
          isError: true);
      return;
    }

    // Map UI → controller
    newPropertyController
      ..propertyName.value = _propertyNameController.text
      ..propertyDescription.value = _descriptionController.text
      ..address.value = _addressController.text
      ..price.value = _exactPriceController.text
      ..minPrice.value = _minPriceController.text
      ..city.value = _cityController.text
      ..state.value = _stateController.text
      ..country.value = _countryController.text
      ..pincode.value = _zipCodeController.text
      ..amenities.value = amenities
      ..amenityIds.value = _selectedAmenityIds.toList()
      ..tagIds.value = _selectedTagIds.toList()
      ..inTime.value = checkInTime?.format(context) ?? ''
      ..outTime.value = checkOutTime?.format(context) ?? ''
      ..contact.value = _contactController.text
      ..email.value = _emailController.text
      ..isPetAllowed.value = isPetFriendly ? 1 : 0
      ..isSmokingAllowed.value = isSmokingAllowed ? 1 : 0
      ..numberOfBeds.value = int.tryParse(_numberOfBedsController.text) ?? 0
      ..numberOfGuests.value = int.tryParse(_numberOfGuestsController.text) ?? 0
      ..image.value = images.map((e) => File(e.path)).toList()
      ..weeklyMinPrice.value = _weeklyMinPriceController.text.isEmpty
          ? '0'
          : _weeklyMinPriceController.text
      ..weeklyMaxPrice.value = _weeklyMaxPriceController.text.isEmpty
          ? '0'
          : _weeklyMaxPriceController.text
      ..monthlySecurityAmount.value =
          _monthlySecurityAmountController.text.isEmpty
              ? '0'
              : _monthlySecurityAmountController.text
      ..propRule.value = _parseHouseRules(_houseRulesController.text)
      // ---- H1 parity fields ----
      ..propertyType.value = tempSelected.join(', ')
      // Map selected type chips (category titles) → category IDs for linking.
      ..categoryIds.value = (commonController.cats.value?.data.categories ?? [])
          .where((c) => tempSelected
              .any((t) => t.toLowerCase() == c.catTitle.toLowerCase()))
          .map((c) => c.catId)
          .toList()
      ..bookingPref.value = _bookingPref
      ..ownershipType.value = _ownershipType ?? ''
      ..areaLocality.value = _areaLocalityController.text
      ..landmark.value = _landmarkController.text
      ..floorNo.value = _floorNoController.text
      ..bathrooms.value = _bathroomsController.text
      ..videoUrl.value = _videoUrlController.text
      ..quietHours.value = _quietHoursController.text
      ..securityDeposit.value = _securityDepositController.text
      ..weekendPrice.value = _weekendPriceController.text
      ..cleaningFee.value = _cleaningFeeController.text
      ..extraGuestCharge.value = _extraGuestChargeController.text
      ..minBookingAmount.value = _minBookingAmountController.text
      ..coupleFriendly.value = _coupleFriendly
      ..localIdAllowed.value = _localIdAllowed
      ..selfDeclaration.value = termsAccepted
      // PG sub-form
      ..isPgSelected.value = isSharingSelected
      ..pgRoomType.value = _pgRoomType ?? ''
      ..pgGenderPref.value = _pgGenderPref ?? ''
      ..pgMonthlyRent.value = _pgMonthlyRentController.text
      ..pgDeposit.value = _pgDepositController.text
      ..pgLockInMonths.value = _pgLockInController.text
      ..pgCurfew.value = _pgCurfewController.text
      ..pgVisitorPolicy.value = _pgVisitorPolicyController.text
      ..pgFoodIncluded.value = _pgFoodIncluded
      // Party sub-form
      ..isPartySelected.value = isPartySelected
      ..partyMaxPeople.value = _partyMaxPeopleController.text
      ..partyCharges.value = _partyChargesController.text
      ..partyEndTime.value = _partyEndTimeController.text
      ..partyLoudMusic.value = _partyLoudMusic;

    if (fireAndSafetyNOC != null) {
      newPropertyController.fireAndSafetyNOC.value =
          File(fireAndSafetyNOC!.path);
    }
    if (jamaBandhiDoc != null) {
      newPropertyController.jamaBandhiDoc.value = File(jamaBandhiDoc!.path);
    }
    if (nocDocument != null) {
      newPropertyController.nocDocument.value = File(nocDocument!.path);
    }
    if (policeVerificationDoc != null) {
      newPropertyController.policeVerificationDoc.value =
          File(policeVerificationDoc!.path);
    }

    if (isPartySelected && partyLicenseDoc != null) {
      newPropertyController.partyLicenseDoc.value = File(partyLicenseDoc!.path);
    } else {
      newPropertyController.partyLicenseDoc.value = null;
    }

    final result = await newPropertyController.saveProperty();
    hostController.getHostProperties();

    final user = authController.userData.value;
    if (user != null) hostController.getHostOngoing(user.userId);

    if (!mounted) return;

    if (result.isSuccess) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Success'),
          content: Text(result.message ?? ''),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).pop();
                context.read<HostTabProvider>().resetToHome();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      _showSnackBar(result.message ?? 'Error', isError: true);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _parseHouseRules(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '';
    return trimmed
        .split('.')
        .map((r) => r.trim())
        .where((r) => r.isNotEmpty)
        .join(', ');
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: const TextStyle(color: Colors.white)),
      backgroundColor: isError ? kDanger : kSuccess,
      duration: const Duration(seconds: 3),
    ));
  }

  void _showTermsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TermsBottomSheet(
        onAgreed: () => setState(() => termsAccepted = true),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  /// The system back button, made to behave like the arrow in the app bar.
  ///
  /// There was no guard at all: a back press or edge swipe at any step popped
  /// the whole six-step wizard and threw away everything typed, with no
  /// warning. On step 2 of 6 that is a lot of a host's work gone to a gesture
  /// they did not mean. Back now walks a step at a time, and leaving from the
  /// first step asks first if anything has been entered.
  Future<void> _handleSystemBack() async {
    if (_step > 0) {
      setState(() => _step--);
      return;
    }
    if (!_hasAnyInput()) {
      if (mounted) Navigator.pop(context);
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard this listing?'),
        content: const Text(
            'What you have entered so far will be lost. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: kDanger),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.pop(context);
  }

  /// Has the host actually put anything in? Used so an immediate back press on
  /// an untouched form does not nag.
  bool _hasAnyInput() =>
      _propertyNameController.text.trim().isNotEmpty || tempSelected.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _handleSystemBack();
      },
      child: Scaffold(
      backgroundColor: kscaffoldColor,
      appBar: AppBar(
        backgroundColor: kSurface,
        foregroundColor: kInk,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              _step == 0 ? Navigator.pop(context) : setState(() => _step--),
        ),
        title: Text('List Your Property',
            style:
                fraunces(fontSize: 17, fontWeight: FontWeight.w700, color: kInk)),
      ),
      // One Form wraps every step; the IndexedStack keeps them all mounted so
      // validation + controllers behave exactly like the old single-page form.
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          children: [
            _progressBar(),
            Expanded(
              child: IndexedStack(
                index: _step,
                sizing: StackFit.expand,
                children:
                    List.generate(_stepNames.length, (i) => _stepBody(i)),
              ),
            ),
            _footer(theme),
          ],
        ),
      ),
      ),
    );
  }

  Widget _progressBar() {
    return Container(
      color: kSurface,
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (int i = 0; i < _stepNames.length; i++) ...[
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= _step ? kIndigo : kLine,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (i < _stepNames.length - 1) const SizedBox(width: 4),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
              'Step ${_step + 1} of ${_stepNames.length} · ${_stepNames[_step]}',
              style: inter(
                  fontSize: 12, fontWeight: FontWeight.w600, color: kMuted)),
        ],
      ),
    );
  }

  // Groups the (unchanged) section builders into wizard steps.
  Widget _stepBody(int i) {
    List<Widget> children;
    switch (i) {
      case 0:
        children = [
          AppCard(child: _buildBasicDetailsSection()),
          const SizedBox(height: 14),
          AppCard(child: _buildLuxurySection()),
        ];
        break;
      case 1:
        children = [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Location'),
                const SizedBox(height: 10),
                _buildLocationButton(),
                const SizedBox(height: 12),
                _buildAddressFields(),
              ],
            ),
          ),
        ];
        break;
      case 2:
        children = [AppCard(child: _buildImagesSection())];
        break;
      case 3:
        children = [
          AppCard(child: _buildDescriptionSection()),
          const SizedBox(height: 14),
          AppCard(child: _buildPricingSection()),
          const SizedBox(height: 14),
          AppCard(child: _buildAdditionalChargesSection()),
          const SizedBox(height: 14),
          AppCard(child: _buildListingDetailsSection()),
        ];
        break;
      case 4:
        children = [
          AppCard(child: _buildStayPreferencesSection()),
          const SizedBox(height: 14),
          if (isSharingSelected) ...[
            AppCard(child: _buildPgSection()),
            const SizedBox(height: 14),
          ],
          if (isPartySelected) ...[
            AppCard(child: _buildPartyExtrasSection()),
            const SizedBox(height: 14),
          ],
          AppCard(child: _buildAmenitiesSection()),
          const SizedBox(height: 14),
          AppCard(child: _buildTagsSection()),
          const SizedBox(height: 14),
          AppCard(child: _buildPoliciesSection()),
          const SizedBox(height: 14),
          AppCard(child: _buildHouseRulesSection()),
        ];
        break;
      default:
        children = [
          AppCard(child: _buildDocumentsSection()),
          const SizedBox(height: 14),
          AppCard(child: _buildContactSection()),
          const SizedBox(height: 14),
          AppCard(child: _buildTermsSection()),
        ];
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _footer(ThemeData theme) {
    final isLast = _step == _stepNames.length - 1;
    return Container(
      decoration: BoxDecoration(
        color: kSurface,
        boxShadow: [
          BoxShadow(
              color: kInk.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -4)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SafeArea(
        top: false,
        // On the last step reuse the existing submit button (Obx loading +
        // terms check + _saveProperty) verbatim; otherwise a Continue button.
        child: isLast
            ? _buildSubmitButton(theme)
            : SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => setState(() => _step++),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kIndigo,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const StadiumBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Continue',
                          style: inter(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ── Section builders ──────────────────────────────────────────────────────

  Widget _buildLuxurySection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const SectionTitle('Luxury Property'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.06),
              border: Border.all(color: Colors.amber.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.star_rounded, color: Colors.amber, size: 24),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('What counts as Luxury?',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87)),
                      SizedBox(height: 6),
                      Text(
                        'Luxury listings typically include premium finishes, exceptional amenities (like pool, gym, concierge), prime locations, and superior guest experience.',
                        style: TextStyle(fontSize: 13, height: 1.35),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Obx(() => SwitchListTile(
                title: const Text('Mark as Luxury'),
                subtitle: const Text(
                    'Toggle on if this property meets luxury standards.'),
                value: newPropertyController.isLuxury.value,
                activeColor: Colors.amber[800],
                onChanged: (val) => newPropertyController.isLuxury.value = val,
              )),
        ],
      );

  Widget _buildImagesSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Property Images (Minimum 2 required, up to 6)'),
          PropertyImagePicker(
            images: images,
            onChanged: (updated) => setState(() => images = updated),
          ),
        ],
      );

  Widget _buildBasicDetailsSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Basic Property Details'),
          PropertyTextField(
              _propertyNameController, 'Property Name', Icons.business),
          const Text('Property Type',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildPropertyTypeChips(),
          const SizedBox(height: 8),
          if (isSharingSelected) ...[
            const Text('Sharing Property Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            PropertyTextField(
                _numberOfBedsController, 'Beds Available', Icons.bed,
                isNumeric: true),
          ],
          if (isPartySelected) ...[
            const Text('Party Property Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            PropertyTextField(_numberOfGuestsController,
                'Number of Guests (Party)', Icons.people,
                isNumeric: true),
          ],
          const SizedBox(height: 8),
        ],
      );
  Widget _buildPropertyTypeChips() => Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: hotelTypes.map((item) {
          final selected = tempSelected.contains(item);
          return ChoiceChip(
            label: Text(item.capitalize!),
            selected: selected,
            onSelected: (_) => setState(() {
              final isSharing = item.toLowerCase() == 'sharing';
              final isParty = item.toLowerCase() == 'party';

              if (selected) {
                // Deselect current item
                tempSelected.remove(item);
              } else {
                if (isSharing) {
                  // Selecting sharing → clear everything else
                  tempSelected.clear();
                  tempSelected.add(item);
                  _numberOfGuestsController.clear();
                } else if (isParty) {
                  // Selecting party → clear everything else
                  tempSelected.clear();
                  tempSelected.add(item);
                  _numberOfBedsController.clear();
                } else {
                  // Normal type selected → just remove sharing & party if present
                  tempSelected.remove('sharing');
                  tempSelected.remove('Sharing');
                  tempSelected.remove('party');
                  tempSelected.remove('Party');
                  tempSelected.add(item);
                  _numberOfBedsController.clear();
                  _numberOfGuestsController.clear();
                }
              }

              // Update flags
              isSharingSelected =
                  tempSelected.any((t) => t.toLowerCase() == 'sharing');
              isPartySelected =
                  tempSelected.any((t) => t.toLowerCase() == 'party');
            }),
            selectedColor: kprimaryColor,
            backgroundColor: kSand,
            labelStyle: TextStyle(
              color: selected ? kCream : kInk,
            ),
          );
        }).toList(),
      );
  // Widget _buildPropertyTypeChips() => Wrap(
  //       spacing: 8.0,
  //       runSpacing: 8.0,
  //       children: hotelTypes.map((item) {
  //         final selected = tempSelected.contains(item);
  //         return ChoiceChip(
  //           label: Text(item.capitalize!),
  //           selected: selected,
  //           onSelected: (_) => setState(() {
  //             selected ? tempSelected.remove(item) : tempSelected.add(item);
  //             isSharingSelected = tempSelected.contains('sharing');
  //             isPartySelected = tempSelected.contains('party');
  //             if (!isSharingSelected) _numberOfBedsController.clear();
  //             if (!isPartySelected) _numberOfGuestsController.clear();
  //           }),
  //           selectedColor: kprimaryColor,
  //           backgroundColor: Colors.grey.shade200,
  //           labelStyle:
  //               TextStyle(color: selected ? Colors.white : Colors.black87),
  //         );
  //       }).toList(),
  //     );

  Widget _buildLocationButton() => Column(
        children: [
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PickLocationScreen()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: kSand,
              foregroundColor: kInk,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0)),
              minimumSize: const Size(double.infinity, 50),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Obx(() {
                  final hasLoc = newPropertyController.latitude.value != 0.0 &&
                      newPropertyController.longitude.value != 0.0;
                  return Icon(hasLoc ? Icons.check_circle : Icons.location_on,
                      color: hasLoc ? kSuccess : null);
                }),
                const SizedBox(width: 10),
                Obx(() {
                  final lat = newPropertyController.latitude.value;
                  final lng = newPropertyController.longitude.value;
                  final hasLoc = lat != 0.0 && lng != 0.0;
                  return Text(hasLoc
                      ? 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}'
                      : 'Select Location');
                }),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      );

  Widget _buildAddressFields() => Column(
        children: [
          PropertyTextField(_addressController, 'Address', Icons.location_on),
          Row(children: [
            Expanded(
                child: PropertyTextField(
                    _cityController, 'City', Icons.location_city)),
            const SizedBox(width: 8),
            Expanded(
                child: PropertyTextField(_stateController, 'State', Icons.map)),
          ]),
          Row(children: [
            Expanded(
                child: PropertyTextField(
                    _countryController, 'Country', Icons.flag)),
            const SizedBox(width: 8),
            Expanded(
                child: PropertyTextField(
                    _zipCodeController, 'Zip Code', Icons.pin_drop)),
          ]),
          const SizedBox(height: 16),
        ],
      );

  Widget _buildDescriptionSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Property Description'),
          PropertyTextField(
              _descriptionController, 'Description', Icons.description,
              maxLines: 5),
        ],
      );

  Widget _buildPricingSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Pricing'),
          PriceTextField(_exactPriceController, 'Exact Price per Night'),
          PriceTextField(
              _minPriceController, 'Minimum Price per Night (for negotiation)'),
          const SectionTitle('Weekly Pricing'),
          PriceTextField(_weeklyMinPriceController, 'Weekly Minimum Price',
              isRequired: false),
          PriceTextField(_weeklyMaxPriceController, 'Weekly Maximum Price',
              isRequired: false),
          const SectionTitle('Monthly Pricing'),
          PriceTextField(_monthlyMaxPriceController, 'Monthly Max Price',
              isRequired: false),
          PriceTextField(_monthlyMinPriceController, 'Monthly Min Price',
              isRequired: false),
          PriceTextField(
              _monthlySecurityAmountController, 'Monthly Security Amount',
              isRequired: false),
        ],
      );

  // ── H1 parity sections (new wizard fields) ──────────────────────────────────

  Widget _singleSelectChips(
    List<String> options,
    String? selected,
    ValueChanged<String> onSelect,
  ) =>
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: options
            .map((o) => ChoiceChip(
                  label: Text(o.capitalizeFirst ?? o),
                  selected: selected == o,
                  selectedColor: kprimaryColor,
                  backgroundColor: kSand,
                  labelStyle: TextStyle(color: selected == o ? kCream : kInk),
                  onSelected: (_) => setState(() => onSelect(o)),
                ))
            .toList(),
      );

  Widget _buildListingDetailsSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Listing Details'),
          PropertyTextField(
              _areaLocalityController, 'Area / Locality', Icons.location_city,
              isRequired: false),
          PropertyTextField(
              _landmarkController, 'Landmark', Icons.place_outlined,
              isRequired: false),
          Row(children: [
            Expanded(
                child: PropertyTextField(
                    _floorNoController, 'Floor No.', Icons.stairs,
                    isRequired: false)),
            const SizedBox(width: 12),
            Expanded(
                child: PropertyTextField(_bathroomsController, 'Bathrooms',
                    Icons.bathtub_outlined,
                    isRequired: false, isNumeric: true)),
          ]),
          const SizedBox(height: 12),
          const Text('Booking preference',
              style: TextStyle(fontWeight: FontWeight.w600, color: kInk)),
          const SizedBox(height: 8),
          _singleSelectChips(const ['instant', 'request'], _bookingPref,
              (v) => _bookingPref = v),
          const SizedBox(height: 12),
          const Text('Ownership type',
              style: TextStyle(fontWeight: FontWeight.w600, color: kInk)),
          const SizedBox(height: 8),
          _singleSelectChips(const ['owned', 'leased', 'managed'],
              _ownershipType, (v) => _ownershipType = v),
          const SizedBox(height: 12),
          PropertyTextField(_quietHoursController,
              'Quiet hours (e.g. 10 PM - 7 AM)', Icons.nightlight_round,
              isRequired: false),
          PropertyTextField(_videoUrlController, 'Video tour URL (optional)',
              Icons.videocam_outlined,
              isRequired: false),
          const SizedBox(height: 8),
        ],
      );

  Widget _buildAdditionalChargesSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Additional Charges (optional)'),
          PriceTextField(_securityDepositController, 'Security Deposit',
              isRequired: false),
          PriceTextField(_weekendPriceController, 'Weekend Price / Night',
              isRequired: false),
          PriceTextField(_cleaningFeeController, 'Cleaning Fee',
              isRequired: false),
          PriceTextField(_extraGuestChargeController, 'Extra Guest Charge',
              isRequired: false),
          PriceTextField(
              _minBookingAmountController, 'Minimum Booking Amount',
              isRequired: false),
        ],
      );

  Widget _buildStayPreferencesSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Stay Preferences'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: kprimaryColor,
            title: const Text('Couple friendly'),
            value: _coupleFriendly,
            onChanged: (v) => setState(() => _coupleFriendly = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: kprimaryColor,
            title: const Text('Local ID allowed'),
            value: _localIdAllowed,
            onChanged: (v) => setState(() => _localIdAllowed = v),
          ),
        ],
      );

  Widget _buildPgSection() {
    if (!isSharingSelected) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('PG / Sharing Details'),
        const Text('Room type',
            style: TextStyle(fontWeight: FontWeight.w600, color: kInk)),
        const SizedBox(height: 8),
        _singleSelectChips(const ['single', 'double', 'triple', 'dorm'],
            _pgRoomType, (v) => _pgRoomType = v),
        const SizedBox(height: 12),
        const Text('Gender preference',
            style: TextStyle(fontWeight: FontWeight.w600, color: kInk)),
        const SizedBox(height: 8),
        _singleSelectChips(
            const ['male', 'female', 'any'], _pgGenderPref, (v) => _pgGenderPref = v),
        const SizedBox(height: 12),
        PriceTextField(_pgMonthlyRentController, 'Monthly Rent',
            isRequired: false),
        PriceTextField(_pgDepositController, 'Deposit', isRequired: false),
        PropertyTextField(
            _pgLockInController, 'Lock-in (months)', Icons.lock_clock,
            isRequired: false, isNumeric: true),
        PropertyTextField(
            _pgCurfewController, 'Curfew (e.g. 11 PM)', Icons.schedule,
            isRequired: false),
        PropertyTextField(_pgVisitorPolicyController, 'Visitor policy',
            Icons.people_outline,
            isRequired: false),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeColor: kprimaryColor,
          title: const Text('Food included'),
          value: _pgFoodIncluded,
          onChanged: (v) => setState(() => _pgFoodIncluded = v),
        ),
      ],
    );
  }

  Widget _buildPartyExtrasSection() {
    if (!isPartySelected) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Party / Group Booking'),
        PropertyTextField(
            _partyMaxPeopleController, 'Max people', Icons.groups_outlined,
            isRequired: false, isNumeric: true),
        PriceTextField(_partyChargesController, 'Party charges',
            isRequired: false),
        PropertyTextField(
            _partyEndTimeController, 'End time (e.g. 11 PM)',
            Icons.timer_off_outlined,
            isRequired: false),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeColor: kprimaryColor,
          title: const Text('Loud music allowed'),
          value: _partyLoudMusic,
          onChanged: (v) => setState(() => _partyLoudMusic = v),
        ),
      ],
    );
  }

  // Amenities come from the admin-managed list (/common/amenties) so whatever
  // the admin publishes is what the host can pick (content sync).
  Widget _buildAmenitiesSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Amenities'),
          Obx(() {
            final list = commonController.amenities.value?.data ?? [];
            if (list.isEmpty) {
              return const Text('Loading amenities…',
                  style: TextStyle(color: kInk2));
            }
            return Wrap(
              spacing: 8.0,
              runSpacing: 4,
              children: list
                  .map((a) => FilterChip(
                        label: Text(a.amnTitle),
                        selected: _selectedAmenityIds.contains(a.amnId),
                        selectedColor: kprimaryColor.withOpacity(0.15),
                        checkmarkColor: kprimaryColor,
                        onSelected: (sel) => setState(() {
                          if (sel) {
                            _selectedAmenityIds.add(a.amnId);
                            if (!amenities.contains(a.amnTitle)) {
                              amenities.add(a.amnTitle);
                            }
                          } else {
                            _selectedAmenityIds.remove(a.amnId);
                            amenities.remove(a.amnTitle);
                          }
                        }),
                      ))
                  .toList(),
            );
          }),
          const SizedBox(height: 16),
        ],
      );

  // Tags come from the admin-managed list (/common/tags) → property_tag[].
  Widget _buildTagsSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Tags'),
          Obx(() {
            final list = commonController.tags.value?.data.tags ?? [];
            if (list.isEmpty) {
              return const Text('Loading tags…',
                  style: TextStyle(color: kInk2));
            }
            return Wrap(
              spacing: 8.0,
              runSpacing: 4,
              children: list
                  .map((t) => FilterChip(
                        label: Text(t.tagName),
                        selected: _selectedTagIds.contains(t.tagId),
                        selectedColor: kprimaryColor.withOpacity(0.15),
                        checkmarkColor: kprimaryColor,
                        onSelected: (sel) => setState(() {
                          sel
                              ? _selectedTagIds.add(t.tagId)
                              : _selectedTagIds.remove(t.tagId);
                        }),
                      ))
                  .toList(),
            );
          }),
          const SizedBox(height: 16),
        ],
      );

  Widget _buildPoliciesSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Policies'),
          PropertyTimePicker(
            label: 'Check-in Time',
            time: checkInTime,
            onChanged: (t) => setState(() => checkInTime = t),
          ),
          PropertyTimePicker(
            label: 'Check-out Time',
            time: checkOutTime,
            onChanged: (t) => setState(() => checkOutTime = t),
          ),
          SwitchListTile(
            title: const Text('Pet-Friendly'),
            value: isPetFriendly,
            onChanged: (v) => setState(() => isPetFriendly = v),
          ),
          const SizedBox(height: 16),
        ],
      );

  Widget _buildHouseRulesSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('House Rules'),
          PropertyTextField(
            _houseRulesController,
            "Property Rules (separate each rule with a period '.')",
            Icons.rule,
            maxLines: 4,
          ),
          if (_houseRulesController.text.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kprimaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kprimaryColor.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Preview (comma-separated):',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: kprimaryColor,
                          fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(_parseHouseRules(_houseRulesController.text),
                      style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kprimaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kprimaryColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: kprimaryColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Example: No smoking. No parties. Quiet hours 10 PM - 8 AM.',
                    style: const TextStyle(
                        fontSize: 12,
                        color: kInk2,
                        fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildDocumentsSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Property Documents (Minimum 3 required)'),
          DocumentUploadSection(
            stateText: _stateController.text,
            fireAndSafetyNOC: fireAndSafetyNOC,
            jamaBandhiDoc: jamaBandhiDoc,
            nocDocument: nocDocument,
            policeVerificationDoc: policeVerificationDoc,
            isPartySelected: isPartySelected,
            partyLicenseDoc: partyLicenseDoc,
            onPick: _pickDocument,
          ),
        ],
      );

  Widget _buildContactSection() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Contact Information'),
          PropertyTextField(_contactController, 'WhatsApp Number', Icons.phone,
              isNumeric: true),
          PropertyTextField(_emailController, 'Email', Icons.email),
          const SizedBox(height: 10),
        ],
      );

  Widget _buildTermsSection() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kCream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kLine),
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  checkColor: Colors.white,
                  activeColor: kprimaryColor,
                  value: termsAccepted,
                  onChanged: (v) => setState(() => termsAccepted = v!),
                ),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(top: 12.0),
                    child: Text(
                      'I agree to the terms and conditions for property listing',
                      style: TextStyle(fontSize: 14, color: kInk2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _showTermsSheet,
                icon: const Icon(Icons.info_outline,
                    size: 18, color: kprimaryColor),
                label: const Text(
                  'Learn More about Terms & Conditions',
                  style: TextStyle(
                      color: kprimaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: kprimaryColor.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildSubmitButton(ThemeData theme) => SizedBox(
        width: double.infinity,
        child: Obx(() => ElevatedButton(
              onPressed: () {
                if (!termsAccepted) {
                  _showSnackBar('Please accept the terms and conditions',
                      isError: true);
                  return;
                }
                if (newPropertyController.isLoading.value) return;
                _saveProperty();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: const StadiumBorder(),
              ),
              child: newPropertyController.isLoading.value
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'Submit',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            )),
      );
}
