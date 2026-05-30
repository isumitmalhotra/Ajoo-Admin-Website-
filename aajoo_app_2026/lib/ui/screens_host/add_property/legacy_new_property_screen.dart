// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:get/get.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:provider/provider.dart';
// import 'package:rent_home/constants.dart';
// import 'package:rent_home/controller/common_controller.dart';
// import 'package:rent_home/ui/screens_host/add_property/new_property_controller_legacy.dart';
// import 'package:rent_home/ui/screens_host/host_controller.dart';
// import 'package:rent_home/ui/screens_host/host_tab_provider.dart';
// import 'package:rent_home/main.dart';
// import 'package:rent_home/ui/screens_common/location_picker/pick_location_screen.dart';

// import '../../screens_common/auth/auth_controller.dart';

// class HostPropertyListingScreen extends StatefulWidget {
//   @override
//   _HostPropertyListingScreenState createState() =>
//       _HostPropertyListingScreenState();
// }

// class _HostPropertyListingScreenState extends State<HostPropertyListingScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final ImagePicker _picker = ImagePicker();
//   List<XFile> images = [];

//   // Controllers for form fields
//   final TextEditingController _propertyNameController = TextEditingController();
//   final TextEditingController _addressController = TextEditingController();
//   final TextEditingController _cityController = TextEditingController();
//   final TextEditingController _stateController = TextEditingController();
//   final TextEditingController _countryController = TextEditingController();
//   final TextEditingController _zipCodeController = TextEditingController();
//   final TextEditingController _descriptionController = TextEditingController();
//   final TextEditingController _exactPriceController = TextEditingController();
//   final TextEditingController _minPriceController = TextEditingController();
//   // Unused controllers removed
//   final TextEditingController _contactController = TextEditingController();
//   final TextEditingController _emailController = TextEditingController();
//   // New controllers for weekly and monthly pricing
//   final TextEditingController _weeklyMinPriceController =
//       TextEditingController();
//   final TextEditingController _weeklyMaxPriceController =
//       TextEditingController();
//   final TextEditingController _monthlySecurityAmountController =
//       TextEditingController();
//   final TextEditingController _monthlyMaxPriceController =
//       TextEditingController();
//   final TextEditingController _monthlyMinPriceController =
//       TextEditingController();

//   // New controllers for additional fields
//   final TextEditingController _houseRulesController = TextEditingController();

//   final TextEditingController _numberOfBedsController = TextEditingController();
//   final TextEditingController _numberOfGuestsController =
//       TextEditingController();

//   String? propertyType;
//   List<String> amenities = [];
//   TimeOfDay? checkInTime;
//   TimeOfDay? checkOutTime;
//   bool isPetFriendly = false;
//   bool isSmokingAllowed = false;

//   // Property documents
//   XFile? fireAndSafetyNOC;
//   XFile? jamaBandhiDoc;
//   XFile? nocDocument;
//   XFile? policeVerificationDoc;

//   List<String> hotelTypes = [];
//   List<String> tempSelected = [];
//   bool isSharingSelected = false;
//   bool isPartySelected = false;

//   // New fields for profile and cover photo
//   XFile? propertyProfilePic;
//   XFile? propertyCoverPhoto;
//   bool termsAccepted = false;

//   // Show Terms and Conditions Learn More dialog

//   Widget _buildTermsSection(String title) {
//     return Padding(
//       padding: const EdgeInsets.only(top: 16, bottom: 8),
//       child: Text(
//         title,
//         style: const TextStyle(
//           fontSize: 16,
//           fontWeight: FontWeight.w600,
//           color: kprimaryColor,
//         ),
//       ),
//     );
//   }

//   Widget _buildTermsBullet(String text) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 6, left: 8),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             '• ',
//             style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//           ),
//           Expanded(
//             child: Text(
//               text,
//               style: const TextStyle(fontSize: 14, height: 1.4),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Image picker
//   Future<void> _pickImages() async {
//     final pickedImages = await _picker.pickMultiImage();
//     if (pickedImages.length <= 6) {
//       setState(() {
//         images = pickedImages;
//         // Set default profile and cover photo to first two images
//         if (images.length >= 2) {
//           propertyProfilePic = images[0];
//           propertyCoverPhoto = images[1];
//         }
//       });
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
//         content: Text('You can select up to 6 images only.'),
//       ));
//     }
//   }

