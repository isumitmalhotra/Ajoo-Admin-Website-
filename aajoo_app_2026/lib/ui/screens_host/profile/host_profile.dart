import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/ui/screens_common/auth/auth_controller.dart';
import 'package:rent_home/data/models/host_properties_reponse.dart';
import 'package:rent_home/ui/screens_host/add_property/host_property_listing_screen.dart';
import 'package:rent_home/ui/screens_host/host_controller.dart';
import 'package:rent_home/ui/screens_host/property_details/view_host_property_details.dart';
import 'package:rent_home/ui/screens_host/update_property/update_property_page.dart';
import 'package:rent_home/ui/screens_common/update_profile/update_profile_screen.dart';
import 'package:shimmer/shimmer.dart';
import '../add_property/legacy_new_property_screen.dart';

class HostProfilePage extends StatefulWidget {
  @override
  _HostProfilePageState createState() => _HostProfilePageState();
}

class _HostProfilePageState extends State<HostProfilePage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _profileImage;
  XFile? coverImage;

  // Simulated data for properties
  final List<Map<String, String>> properties = [];

  // Pick profile image
  Future<void> _pickProfileImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = pickedFile;
      });
    }
  }

  Future<void> _pickCoverImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        coverImage = pickedFile;
      });
    }
  }

  // Pick KYC document
  Future<XFile?> _pickKycDocument() async {
    final pickedFile = await _picker.pickMedia();
    if (pickedFile != null) {
      return pickedFile;
    }
    return null;
  }

  // Show bottom sheet for KYC upload
  void _showKycBottomSheet(BuildContext context) {
    XFile? selectedFile;
    final TextEditingController cardNumberController = TextEditingController();
    final _formKey = GlobalKey<FormState>();

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
                key: _formKey,
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
                    const SizedBox(height: 16),
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
                          color: kSand,
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
                                        style: TextStyle(color: kMuted)),
                                  ],
                                )
                              : Text(
                                  selectedFile!.name,
                                  style: const TextStyle(
                                      fontSize: 16, color: Colors.black87),
                                  textAlign: TextAlign.center,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: cardNumberController,
                      decoration: InputDecoration(
                        labelText: 'Card Number (e.g., Aadhaar, Passport)',
                        prefixIcon:
                            const Icon(Iconsax.card, color: kprimaryColor),
                        filled: true,
                        fillColor: kCream,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      keyboardType: TextInputType.text,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the card number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate() &&
                              selectedFile != null) {
                            // Placeholder for upload action
                            print(
                                'Uploading KYC: ${selectedFile!.path}, Card Number: ${cardNumberController.text}');
                            Get.snackbar(
                              'Success',
                              'KYC document submitted for verification',
                              backgroundColor: kprimaryColor,
                              colorText: Colors.white,
                              snackPosition: SnackPosition.BOTTOM,
                            );
                            Navigator.pop(context);
                          } else {
                            Get.snackbar(
                              'Error',
                              'Please select a document and enter a card number',
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

  final HostController hostController = Get.find<HostController>();
  @override
  void initState() {
    super.initState();
    try {
      hostController.getHostProperties();
    } catch (e) {}
  }

  final AuthController authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    final user = authController.userData.value;
    return Scaffold(
      backgroundColor: kscaffoldColor,
      body: RefreshIndicator(
        onRefresh: () async {
          hostController.getHostProperties();
          hostController.getHostOngoing(user?.userId ?? 0);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile photo section
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: _profileImage != null
                          ? FileImage(File(_profileImage!.path))
                          : const AssetImage('assets/boy.png') as ImageProvider,
                      backgroundColor: kSand,
                    ),
                    IconButton(
                      icon: const Icon(Icons.camera_alt,
                          color: Colors.blueAccent),
                      onPressed: _pickProfileImage,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Basic Information section
              _buildSectionTitle("Basic Information"),
              _buildInfoRow(
                  "Name", authController.userData.value?.fullName ?? ""),
              _buildInfoRow("Host Rating", "4.8 / 5"),
              _buildInfoRow("DOB", user?.dob ?? ""),
              const SizedBox(height: 20),

              // Contact Details section
              _buildSectionTitle("Contact Details"),
              _buildInfoRow("Email", user?.email ?? ""),
              _buildInfoRow("Phone", user?.phoneNumber ?? ""),
              const SizedBox(height: 20),

              // KYC Verification section
              _buildSectionTitle("KYC Verification"),
              // Card(
              //   elevation: 0,
              //   shape: RoundedRectangleBorder(
              //       borderRadius: BorderRadius.circular(12)),
              //   child: ListTile(
              //     leading: const Icon(Iconsax.document_upload,
              //         color: kprimaryColor, size: 24),
              //     title: const Text(
              //       'Upload KYC Document',
              //       style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              //     ),
              //     subtitle: const Text(
              //       'Submit ID proof for government verification',
              //       style: TextStyle(fontSize: 14, color: Colors.grey),
              //     ),
              //     trailing: const Icon(Iconsax.arrow_right_3,
              //         color: kprimaryColor, size: 20),
              //     onTap: () => _showKycBottomSheet(context),
              //   ),
              // ),
              // const SizedBox(height: 20),

              // Edit Profile section
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: ListTile(
                  leading: const Icon(Icons.edit, color: kprimaryColor),
                  title: const Text(
                    'Edit Profile',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Update your personal information'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Get.to(() => const UpdateProfileScreen());
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Managed Properties section
              _buildSectionTitle("Managed Properties", icon: Icons.add,
                  onTapIcon: () {
                Navigator.push<void>(
                  context,
                  CupertinoPageRoute<void>(
                    builder: (BuildContext context) =>
                        HostPropertyListingScreen(),
                  ),
                );
              }),
              const SizedBox(height: 10),

              Obx(() {
                // Check if data is loading
                if (hostController.loading.value) {
                  // Display shimmer effect without nested scrollables
                  return Column(
                    children: List.generate(6, (index) {
                      return Shimmer.fromColors(
                        baseColor: kLine,
                        highlightColor: kCream,
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const ListTile(
                            title: SizedBox(
                              height: 20,
                              child: DecoratedBox(
                                decoration: BoxDecoration(color: Colors.white),
                              ),
                            ),
                            subtitle: SizedBox(
                              height: 16,
                              child: DecoratedBox(
                                decoration: BoxDecoration(color: Colors.white),
                              ),
                            ),
                            trailing: Icon(Icons.arrow_forward_ios,
                                color: Colors.white),
                          ),
                        ),
                      );
                    }),
                  );
                } else if (hostController.hostPropertiesResponse.value?.data
                        ?.properties.isNotEmpty ??
                    false) {
                  final props = hostController
                          .hostPropertiesResponse.value?.data?.properties ??
                      [];
                  return Column(
                    children: List.generate(props.length, (index) {
                      final property = props[index];
                      return _buildPropertyTile(property);
                    }),
                  );
                } else if (hostController.error.value != "") {
                  // Handle no data scenario
                  return Center(
                    child: Image.asset("assets/noProperty.png"),
                  );
                } else {
                  return const Center();
                }
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(
      {required String label, required Color color, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(right: 6, bottom: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildInfoIconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[700]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyTile(Property? property) {
    if (property == null) return const SizedBox.shrink();

    final isVerified = property.isVerify;
    final isActive = property.isActive;
    final isLuxury = (property.isLuxury == 1);

    final String? cover = property.coverImage?.toString();
    final bool hasCover = cover != null && cover.isNotEmpty && cover != 'null';
    final List<String> imgs = property.images.cast<String>();
    final String checkIn =
        (property.propDetailsPropDetailInTime ?? '-').toString();
    final String checkOut =
        (property.propDetailsPropDetailOutTime ?? '-').toString();

    return GestureDetector(
      onTap: () => Get.to(() => HostPropertyDetails(property: property)),
      child: Card(
        color: kCream,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: kLine)),
        elevation: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                          width: 72,
                          height: 72,
                          color: kSand,
                          child: hasCover
                              ? Image.network(cover, fit: BoxFit.cover)
                              : Image.asset("assets/home_1.jpg",
                                  fit: BoxFit.cover))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              property.propertyName,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                IconButton(
                                  tooltip: 'Edit',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  icon: const Icon(Iconsax.edit4,
                                      size: 18, color: Colors.blueGrey),
                                  onPressed: () {
                                    Get.to(() =>
                                        UpdatePropertyPage(property: property));
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          property.propertyAddress,
                          style:
                              TextStyle(fontSize: 12, color: kInk2),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (isVerified)
                              _buildChip(
                                  label: 'Verified',
                                  color: Colors.green,
                                  icon: Icons.verified)
                            else
                              _buildChip(
                                  label: 'Pending',
                                  color: Colors.orange,
                                  icon: Icons.hourglass_bottom),
                            _buildChip(
                                label: isActive ? 'Active' : 'Inactive',
                                color: isActive ? Colors.blue : Colors.grey,
                                icon: isActive
                                    ? Icons.check_circle_outline
                                    : Icons.pause_circle_outline),
                            if (isLuxury)
                              _buildChip(
                                  label: 'Luxury',
                                  color: Colors.purple,
                                  icon: Icons.star),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.schedule,
                                    size: 14, color: Colors.grey[700]),
                                const SizedBox(width: 4),
                                Text('In: $checkIn',
                                    style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.schedule,
                                    size: 14, color: Colors.grey[700]),
                                const SizedBox(width: 4),
                                Text('Out: $checkOut',
                                    style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Price: ${property.propertyPrice} (min ${property.propertyMiniPrice})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (imgs.isNotEmpty) ...[
              const Divider(height: 1),
              SizedBox(
                height: 90,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: imgs.map((e) {
                      final String url = e;
                      final bool valid = url.isNotEmpty && url != 'null';
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 120,
                            height: 74,
                            color: kSand,
                            child: valid
                                ? Image.network(url, fit: BoxFit.cover)
                                : const Icon(Icons.image, color: Colors.grey),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper method to build section titles
  Widget _buildSectionTitle(String title,
      {IconData? icon, VoidCallback? onTapIcon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: kInk),
          ),
          icon != null
              ? GestureDetector(
                  onTap: onTapIcon,
                  child: Icon(icon, color: kprimaryColor, size: 30),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // 👈 important
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: kMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              softWrap: true, // 👈 allows wrapping
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
