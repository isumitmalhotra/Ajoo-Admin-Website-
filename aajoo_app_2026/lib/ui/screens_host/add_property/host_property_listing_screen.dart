import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/controller/common_controller.dart';
import 'package:rent_home/ui/screens_common/auth/auth_controller.dart';
import 'package:rent_home/ui/screens_common/location_picker/pick_location_screen.dart';
import 'package:rent_home/ui/screens_host/add_property/document_upload_section.dart';
import 'package:rent_home/ui/screens_host/add_property/new_property_controller_legacy.dart';
import 'package:rent_home/ui/screens_host/add_property/property_image_picker.dart';
import 'package:rent_home/ui/screens_host/host_controller.dart';
import 'package:rent_home/ui/screens_host/host_tab_provider.dart';

import 'widgets/property_form_widgets.dart';

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

  // ── GetX ──────────────────────────────────────────────────────────────────
  final newPropertyController = Get.put(NewPropertyController());
  final authController = Get.find<AuthController>();
  final commonController = Get.find<CommonController>();

  // ── State ─────────────────────────────────────────────────────────────────
  List<XFile> images = [];
  List<String> amenities = [];
  List<String> hotelTypes = [];
  List<String> tempSelected = [];
  TimeOfDay? checkInTime;
  TimeOfDay? checkOutTime;
  bool isPetFriendly = false;
  bool isSmokingAllowed = false;
  bool isSharingSelected = false;
  bool isPartySelected = false;
  bool termsAccepted = false;

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
    if (!_formKey.currentState!.validate()) return;

    if (images.length < 2) {
      _showSnackBar('Please upload at least 2 photos of your property',
          isError: true);
      return;
    }
    if (_docsCount < 3) {
      _showSnackBar('Please upload at least 3 property documents',
          isError: true);
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
      ..propRule.value = _parseHouseRules(_houseRulesController.text);

    if (fireAndSafetyNOC != null)
      newPropertyController.fireAndSafetyNOC.value =
          File(fireAndSafetyNOC!.path);
    if (jamaBandhiDoc != null)
      newPropertyController.jamaBandhiDoc.value = File(jamaBandhiDoc!.path);
    if (nocDocument != null)
      newPropertyController.nocDocument.value = File(nocDocument!.path);
    if (policeVerificationDoc != null)
      newPropertyController.policeVerificationDoc.value =
          File(policeVerificationDoc!.path);

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Add Property'),
        backgroundColor: kprimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLuxurySection(),
              _buildImagesSection(),
              _buildBasicDetailsSection(),
              _buildLocationButton(),
              _buildAddressFields(),
              _buildDescriptionSection(),
              _buildPricingSection(),
              _buildAmenitiesSection(),
              _buildPoliciesSection(),
              _buildHouseRulesSection(),
              _buildDocumentsSection(),
              _buildContactSection(),
              _buildTermsSection(),
              const SizedBox(height: 10),
              _buildSubmitButton(theme),
            ],
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

  Widget _buildAmenitiesSection() {
    const options = [
      'Wi-Fi',
      'Pool',
      'Gym',
      'Kitchen',
      'Air Conditioning',
      'Parking'
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle('Amenities'),
        Wrap(
          spacing: 8.0,
          children: options
              .map((a) => FilterChip(
                    label: Text(a),
                    selected: amenities.contains(a),
                    onSelected: (selected) => setState(() {
                      selected ? amenities.add(a) : amenities.remove(a);
                    }),
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

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
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Example: No smoking. No parties. Quiet hours 10 PM - 8 AM.',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[800],
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
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12.0),
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