//   // Select profile or cover photo
//   Future<void> _selectImage(String type) async {
//     final List<XFile>? pickedImages = await _picker.pickMultiImage();
//     if (pickedImages != null && pickedImages.isNotEmpty) {
//       setState(() {
//         if (type == 'profile') {
//           propertyProfilePic =
//               pickedImages[0]; // Set the first selected image as profile
//         } else if (type == 'cover') {
//           propertyCoverPhoto =
//               pickedImages[0]; // Set the first selected image as cover
//         }
//       });
//       images = pickedImages;
//     }
//   }

//   // Pick property documents
//   Future<void> _pickDocument(String documentType) async {
//     final XFile? pickedFile = await _picker.pickImage(
//       source: ImageSource.gallery,
//     );

//     if (pickedFile != null) {
//       setState(() {
//         switch (documentType) {
//           case 'fireAndSafety':
//             fireAndSafetyNOC = pickedFile;
//             break;
//           case 'jamaBandhi':
//             jamaBandhiDoc = pickedFile;
//             break;
//           case 'noc':
//             nocDocument = pickedFile;
//             break;
//           case 'policeVerification':
//             policeVerificationDoc = pickedFile;
//             break;
//         }
//       });

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('$documentType document selected successfully'),
//           backgroundColor: Colors.green,
//         ),
//       );
//     }
//   }

//   final newPropertyController = Get.put(NewPropertyController());
//   final authController = Get.find<AuthController>();

//   // Save form data
//   Future<void> _saveProperty() async {
//     final HostController hostController = Get.put(HostController());

//     if (_formKey.currentState!.validate()) {
//       // Check if at least 2 images are uploaded
//       if (images.length < 2) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             backgroundColor: Colors.red,
//             duration: Duration(seconds: 3),
//             content: Text(
//               "Please upload at least 2 photos of your property",
//               style: TextStyle(color: Colors.white),
//             ),
//           ),
//         );
//         return;
//       }

//       // if (isSharingSelected &&  (int.tryParse(_numberOfBedsController.text) ?? 0) == 0) {
//       //     ScaffoldMessenger.of(context).showSnackBar(
//       //       const SnackBar(
//       //         backgroundColor: Colors.red,
//       //         duration: Duration(seconds: 3),
//       //         content: Text(
//       //           "Please upload at least 2 photos of your property",
//       //           style: TextStyle(color: Colors.white),
//       //         ),
//       //       ),
//       //     );
//       //     return;
//       //   }

//       newPropertyController.propertyName.value = _propertyNameController.text;
//       newPropertyController.propertyDescription.value =
//           _descriptionController.text;
//       newPropertyController.address.value = _addressController.text;
//       newPropertyController.price.value = _exactPriceController.text;
//       newPropertyController.minPrice.value = _minPriceController.text;

//       newPropertyController.city.value = _cityController.text;
//       newPropertyController.state.value = _stateController.text;
//       newPropertyController.country.value = _countryController.text;
//       newPropertyController.pincode.value = _zipCodeController.text;
//       newPropertyController.amenities.value = amenities;
//       newPropertyController.inTime.value = checkInTime?.format(context) ?? "";
//       newPropertyController.outTime.value = checkOutTime?.format(context) ?? "";
//       newPropertyController.contact.value = _contactController.text;
//       newPropertyController.email.value = _emailController.text;
//       newPropertyController.isPetAllowed.value = isPetFriendly ? 1 : 0;
//       newPropertyController.isSmokingAllowed.value = isSmokingAllowed ? 1 : 0;
//       newPropertyController.numberOfBeds.value =
//           int.tryParse(_numberOfBedsController.text) ?? 0;
//       newPropertyController.numberOfGuests.value =
//           int.tryParse(_numberOfGuestsController.text) ?? 0;
//       newPropertyController.image.value =
//           images.isNotEmpty ? images.map((e) => File(e.path)).toList() : [];
//       // New fields for weekly and monthly pricing
//       newPropertyController.weeklyMinPrice.value =
//           _weeklyMinPriceController.text.isEmpty
//               ? "0"
//               : _weeklyMinPriceController.text;
//       newPropertyController.weeklyMaxPrice.value =
//           _weeklyMaxPriceController.text.isEmpty
//               ? "0"
//               : _weeklyMaxPriceController.text;
//       newPropertyController.monthlySecurityAmount.value =
//           _monthlySecurityAmountController.text.isEmpty
//               ? "0"
//               : _monthlySecurityAmountController.text;

//       // House rules - process text field input and convert periods to commas
//       String rulesText = _houseRulesController.text.trim();
//       if (rulesText.isNotEmpty) {
//         // Split by periods and clean up each rule
//         List<String> processedRules = rulesText
//             .split('.')
//             .map((rule) => rule.trim())
//             .where((rule) => rule.isNotEmpty)
//             .toList();
//         newPropertyController.propRule.value = processedRules.join(', ');
//       } else {
//         newPropertyController.propRule.value = '';
//       }

