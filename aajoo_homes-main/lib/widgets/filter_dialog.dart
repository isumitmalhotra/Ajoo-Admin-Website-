// import 'dart:io';
//
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
//
// class HostPropertyListingScreen extends StatefulWidget {
//   @override
//   _HostPropertyListingScreenState createState() => _HostPropertyListingScreenState();
// }
//
// class _HostPropertyListingScreenState extends State<HostPropertyListingScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final ImagePicker _picker = ImagePicker();
//   List<XFile> images = [];
//
//   // Controllers for form fields
//   final TextEditingController _propertyNameController = TextEditingController();
//   final TextEditingController _addressController = TextEditingController();
//   final TextEditingController _cityController = TextEditingController();
//   final TextEditingController _stateController = TextEditingController();
//   final TextEditingController _countryController = TextEditingController();
//   final TextEditingController _zipCodeController = TextEditingController();
//   final TextEditingController _descriptionController = TextEditingController();
//   final TextEditingController _priceController = TextEditingController();
//   final TextEditingController _cleaningFeeController = TextEditingController();
//   final TextEditingController _securityDepositController = TextEditingController();
//   final TextEditingController _maxGuestsController = TextEditingController();
//   final TextEditingController _contactController = TextEditingController();
//   final TextEditingController _emailController = TextEditingController();
//
//   String? propertyType;
//   String? category;
//   List<String> amenities = [];
//   TimeOfDay? checkInTime;
//   TimeOfDay? checkOutTime;
//   bool isPetFriendly = false;
//   bool isSmokingAllowed = false;
//
//   final List<String> hotelTypes = ["Sharing", "Single", "Couple", "Party"];
//
//   // Image picker
//   Future<void> _pickImages() async {
//     final pickedImages = await _picker.pickMultiImage();
//     if (pickedImages != null && pickedImages.length <= 6) {
//       setState(() {
//         images = pickedImages;
//       });
//     } else if (pickedImages != null) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//         content: Text('You can select up to 6 images only.'),
//       ));
//     }
//   }
//
//   // Save form data
//   void _saveProperty() {
//     if (_formKey.currentState!.validate()) {
//       // Perform save action
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//         content: Text('Property saved successfully!'),
//       ));
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("List Your Property"),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.save),
//             onPressed: _saveProperty,
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.all(16),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Property images
//               _buildSectionTitle("Property Images (up to 6)"),
//               GestureDetector(
//                 onTap: _pickImages,
//                 child: Container(
//                   height: 100,
//                   decoration: BoxDecoration(
//                     color: Colors.grey[300],
//                     borderRadius: BorderRadius.circular(8.0),
//                   ),
//                   child: Center(
//                     child: images.isEmpty
//                         ? Icon(Icons.add_a_photo, size: 40)
//                         : ListView.builder(
//                       scrollDirection: Axis.horizontal,
//                       itemCount: images.length,
//                       itemBuilder: (context, index) {
//                         return Padding(
//                           padding: EdgeInsets.all(4.0),
//                           child: Image.file(
//                             File(images[index].path),
//                             width: 80,
//                             height: 80,
//                             fit: BoxFit.cover,
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 ),
//               ),
//               SizedBox(height: 16),
//
//               // Property basic details
//               _buildSectionTitle("Basic Property Details"),
//               _buildTextField(_propertyNameController, "Property Name", Icons.business),
//               _buildDropdownField("Property Type", ["Apartment", "House", "Villa", "Cabin"], (value) {
//                 setState(() => propertyType = value);
//               }),
//               _buildDropdownField("Category", hotelTypes, (value) {
//                 setState(() => category = value);
//               }),
//               _buildTextField(_addressController, "Address", Icons.location_on),
//               Row(
//                 children: [
//                   Expanded(child: _buildTextField(_cityController, "City", Icons.location_city)),
//                   SizedBox(width: 8),
//                   Expanded(child: _buildTextField(_stateController, "State", Icons.map)),
//                 ],
//               ),
//               Row(
//                 children: [
//                   Expanded(child: _buildTextField(_countryController, "Country", Icons.flag)),
//                   SizedBox(width: 8),
//                   Expanded(child: _buildTextField(_zipCodeController, "Zip Code", Icons.pin_drop)),
//                 ],
//               ),
//               SizedBox(height: 16),
//
//               // Property description
//               _buildSectionTitle("Property Description"),
//               _buildTextField(_descriptionController, "Description", Icons.description, maxLines: 5),
//
//               // Amenities
//               _buildSectionTitle("Amenities"),
//               Wrap(
//                 spacing: 8.0,
//                 children: ["Wi-Fi", "Pool", "Gym", "Kitchen", "Air Conditioning", "Parking"]
//                     .map((amenity) => FilterChip(
//                   label: Text(amenity),
//                   selected: amenities.contains(amenity),
//                   onSelected: (selected) {
//                     setState(() {
//                       if (selected) {
//                         amenities.add(amenity);
//                       } else {
//                         amenities.remove(amenity);
//                       }
//                     });
//                   },
//                 ))
//                     .toList(),
//               ),
//               SizedBox(height: 16),
//
//               // Pricing
//               _buildSectionTitle("Pricing"),
//               _buildTextField(_priceController, "Price per Night", Icons.attach_money, isNumeric: true),
//               _buildTextField(_cleaningFeeController, "Cleaning Fee (optional)", Icons.cleaning_services, isNumeric: true),
//               _buildTextField(_securityDepositController, "Security Deposit (optional)", Icons.security, isNumeric: true),
//               SizedBox(height: 16),
//
//               // Policies
//               _buildSectionTitle("Policies"),
//               _buildTimePicker("Check-in Time", (selectedTime) => checkInTime = selectedTime),
//               _buildTimePicker("Check-out Time", (selectedTime) => checkOutTime = selectedTime),
//               SwitchListTile(
//                 title: Text("Pet-Friendly"),
//                 value: isPetFriendly,
//                 onChanged: (value) => setState(() => isPetFriendly = value),
//               ),
//               SwitchListTile(
//                 title: Text("Smoking Allowed"),
//                 value: isSmokingAllowed,
//                 onChanged: (value) => setState(() => isSmokingAllowed = value),
//               ),
//               SizedBox(height: 16),
//
//               // Guest capacity and contact
//               _buildSectionTitle("Guest Capacity & Contact"),
//               _buildTextField(_maxGuestsController, "Maximum Guests", Icons.group, isNumeric: true),
//               _buildTextField(_contactController, "Contact Number", Icons.phone, isNumeric: true),
//               _buildTextField(_emailController, "Email", Icons.email),
//
//               SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: _saveProperty,
//                 child: Text("Save Property"),
//                 style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSectionTitle(String title) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8.0),
//       child: Text(
//         title,
//         style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//       ),
//     );
//   }
//
//   Widget _buildTextField(TextEditingController controller, String hint, IconData icon,
//       {bool isNumeric = false, int maxLines = 1}) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16.0),
//       child: TextFormField(
//         controller: controller,
//         keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
//         maxLines: maxLines,
//         decoration: InputDecoration(
//           prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
//           hintText: hint,
//           filled: true,
//           fillColor: Colors.grey[100],
//           contentPadding: const EdgeInsets.symmetric(vertical: 18),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12.0),
//             borderSide: BorderSide.none,
//           ),
//         ),
//         validator: (value) {
//           if (value == null || value.isEmpty) return 'Please enter $hint';
//           return null;
//         },
//       ),
//     );
//   }
//
//   Widget _buildDropdownField(String label, List<String> options, ValueChanged<String?> onChanged) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16.0),
//       child: DropdownButtonFormField<String>(
//         decoration: InputDecoration(
//           labelText: label,
//           filled: true,
//           fillColor: Colors.grey[100],
//           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
//         ),
//         value: label == "Property Type" ? propertyType : category,
//         items: options.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
//         onChanged: onChanged,
//         validator: (value) => value == null ? 'Please select $label' : null,
//       ),
//     );
//   }
//
//   Widget _buildTimePicker(String label, ValueChanged<TimeOfDay?> onTimePicked) {
//     return ListTile(
//       title: Text(label),
//       trailing: Icon(Icons.access_time),
//       onTap: () async {
//         TimeOfDay? selectedTime = await showTimePicker(
//           context: context,
//           initialTime: TimeOfDay.now(),
//         );
//         onTimePicked(selectedTime);
//       },
//     );
//   }
// }
// import 'dart:io';
//
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
//
// class HostPropertyListingScreen extends StatefulWidget {
//   @override
//   _HostPropertyListingScreenState createState() => _HostPropertyListingScreenState();
// }
//
// class _HostPropertyListingScreenState extends State<HostPropertyListingScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final ImagePicker _picker = ImagePicker();
//   List<XFile> images = [];
//
//   // Controllers for form fields
//   final TextEditingController _propertyNameController = TextEditingController();
//   final TextEditingController _addressController = TextEditingController();
//   final TextEditingController _cityController = TextEditingController();
//   final TextEditingController _stateController = TextEditingController();
//   final TextEditingController _countryController = TextEditingController();
//   final TextEditingController _zipCodeController = TextEditingController();
//   final TextEditingController _descriptionController = TextEditingController();
//   final TextEditingController _priceController = TextEditingController();
//   final TextEditingController _cleaningFeeController = TextEditingController();
//   final TextEditingController _securityDepositController = TextEditingController();
//   final TextEditingController _maxGuestsController = TextEditingController();
//   final TextEditingController _contactController = TextEditingController();
//   final TextEditingController _emailController = TextEditingController();
//
//   String? propertyType;
//   String? category;
//   List<String> amenities = [];
//   TimeOfDay? checkInTime;
//   TimeOfDay? checkOutTime;
//   bool isPetFriendly = false;
//   bool isSmokingAllowed = false;
//
//   final List<String> hotelTypes = ["Sharing", "Single", "Couple", "Party"];
//
//   // Image picker
//   Future<void> _pickImages() async {
//     final pickedImages = await _picker.pickMultiImage();
//     if (pickedImages != null && pickedImages.length <= 6) {
//       setState(() {
//         images = pickedImages;
//       });
//     } else if (pickedImages != null) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//         content: Text('You can select up to 6 images only.'),
//       ));
//     }
//   }
//
//   // Save form data
//   void _saveProperty() {
//     if (_formKey.currentState!.validate()) {
//       // Perform save action
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//         content: Text('Property saved successfully!'),
//       ));
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("List Your Property"),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.save),
//             onPressed: _saveProperty,
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.all(16),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Property images
//               _buildSectionTitle("Property Images (up to 6)"),
//               GestureDetector(
//                 onTap: _pickImages,
//                 child: Container(
//                   height: 100,
//                   decoration: BoxDecoration(
//                     color: Colors.grey[300],
//                     borderRadius: BorderRadius.circular(8.0),
//                   ),
//                   child: Center(
//                     child: images.isEmpty
//                         ? Icon(Icons.add_a_photo, size: 40)
//                         : ListView.builder(
//                       scrollDirection: Axis.horizontal,
//                       itemCount: images.length,
//                       itemBuilder: (context, index) {
//                         return Padding(
//                           padding: EdgeInsets.all(4.0),
//                           child: Image.file(
//                             File(images[index].path),
//                             width: 80,
//                             height: 80,
//                             fit: BoxFit.cover,
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                 ),
//               ),
//               SizedBox(height: 16),
//
//               // Property basic details
//               _buildSectionTitle("Basic Property Details"),
//               _buildTextField(_propertyNameController, "Property Name", Icons.business),
//               _buildDropdownField("Property Type", ["Apartment", "House", "Villa", "Cabin"], (value) {
//                 setState(() => propertyType = value);
//               }),
//               _buildDropdownField("Category", hotelTypes, (value) {
//                 setState(() => category = value);
//               }),
//               _buildTextField(_addressController, "Address", Icons.location_on),
//               Row(
//                 children: [
//                   Expanded(child: _buildTextField(_cityController, "City", Icons.location_city)),
//                   SizedBox(width: 8),
//                   Expanded(child: _buildTextField(_stateController, "State", Icons.map)),
//                 ],
//               ),
//               Row(
//                 children: [
//                   Expanded(child: _buildTextField(_countryController, "Country", Icons.flag)),
//                   SizedBox(width: 8),
//                   Expanded(child: _buildTextField(_zipCodeController, "Zip Code", Icons.pin_drop)),
//                 ],
//               ),
//               SizedBox(height: 16),
//
//               // Property description
//               _buildSectionTitle("Property Description"),
//               _buildTextField(_descriptionController, "Description", Icons.description, maxLines: 5),
//
//               // Amenities
//               _buildSectionTitle("Amenities"),
//               Wrap(
//                 spacing: 8.0,
//                 children: ["Wi-Fi", "Pool", "Gym", "Kitchen", "Air Conditioning", "Parking"]
//                     .map((amenity) => FilterChip(
//                   label: Text(amenity),
//                   selected: amenities.contains(amenity),
//                   onSelected: (selected) {
//                     setState(() {
//                       if (selected) {
//                         amenities.add(amenity);
//                       } else {
//                         amenities.remove(amenity);
//                       }
//                     });
//                   },
//                 ))
//                     .toList(),
//               ),
//               SizedBox(height: 16),
//
//               // Pricing
//               _buildSectionTitle("Pricing"),
//               _buildTextField(_priceController, "Price per Night", Icons.attach_money, isNumeric: true),
//               _buildTextField(_cleaningFeeController, "Cleaning Fee (optional)", Icons.cleaning_services, isNumeric: true),
//               _buildTextField(_securityDepositController, "Security Deposit (optional)", Icons.security, isNumeric: true),
//               SizedBox(height: 16),
//
//               // Policies
//               _buildSectionTitle("Policies"),
//               _buildTimePicker("Check-in Time", (selectedTime) => checkInTime = selectedTime),
//               _buildTimePicker("Check-out Time", (selectedTime) => checkOutTime = selectedTime),
//               SwitchListTile(
//                 title: Text("Pet-Friendly"),
//                 value: isPetFriendly,
//                 onChanged: (value) => setState(() => isPetFriendly = value),
//               ),
//               SwitchListTile(
//                 title: Text("Smoking Allowed"),
//                 value: isSmokingAllowed,
//                 onChanged: (value) => setState(() => isSmokingAllowed = value),
//               ),
//               SizedBox(height: 16),
//
//               // Guest capacity and contact
//               _buildSectionTitle("Guest Capacity & Contact"),
//               _buildTextField(_maxGuestsController, "Maximum Guests", Icons.group, isNumeric: true),
//               _buildTextField(_contactController, "Contact Number", Icons.phone, isNumeric: true),
//               _buildTextField(_emailController, "Email", Icons.email),
//
//               SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: _saveProperty,
//                 child: Text("Save Property"),
//                 style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSectionTitle(String title) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8.0),
//       child: Text(
//         title,
//         style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//       ),
//     );
//   }
//
//   Widget _buildTextField(TextEditingController controller, String hint, IconData icon,
//       {bool isNumeric = false, int maxLines = 1}) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16.0),
//       child: TextFormField(
//         controller: controller,
//         keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
//         maxLines: maxLines,
//         decoration: InputDecoration(
//           prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
//           hintText: hint,
//           filled: true,
//           fillColor: Colors.grey[100],
//           contentPadding: const EdgeInsets.symmetric(vertical: 18),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12.0),
//             borderSide: BorderSide.none,
//           ),
//         ),
//         validator: (value) {
//           if (value == null || value.isEmpty) return 'Please enter $hint';
//           return null;
//         },
//       ),
//     );
//   }
//
//   Widget _buildDropdownField(String label, List<String> options, ValueChanged<String?> onChanged) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16.0),
//       child: DropdownButtonFormField<String>(
//         decoration: InputDecoration(
//           labelText: label,
//           filled: true,
//           fillColor: Colors.grey[100],
//           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
//         ),
//         value: label == "Property Type" ? propertyType : category,
//         items: options.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
//         onChanged: onChanged,
//         validator: (value) => value == null ? 'Please select $label' : null,
//       ),
//     );
//   }
//
//   Widget _buildTimePicker(String label, ValueChanged<TimeOfDay?> onTimePicked) {
//     return ListTile(
//       title: Text(label),
//       trailing: Icon(Icons.access_time),
//       onTap: () async {
//         TimeOfDay? selectedTime = await showTimePicker(
//           context: context,
//           initialTime: TimeOfDay.now(),
//         );
//         onTimePicked(selectedTime);
//       },
//     );
//   }
// }
