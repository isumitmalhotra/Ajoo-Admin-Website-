import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/data/models/host_properties_reponse.dart';
import 'package:rent_home/ui/screens_host/add_property/new_property_controller_legacy.dart';

class UpdatePropertyPage extends StatefulWidget {
  final Property property;
  const UpdatePropertyPage({super.key, required this.property});

  @override
  State<UpdatePropertyPage> createState() => _UpdatePropertyPageState();
}

class _UpdatePropertyPageState extends State<UpdatePropertyPage> {
  final _formKey = GlobalKey<FormState>();
  final controller = Get.put(NewPropertyController(), tag: 'update_property');
  final ImagePicker _picker = ImagePicker();

  // Text controllers
  late TextEditingController nameCtrl;
  late TextEditingController descCtrl;
  late TextEditingController addressCtrl;
  late TextEditingController priceCtrl;
  late TextEditingController minPriceCtrl;
  late TextEditingController cityCtrl;
  late TextEditingController stateCtrl;
  late TextEditingController countryCtrl;
  late TextEditingController zipCtrl;
  late TextEditingController contactCtrl;
  late TextEditingController emailCtrl;
  late TextEditingController rulesCtrl;

  List<XFile> pickedImages = [];

  @override
  void initState() {
    super.initState();
    final p = widget.property;
    // Text field default mapping mirrors new property screen approach
    nameCtrl = TextEditingController(text: p.propertyName);
    descCtrl = TextEditingController(text: p.propertyDesc);
    addressCtrl = TextEditingController(text: p.propertyAddress);
    priceCtrl = TextEditingController(text: p.propertyPrice.toString());
    minPriceCtrl = TextEditingController(text: p.propertyMiniPrice.toString());
    cityCtrl = TextEditingController(text: p.propertyCity);
    stateCtrl = TextEditingController(text: p.propertyState.toString());
    countryCtrl = TextEditingController(text: p.propertyContry);
    zipCtrl = TextEditingController(text: p.propertyZip?.toString() ?? '');
    contactCtrl = TextEditingController(text: p.propertyContact);
    emailCtrl = TextEditingController(text: p.propertyEmail);

    // House rules not present in host properties response; keep blank
    rulesCtrl = TextEditingController(text: '');

    // Seed observable values (category defaults to 'single' like create screen)
    controller.propertyName.value = nameCtrl.text;
    controller.propertyDescription.value = descCtrl.text;
    controller.address.value = addressCtrl.text;
    controller.price.value = priceCtrl.text;
    controller.minPrice.value = minPriceCtrl.text;
    controller.category.value = 'single';
    controller.city.value = cityCtrl.text;
    controller.state.value = stateCtrl.text;
    controller.country.value = countryCtrl.text;
    controller.pincode.value = zipCtrl.text;
    controller.contact.value = contactCtrl.text;
    controller.email.value = emailCtrl.text;
    controller.propRule.value = '';

    controller.isPetAllowed.value =
        int.tryParse('${p.propDetailsPropDetailIsPetFriendly ?? 0}') ?? 0;
    controller.isSmokingAllowed.value =
        int.tryParse('${p.propDetailsPropDetailIsSmoke ?? 0}') ?? 0;
    controller.isLuxury.value = (p.isLuxury == 1);

    // Weekly / monthly pricing default to zero strings like new screen's logic when empty
    controller.weeklyMinPrice.value = '0';
    controller.weeklyMaxPrice.value = '0';
    controller.monthlySecurityAmount.value = '0';
    controller.numberOfBeds.value =
        0; // only relevant if sharing, still default

    controller.inTime.value = p.propDetailsPropDetailInTime?.toString() ?? '';
    controller.outTime.value = p.propDetailsPropDetailOutTime?.toString() ?? '';
  }

  Future<void> _pickImages() async {
    final imgs = await _picker.pickMultiImage();
    if (imgs.isNotEmpty) {
      setState(() => pickedImages = imgs);
      controller.image.value = imgs.map((e) => File(e.path)).toList();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Sync text fields back to controller
    controller.propertyName.value = nameCtrl.text.trim();
    controller.propertyDescription.value = descCtrl.text.trim();
    controller.address.value = addressCtrl.text.trim();
    controller.price.value = priceCtrl.text.trim();
    controller.minPrice.value = minPriceCtrl.text.trim();
    controller.city.value = cityCtrl.text.trim();
    controller.state.value = stateCtrl.text.trim();
    controller.country.value = countryCtrl.text.trim();
    controller.pincode.value = zipCtrl.text.trim();
    controller.contact.value = contactCtrl.text.trim();
    controller.email.value = emailCtrl.text.trim();
    // Process house rules similar to create screen (split on periods)
    final rawRules = rulesCtrl.text.trim();
    if (rawRules.isNotEmpty) {
      final processed = rawRules
          .split('.')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .join(', ');
      controller.propRule.value = processed;
    } else {
      controller.propRule.value = '';
    }

    await controller.updateProperty(widget.property.propertyId);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    descCtrl.dispose();
    addressCtrl.dispose();
    priceCtrl.dispose();
    minPriceCtrl.dispose();
    cityCtrl.dispose();
    stateCtrl.dispose();
    countryCtrl.dispose();
    zipCtrl.dispose();
    contactCtrl.dispose();
    emailCtrl.dispose();
    rulesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Property'),
        backgroundColor: kprimaryColor,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTextField(nameCtrl, 'Property Name'),
            _buildTextField(descCtrl, 'Description', maxLines: 3),
            _buildTextField(addressCtrl, 'Address', maxLines: 2),
            Row(children: [
              Expanded(
                  child: _buildTextField(priceCtrl, 'Price', isNumeric: true)),
              const SizedBox(width: 12),
              Expanded(
                  child: _buildTextField(minPriceCtrl, 'Min Price',
                      isNumeric: true)),
            ]),
            Row(children: [
              Expanded(child: _buildTextField(cityCtrl, 'City')),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField(stateCtrl, 'State')),
            ]),
            Row(children: [
              Expanded(child: _buildTextField(countryCtrl, 'Country')),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField(zipCtrl, 'Zip')),
            ]),
            _buildTextField(contactCtrl, 'Contact'),
            _buildTextField(emailCtrl, 'Email'),
            _buildTextField(rulesCtrl, 'House Rules',
                maxLines: 2, isRequired: false),
            const SizedBox(height: 12),
            Text('Images', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...pickedImages.map((x) => Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(File(x.path),
                              width: 90, height: 90, fit: BoxFit.cover),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close,
                              size: 18, color: kDanger),
                          onPressed: () {
                            setState(() {
                              pickedImages.remove(x);
                              controller.image.value = pickedImages
                                  .map((e) => File(e.path))
                                  .toList();
                            });
                          },
                        )
                      ],
                    )),
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      border: Border.all(color: kLine),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add_a_photo),
                  ),
                )
              ],
            ),
            const SizedBox(height: 24),
            Obx(() => ElevatedButton(
                  onPressed: controller.isLoading.value ? null : _submit,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: kprimaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  child: controller.isLoading.value
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Update Property'),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController c, String label,
      {int maxLines = 1, bool isNumeric = false, bool isRequired = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: TextFormField(
        controller: c,
        maxLines: maxLines,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: kCream,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        validator: (v) {
          if (!isRequired) return null;
          if (v == null || v.trim().isEmpty) return 'Enter $label';
          return null;
        },
      ),
    );
  }
}