//       // Property documents
//       if (fireAndSafetyNOC != null) {
//         newPropertyController.fireAndSafetyNOC.value =
//             File(fireAndSafetyNOC!.path);
//       }
//       if (jamaBandhiDoc != null) {
//         newPropertyController.jamaBandhiDoc.value = File(jamaBandhiDoc!.path);
//       }
//       if (nocDocument != null) {
//         newPropertyController.nocDocument.value = File(nocDocument!.path);
//       }
//       if (policeVerificationDoc != null) {
//         newPropertyController.policeVerificationDoc.value =
//             File(policeVerificationDoc!.path);
//       }

//       final result = await newPropertyController.saveProperty();

//       hostController.getHostProperties();
//       final user = authController.userData.value;
//       if (user != null) {
//         hostController.getHostOngoing(user.userId);
//       }

//       if (result.isSuccess) {
//         showDialog(
//           context: context,
//           builder: (dialogContext) => AlertDialog(
//             title: const Text('Success'),
//             content: Text(result.message ?? ''),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   // Close dialog first
//                   Navigator.of(dialogContext).pop();

//                   // Then reset tab
//                   final hostTabProvider = context.read<HostTabProvider>();
//                   hostTabProvider.resetToHome();
//                 },
//                 child: const Text('OK'),
//               ),
//             ],
//           ),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(result.message ?? 'Error'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     ever(newPropertyController.latitude, (_) async {
//       if (newPropertyController.latitude.value != 0.0 &&
//           newPropertyController.longitude.value != 0.0) {
//         try {
//           // Import geocoding package in your pubspec.yaml and at the top of this file:
//           // import 'package:geocoding/geocoding.dart';
//           final placemarks = await placemarkFromCoordinates(
//             newPropertyController.latitude.value,
//             newPropertyController.longitude.value,
//           );
//           if (placemarks.isNotEmpty) {
//             final place = placemarks.first;
//             setState(() {
//               _addressController.text =
//                   "${place.street ?? ''}, ${place.subLocality ?? ''}".trim();
//               _cityController.text = place.locality ?? '';
//               _stateController.text = place.administrativeArea ?? '';
//               _countryController.text = place.country ?? '';
//               _zipCodeController.text = place.postalCode ?? '';
//             });
//           }
//         } catch (e) {
//           // Handle geocoding error
//         }
//       }
//     });
//   }

//   @override
//   void initState() {
//     super.initState();
//     hotelTypes = commonController.cats.value?.data.categories
//             .map((e) => e.catTitle)
//             .toList() ??
//         [];
//     hotelTypes.remove("apartment");
//     hotelTypes.remove("Apartment");
//     hotelTypes.add("Family");
//     final user = authController.userData.value;
//     _emailController.text = user?.email ?? "";
//     _contactController.text = user?.phoneNumber ?? "";

//     // Add listener to house rules controller for real-time preview
//     _houseRulesController.addListener(() {
//       setState(() {
//         // This will trigger a rebuild to update the preview
//       });
//     });

//     // Rebuild when state field changes so document section updates
//     _stateController.addListener(() {
//       setState(() {});
//     });
//   }

//   @override
//   void dispose() {
//     _houseRulesController.dispose();
//     super.dispose();
//   }

//   final CommonController commonController = Get.find<CommonController>();
//   @override
//   Widget build(BuildContext context) {
//     print(commonController.cats.value?.toJson());
//     final theme = Theme.of(context);

//     return Scaffold(
//       appBar: AppBar(
//         centerTitle: true,
//         title: const Text("Add Property"),
//         backgroundColor: kprimaryColor,
//         foregroundColor: Colors.white,
//         elevation: 0,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Luxury Property Section
//               const SizedBox(height: 8),
//               _buildSectionTitle("Luxury Property"),
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.amber.withOpacity(0.06),
//                   border: Border.all(color: Colors.amber.withOpacity(0.3)),
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: const Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const Icon(Icons.star_rounded,
//                         color: Colors.amber, size: 24),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: const [
//                           Text(
//                             "What counts as Luxury?",
//                             style: TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.w700,
//                               color: Colors.black87,
//                             ),
//                           ),
//                           SizedBox(height: 6),
//                           Text(
//                             "Luxury listings typically include premium finishes, exceptional amenities (like pool, gym, concierge), prime locations, and superior guest experience.",
//                             style: TextStyle(fontSize: 13, height: 1.35),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Obx(() => SwitchListTile(
//                     title: const Text("Mark as Luxury"),
//                     subtitle: const Text(
//                         "Toggle on if this property meets luxury standards."),
//                     value: newPropertyController.isLuxury.value,
//                     activeColor: Colors.amber[800],
//                     onChanged: (val) =>
//                         newPropertyController.isLuxury.value = val,
//                   )),

//               // Property images
//               _buildSectionTitle(
//                   "Property Images (Minimum 2 required, up to 6)"),
//               GestureDetector(
//                 onTap: _pickImages,
//                 child: Container(
//                   height: 100,
//                   decoration: BoxDecoration(
//                     color: Colors.grey[300],
//                     borderRadius: BorderRadius.circular(8.0),
//                     border: Border.all(
//                       color: images.length < 2 ? Colors.red : Colors.grey,
//                       width: images.length < 2 ? 2 : 1,
//                     ),
//                   ),
//                   child: Center(
//                     child: images.isEmpty
//                         ? const HostTapToAddPhotosView()
//                         : ListView.builder(
//                             scrollDirection: Axis.horizontal,
//                             itemCount: images.length,
//                             itemBuilder: (context, index) {
//                               return Padding(
//                                 padding: const EdgeInsets.all(4.0),
//                                 child: Stack(
//                                   children: [
//                                     Image.file(
//                                       File(images[index].path),
//                                       width: 80,
//                                       height: 80,
//                                       fit: BoxFit.cover,
//                                     ),
//                                     Positioned(
//                                       top: 0,
//                                       right: 0,
//                                       child: GestureDetector(
//                                         onTap: () {
//                                           setState(() {
//                                             images.removeAt(index);
//                                           });
//                                         },
//                                         child: Container(
//                                           decoration: BoxDecoration(
//                                             color: Colors.red,
//                                             borderRadius:
//                                                 BorderRadius.circular(10),
//                                           ),
//                                           child: const Icon(
//                                             Icons.close,
//                                             color: Colors.white,
//                                             size: 16,
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               );
//                             },
//                           ),
//                   ),
//                 ),
//               ),
//               if (images.length < 2)
//                 Padding(
//                   padding: const EdgeInsets.only(top: 4.0),
//                   child: Text(
//                     "Please upload at least 2 photos (${images.length}/2)",
//                     style: const TextStyle(
//                       color: Colors.red,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ),
//               if (images.length >= 2)
//                 Padding(
//                   padding: const EdgeInsets.only(top: 4.0),
//                   child: Text(
//                     "✓ Photos uploaded (${images.length}/6)",
//                     style: const TextStyle(
//                       color: Colors.green,
//                       fontSize: 12,
//                     ),
//                   ),
//                 ),
//               const SizedBox(height: 16),

//               // Property basic details
//               _buildSectionTitle("Basic Property Details"),
//               _buildTextField(
//                   _propertyNameController, "Property Name", Icons.business),
//               const SizedBox(height: 8),
//               const Text(
//                 "Property Type",
//                 style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 8),
//               Wrap(
//                 spacing: 8.0,
//                 runSpacing: 8.0,
//                 children: hotelTypes.map((String item) {
//                   return ChoiceChip(
//                     label: Text(item.toString().capitalize!),
//                     selected: tempSelected.contains(item),
//                     onSelected: (bool selected) {
//                       setState(() {
//                         if (selected) {
//                           tempSelected.add(item);
//                         } else {
//                           tempSelected.remove(item);
//                         }
//                         isSharingSelected = tempSelected.contains("sharing");
//                         isPartySelected = tempSelected.contains("party");

//                         // Reset values if unselected
//                         if (!isSharingSelected) {
//                           _numberOfBedsController.clear();
//                         }

//                         if (!isPartySelected) {
//                           _numberOfGuestsController.clear();
//                         }
//                       });
//                     },
//                     selectedColor: kprimaryColor,
//                     backgroundColor: Colors.grey.shade200,
//                     labelStyle: TextStyle(
//                       color: tempSelected.contains(item)
//                           ? Colors.white
//                           : Colors.black87,
//                     ),
//                   );
//                 }).toList(),
//               ),
//               const SizedBox(height: 8),

//               /// ✅ Sharing → Number of Beds
//               if (isSharingSelected) ...[
//                 const Text("Sharing Property Details",
//                     style:
//                         TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: _numberOfBedsController,
//                   decoration: InputDecoration(
//                     labelText: "Beds Available",
//                     prefixIcon: null,
//                     filled: true,
//                     fillColor: Colors.grey[100],
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12.0),
//                       borderSide: BorderSide.none,
//                     ),
//                   ),
//                   maxLines: 1,
//                   keyboardType: TextInputType.number,
//                   validator: (value) {
//                     return (value == null || value.isEmpty)
//                         ? "Please enter number of beds"
//                         : null;
//                   },
//                 )
//               ],

//               /// ✅ Party → Number of Guests
//               if (isPartySelected) ...[
//                 const Text("Party Property Details",
//                     style:
//                         TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: _numberOfGuestsController,
//                   decoration: InputDecoration(
//                     labelText: "Number of Guests (Party)",
//                     prefixIcon: null,
//                     filled: true,
//                     fillColor: Colors.grey[100],
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12.0),
//                       borderSide: BorderSide.none,
//                     ),
//                   ),
//                   maxLines: 1,
//                   keyboardType: TextInputType.number,
//                   validator: (value) {
//                     return (value == null || value.isEmpty)
//                         ? "Please enter number of guests"
//                         : null;
//                   },
//                 )
//               ],

//               const SizedBox(height: 8),

//               ElevatedButton(
//                 onPressed: () {
//                   Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                           builder: (context) => const PickLocationScreen()));
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.grey[200],
//                   foregroundColor: Colors.black,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12.0),
//                   ),
//                   minimumSize: const Size(double.infinity, 50),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Obx(() => newPropertyController.latitude.value != 0.0 &&
//                             newPropertyController.longitude.value != 0.0
//                         ? const Icon(Icons.check_circle, color: Colors.green)
//                         : const Icon(Icons.location_on)),
//                     const SizedBox(
//                       width: 10,
//                     ),
//                     Obx(() => Text(newPropertyController.latitude.value !=
//                                 0.0 &&
//                             newPropertyController.longitude.value != 0.0
//                         ? "Latitude: ${newPropertyController.latitude.value.toString().substring(0, 6)}, Longitude: ${newPropertyController.longitude.value.toString().substring(0, 6)}"
//                         : "Select Location")),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 16),

//               _buildTextField(_addressController, "Address", Icons.location_on),
//               Row(
//                 children: [
//                   Expanded(
//                       child: _buildTextField(
//                           _cityController, "City", Icons.location_city)),
//                   const SizedBox(width: 8),
//                   Expanded(
//                       child: _buildTextField(
//                           _stateController, "State", Icons.map)),
//                 ],
//               ),
//               Row(
//                 children: [
//                   Expanded(
//                       child: _buildTextField(
//                           _countryController, "Country", Icons.flag)),
//                   const SizedBox(width: 8),
//                   Expanded(
//                       child: _buildTextField(
//                           _zipCodeController, "Zip Code", Icons.pin_drop)),
//                 ],
//               ),

//               const SizedBox(height: 16),

//               // Property description
//               _buildSectionTitle("Property Description"),
//               _buildTextField(
//                   _descriptionController, "Description", Icons.description,
//                   maxLines: 5),

//               // Pricing
//               _buildSectionTitle("Pricing"),
//               _buildTextField(_exactPriceController, "Exact Price per Night",
//                   Icons.attach_money,
//                   mainIcon: const Padding(
//                     padding:
//                         EdgeInsets.symmetric(vertical: 12.0, horizontal: 30),
//                     child: Text("₹",
//                         style: TextStyle(fontSize: 35, color: Colors.black)),
//                   ),
//                   isNumeric: true),
//               _buildTextField(
//                   _minPriceController,
//                   "Minimum Price per Night (for negotiation)",
//                   Icons.attach_money,
//                   mainIcon: const Padding(
//                     padding:
//                         EdgeInsets.symmetric(vertical: 12.0, horizontal: 30),
//                     child: Text("₹",
//                         style: TextStyle(fontSize: 35, color: Colors.black)),
//                   ),
//                   isNumeric: true),
//               _buildSectionTitle("Weekly Pricing"),
//               _buildTextField(_weeklyMinPriceController, "Weekly Minimum Price",
//                   Icons.attach_money,
//                   mainIcon: const Padding(
//                     padding:
//                         EdgeInsets.symmetric(vertical: 12.0, horizontal: 30),
//                     child: Text("₹",
//                         style: TextStyle(fontSize: 35, color: Colors.black)),
//                   ),
//                   isNumeric: true,
//                   isRequired: false),
//               _buildTextField(_weeklyMaxPriceController, "Weekly Maximum Price",
//                   Icons.attach_money,
//                   mainIcon: const Padding(
//                     padding:
//                         EdgeInsets.symmetric(vertical: 12.0, horizontal: 30),
//                     child: Text("₹",
//                         style: TextStyle(fontSize: 35, color: Colors.black)),
//                   ),
//                   isNumeric: true,
//                   isRequired: false),
//               _buildSectionTitle("Monthly Pricing"),
//               _buildTextField(_monthlyMaxPriceController, "Monthly Max Price ",
//                   Icons.attach_money,
//                   mainIcon: const Padding(
//                     padding:
//                         EdgeInsets.symmetric(vertical: 12.0, horizontal: 30),
//                     child: Text("₹",
//                         style: TextStyle(fontSize: 35, color: Colors.black)),
//                   ),
//                   isNumeric: true,
//                   isRequired: false),
//               _buildTextField(_monthlyMinPriceController, "Monthly Min Price",
//                   Icons.attach_money,
//                   mainIcon: const Padding(
//                     padding:
//                         EdgeInsets.symmetric(vertical: 12.0, horizontal: 30),
//                     child: Text("₹",
//                         style: TextStyle(fontSize: 35, color: Colors.black)),
//                   ),
//                   isNumeric: true,
//                   isRequired: false),
//               _buildTextField(_monthlySecurityAmountController,
//                   "Monthly Security Amount", Icons.attach_money,
//                   mainIcon: const Padding(
//                     padding:
//                         EdgeInsets.symmetric(vertical: 12.0, horizontal: 30),
//                     child: Text("₹",
//                         style: TextStyle(fontSize: 35, color: Colors.black)),
//                   ),
//                   isNumeric: true,
//                   isRequired: false),

//               // Amenities
//               _buildSectionTitle("Amenities"),
//               Wrap(
//                 spacing: 8.0,
//                 children: [
//                   "Wi-Fi",
//                   "Pool",
//                   "Gym",
//                   "Kitchen",
//                   "Air Conditioning",
//                   "Parking"
//                 ]
//                     .map((amenity) => FilterChip(
//                           label: Text(amenity),
//                           selected: amenities.contains(amenity),
//                           onSelected: (selected) {
//                             setState(() {
//                               if (selected) {
//                                 amenities.add(amenity);
//                               } else {
//                                 amenities.remove(amenity);
//                               }
//                             });
//                           },
//                         ))
//                     .toList(),
//               ),
//               const SizedBox(height: 16),

//               // Policies
//               _buildSectionTitle("Policies"),
//               _buildTimePicker(
//                   "Check-in Time ",
//                   (selectedTime) => setState(() {
//                         checkInTime = selectedTime;
//                       }),
//                   time: checkInTime),
//               _buildTimePicker(
//                   "Check-out Time",
//                   (selectedTime) => setState(() {
//                         checkOutTime = selectedTime;
//                       }),
//                   time: checkOutTime),
//               SwitchListTile(
//                 title: const Text("Pet-Friendly"),
//                 value: isPetFriendly,
//                 onChanged: (value) => setState(() => isPetFriendly = value),
//               ),

//               const SizedBox(height: 16),

//               // House Rules
//               _buildSectionTitle("House Rules"),
//               _buildTextField(
//                 _houseRulesController,
//                 "Property Rules (separate each rule with a period '.')",
//                 Icons.rule,
//                 maxLines: 4,
//               ),
//               if (_houseRulesController.text.isNotEmpty)
//                 Container(
//                   margin: const EdgeInsets.only(top: 8),
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: kprimaryColor.withOpacity(0.05),
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(color: kprimaryColor.withOpacity(0.2)),
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text(
//                         "Preview (comma-separated):",
//                         style: TextStyle(
//                           fontWeight: FontWeight.w600,
//                           color: kprimaryColor,
//                           fontSize: 12,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         _houseRulesController.text
//                             .split('.')
//                             .map((rule) => rule.trim())
//                             .where((rule) => rule.isNotEmpty)
//                             .join(', '),
//                         style: const TextStyle(fontSize: 14),
//                       ),
//                     ],
//                   ),
//                 ),
//               const SizedBox(height: 8),
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.blue.withOpacity(0.05),
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(color: Colors.blue.withOpacity(0.2)),
//                 ),
//                 child: Row(
//                   children: [
//                     const Icon(Icons.info_outline,
//                         color: Colors.blue, size: 16),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: Text(
//                         "Example: No smoking. No parties. Quiet hours 10 PM - 8 AM. No pets allowed.",
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.blue[800],
//                           fontStyle: FontStyle.italic,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               // Property Documents
//               _buildSectionTitle("Property Documents (Minimum 3 required)"),
//               _buildDocumentUploadSection(),
//               Builder(
//                 builder: (context) {
//                   final int docsCount = (fireAndSafetyNOC != null ? 1 : 0) +
//                       (jamaBandhiDoc != null ? 1 : 0) +
//                       (nocDocument != null ? 1 : 0) +
//                       (policeVerificationDoc != null ? 1 : 0);
//                   return Padding(
//                     padding: const EdgeInsets.only(top: 4.0),
//                     child: Text(
//                       docsCount < 3
//                           ? "Please upload at least 3 documents ($docsCount/3)"
//                           : "✓ Documents uploaded ($docsCount/3)",
//                       style: TextStyle(
//                         color: docsCount < 3 ? Colors.red : Colors.green,
//                         fontSize: 12,
//                       ),
//                     ),
//                   );
//                 },
//               ),

//               const SizedBox(height: 16),

//               // Contact Information
//               _buildSectionTitle("Contact Information"),
//               _buildTextField(
//                   _contactController, "WhatsApp Number", Icons.phone,
//                   isNumeric: true),
//               _buildTextField(_emailController, "Email", Icons.email),
//               const SizedBox(height: 10),
//               // Terms and conditions with Learn More button
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Colors.grey[50],
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: Colors.grey[300]!),
//                 ),
//                 child: Column(
//                   children: [
//                     Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Checkbox(
//                           checkColor: Colors.white,
//                           activeColor: kprimaryColor,
//                           value: termsAccepted,
//                           onChanged: (value) {
//                             setState(() {
//                               termsAccepted = value!;
//                             });
//                           },
//                         ),
//                         Expanded(
//                           child: Padding(
//                             padding: const EdgeInsets.only(top: 12.0),
//                             child: Text(
//                               "I agree to the terms and conditions for property listing",
//                               style: TextStyle(
//                                 fontSize: 14,
//                                 color: Colors.grey[800],
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 8),
//                     SizedBox(
//                       width: double.infinity,
//                       child: TextButton.icon(
//                         onPressed: _showTermsAndConditionsDialog,
//                         icon: const Icon(
//                           Icons.info_outline,
//                           size: 18,
//                           color: kprimaryColor,
//                         ),
//                         label: const Text(
//                           'Learn More about Terms & Conditions',
//                           style: TextStyle(
//                             color: kprimaryColor,
//                             fontSize: 14,
//                             fontWeight: FontWeight.w500,
//                           ),
//                         ),
//                         style: TextButton.styleFrom(
//                           backgroundColor: kprimaryColor.withOpacity(0.1),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           padding: const EdgeInsets.symmetric(
//                               vertical: 12, horizontal: 16),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 10),

//               SizedBox(
//                 width: double.infinity,
//                 child: Obx(
//                   () => ElevatedButton(
//                       onPressed: () {
//                         if (!termsAccepted) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(
//                               backgroundColor: Colors.red,
//                               duration: Duration(seconds: 2),
//                               content:
//                                   Text("Please accept the terms and conditions",
//                                       style: TextStyle(
//                                         color: Colors.white,
//                                       )),
//                             ),
//                           );
//                           return;
//                         }
//                         if (images.length < 2) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(
//                               backgroundColor: Colors.red,
//                               duration: Duration(seconds: 3),
//                               content: Text(
//                                 "Please upload at least 2 photos of your property",
//                                 style: TextStyle(color: Colors.white),
//                               ),
//                             ),
//                           );
//                           return;
//                         }
//                         // Require at least 3 property documents
//                         final int docsCount =
//                             (fireAndSafetyNOC != null ? 1 : 0) +
//                                 (jamaBandhiDoc != null ? 1 : 0) +
//                                 (nocDocument != null ? 1 : 0) +
//                                 (policeVerificationDoc != null ? 1 : 0);
//                         if (docsCount < 3) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(
//                               backgroundColor: Colors.red,
//                               duration: Duration(seconds: 3),
//                               content: Text(
//                                 "Please upload at least 3 property documents",
//                                 style: TextStyle(color: Colors.white),
//                               ),
//                             ),
//                           );
//                           return;
//                         }
//                         newPropertyController.isLoading.value
//                             ? null
//                             : _saveProperty();
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: theme.primaryColor,
//                         padding: const EdgeInsets.symmetric(vertical: 16),
//                         shape: const StadiumBorder(),
//                       ),
//                       child: newPropertyController.isLoading.value
//                           ? const Center(
//                               child: CircularProgressIndicator(
//                                 color: kcontentColor,
//                               ),
//                             )
//                           : Text(
//                               "Submit",
//                               style: theme.textTheme.titleMedium?.copyWith(
//                                 color: theme.colorScheme.onPrimary,
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             )),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildSectionTitle(String title) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8.0),
//       child: Text(title,
//           style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//     );
//   }

//   Widget _buildTextField(
//       TextEditingController controller, String label, IconData icon,
//       {int? maxLines,
//       bool isNumeric = false,
//       Widget? mainIcon,
//       bool isRequired = true}) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16.0),
//       child: TextFormField(
//         controller: controller,
//         decoration: InputDecoration(
//           labelText: label,
//           prefixIcon: mainIcon ?? Icon(icon),
//           filled: true,
//           fillColor: Colors.grey[100],
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12.0),
//             borderSide: BorderSide.none,
//           ),
//         ),
//         maxLines: maxLines,
//         keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
//         validator: (value) {
//           if (!isRequired) return null;
//           return (value == null || value.isEmpty)
//               ? 'Please enter $label'
//               : null;
//         },
//       ),
//     );
//   }

//   Widget _buildDropdownField(
//       String label, List<String> items, Function(String?) onChanged) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16.0),
//       child: DropdownButtonFormField<String>(
//         decoration: InputDecoration(
//           labelText: label,
//           filled: true,
//           fillColor: Colors.grey[100],
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12.0),
//             borderSide: BorderSide.none,
//           ),
//         ),
//         items: items.map((String value) {
//           return DropdownMenuItem<String>(
//             value: value,
//             child: Text(value),
//           );
//         }).toList(),
//         onChanged: onChanged,
//         validator: (value) => value == null ? 'Please select a $label' : null,
//       ),
//     );
//   }

//   Widget _buildTimePicker(String label, Function(TimeOfDay?) onChanged,
//       {TimeOfDay? time}) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16.0),
//       child: GestureDetector(
//         onTap: () async {
//           TimeOfDay? pickedTime = await showTimePicker(
//             context: context,
//             initialTime: TimeOfDay.now(),
//           );
//           onChanged(pickedTime);
//         },
//         child: AbsorbPointer(
//           child: TextFormField(
//             decoration: InputDecoration(
//               labelText:
//                   time == null ? label : "$label: ${time.format(context)}",
//               filled: true,
//               hintText: checkInTime?.format(context) ?? "Select Time",
//               fillColor: Colors.grey[100],
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(12.0),
//                 borderSide: BorderSide.none,
//               ),
//             ),
//             validator: (value) => value == null ? 'Please select $label' : null,
//             readOnly: true,
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildDocumentUploadSection() {
//     return Column(
//       children: [
//         // Fire and Safety NOC
//         _buildDocumentUploadTile(
//           "Fire and Safety NOC",
//           "Fire and safety clearance certificate",
//           fireAndSafetyNOC,
//           () => _pickDocument('fireAndSafety'),
//         ),
//         const SizedBox(height: 8),

//         // Jama Bandhi Document - Only for Himachal Pradesh
//         if (_stateController.text
//             .trim()
//             .toLowerCase()
//             .contains('himachal')) ...[
//           _buildDocumentUploadTile(
//             "Jama Bandhi Document",
//             "Property registration or ownership document (Himachal Pradesh only)",
//             jamaBandhiDoc,
//             () => _pickDocument('jamaBandhi'),
//           ),
//           const SizedBox(height: 8),
//         ],

//         // NOC Document
//         _buildDocumentUploadTile(
//           "NOC Document",
//           "No Objection Certificate",
//           nocDocument,
//           () => _pickDocument('noc'),
//         ),
//         const SizedBox(height: 8),

//         // Police Verification
//         _buildDocumentUploadTile(
//           "Police Verification Document",
//           "Police clearance certificate",
//           policeVerificationDoc,
//           () => _pickDocument('policeVerification'),
//         ),
//       ],
//     );
//   }

//   Widget _buildDocumentUploadTile(
//     String title,
//     String subtitle,
//     XFile? document,
//     VoidCallback onTap,
//   ) {
//     return Container(
//       decoration: BoxDecoration(
//         border: Border.all(color: Colors.grey[300]!),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: ListTile(
//         leading: Icon(
//           document != null ? Icons.check_circle : Icons.upload_file,
//           color: document != null ? Colors.green : Colors.grey,
//         ),
//         title: Text(
//           title,
//           style: const TextStyle(fontWeight: FontWeight.w600),
//         ),
//         subtitle: Text(
//           document != null ? "Document uploaded" : subtitle,
//           style: TextStyle(
//             color: document != null ? Colors.green : Colors.grey[600],
//           ),
//         ),
//         trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//         onTap: onTap,
//       ),
//     );
//   }
// }

// class HostTapToAddPhotosView extends StatelessWidget {
//   const HostTapToAddPhotosView({
//     super.key,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         const Icon(Icons.add_a_photo, size: 40),
//         const SizedBox(height: 8),
//         Text(
//           "Tap to add photos",
//           style: TextStyle(
//             color: Colors.grey[600],
//             fontSize: 12,
//           ),
//         ),
//       ],
//     );
//   }
// }
