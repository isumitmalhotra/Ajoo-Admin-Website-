import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:iconsax/iconsax.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/widgets/app_ui.dart'
    show AppCard, InfoRow, withDividers;
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/ui/screens_common/auth/auth_controller.dart';
import 'package:rent_home/data/models/host_properties_reponse.dart';
import 'package:rent_home/ui/screens_host/add_property/host_property_listing_screen.dart';
import 'package:rent_home/ui/screens_host/host_controller.dart';
import 'package:rent_home/ui/screens_host/property_details/view_host_property_details.dart';
import 'package:rent_home/ui/screens_host/update_property/update_property_page.dart';
import 'package:rent_home/ui/screens_common/update_profile/update_profile_screen.dart';
import 'package:rent_home/ui/screens_host/profile/host_menu.dart';
import 'package:shimmer/shimmer.dart';
import 'package:rent_home/utils/input_sanitizers.dart';

class HostProfilePage extends StatefulWidget {
  const HostProfilePage({super.key});

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
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
    if (pickedFile != null) {
      setState(() {
        _profileImage = pickedFile;
      });
    }
  }

  Future<void> _pickCoverImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024, imageQuality: 85);
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
    final formKey = GlobalKey<FormState>();

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
                      inputFormatters: AppInputFormatters.upperAlnum(20),
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
                          if (formKey.currentState!.validate() &&
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
      // This screen has no AppBar and sits in the shell's IndexedStack, so
      // nothing was insetting it: the header row rendered underneath the
      // status bar, with the clock sitting on top of "Profile" and the
      // signal icons over the menu button — which also swallowed taps on it.
      // The hero band runs to the top of the screen, so this must NOT be
      // inset at the top — SafeArea handles the status bar inside the header
      // instead, which is how the guest profile does it.
      body: RefreshIndicator(
        onRefresh: () async {
          hostController.getHostProperties();
          hostController.getHostOngoing(user?.userId ?? 0);
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Teal hero, same as the guest profile.
              //
              // The host's version of this page opened with a bare "Profile"
              // heading and an avatar sitting on plain ivory, so the two
              // profiles in one app looked like they came from two apps. The
              // client asked for the host's to match the guest's; this is the
              // same gradient band, the same white avatar ring, the same
              // name-and-role stack. The menu button keeps its corner.
              _HostProfileHero(
                name: user?.fullName ?? 'Host',
                image: _profileImage,
                onPickImage: _pickProfileImage,
                onOpenMenu: () => showHostMenu(context),
              ),
              const SizedBox(height: 18),
              Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information section
              _buildSectionTitle("Basic Information"),
              const SizedBox(height: 8),
              AppCard(
                child: Column(
                  children: withDividers([
                    InfoRow(Icons.person_outline, "Name",
                        authController.userData.value?.fullName ?? "—"),
                    // "4.8 / 5" was a literal shown to every host. There is no
                    // host rating in the data — not even a column — so the row
                    // is gone rather than made up. It comes back when hosts
                    // are actually rated.
                    InfoRow(Icons.cake_outlined, "DOB",
                        (user?.dob ?? "").isEmpty ? "—" : user!.dob),
                  ]),
                ),
              ),
              const SizedBox(height: 20),

              // Contact Details section
              _buildSectionTitle("Contact Details"),
              const SizedBox(height: 8),
              AppCard(
                child: Column(
                  children: withDividers([
                    InfoRow(Icons.email_outlined, "Email",
                        (user?.email ?? "").isEmpty ? "—" : user!.email),
                    InfoRow(Icons.phone_outlined, "Phone",
                        (user?.phoneNumber ?? "").isEmpty
                            ? "—"
                            : user!.phoneNumber),
                  ]),
                ),
              ),
              const SizedBox(height: 20),

              // KYC Verification section
              _buildSectionTitle("KYC Verification"),
              const SizedBox(height: 8),
              Obx(() {
                final verified =
                    authController.userData.value?.isKycVerified ?? false;
                return AppCard(
                  child: Row(
                    children: [
                      Icon(
                          verified
                              ? Icons.verified
                              : Icons.gpp_maybe_outlined,
                          color: verified ? kSuccess : const Color(0xFFB26A00)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          verified
                              ? 'Identity verified'
                              : 'Identity not verified yet',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, color: kInk),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
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
              const SizedBox(height: 12),

              // Managed Properties section
              _buildSectionTitle("Managed Properties", icon: Icons.add,
                  onTapIcon: () {
                Navigator.push<void>(
                  context,
                  CupertinoPageRoute<void>(
                    builder: (BuildContext context) =>
                        const HostPropertyListingScreen(),
                  ),
                );
              }),
              const SizedBox(height: 10),

              // Sort — tens of thousands of listings need an order a person
              // chose. Server-side; mirrors the web host portal's dropdown.
              Obx(() {
                const options = <String, String>{
                  'newest': 'Newest first',
                  'name_az': 'Name A–Z',
                  'name_za': 'Name Z–A',
                  'price_low': 'Price: low → high',
                  'price_high': 'Price: high → low',
                };
                final current = hostController.propertySort.value;
                return Align(
                  alignment: Alignment.centerLeft,
                  child: PopupMenuButton<String>(
                    initialValue: current,
                    onSelected: hostController.setPropertySort,
                    itemBuilder: (_) => options.entries
                        .map((e) => PopupMenuItem<String>(
                            value: e.key, child: Text(e.value)))
                        .toList(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: kSurface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: kLine),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.sort_rounded,
                              size: 15, color: kInk2),
                          const SizedBox(width: 6),
                          Text(options[current] ?? 'Sort',
                              style: inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: kInk2)),
                          const Icon(Icons.arrow_drop_down,
                              size: 18, color: kInk2),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),

              Obx(() {
                final props = hostController
                        .hostPropertiesResponse.value?.data?.properties ??
                    const [];

                // Initial shimmer only while the first fetch is in-flight.
                if (hostController.loading.value && props.isEmpty) {
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
                }

                if (props.isNotEmpty) {
                  // The list is one page of a paginated endpoint now, so it has
                  // to say how much of the account it is showing and offer the
                  // rest. Rendering all of it is not an option — the test host
                  // owns 29,230.
                  final total = hostController.hostPropertyCount;
                  return Column(
                    children: [
                      ...List.generate(props.length, (index) {
                        final property = props[index];
                        return _buildPropertyTile(property);
                      }),
                      if (hostController.hasMoreProperties) ...[
                        const SizedBox(height: 6),
                        Text(
                          "Showing ${props.length} of $total listings",
                          style: const TextStyle(fontSize: 12, color: kMuted),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: hostController.loadingMore.value
                                ? null
                                : hostController.loadMoreHostProperties,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kprimaryColor,
                              side: const BorderSide(color: kLine),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(hostController.loadingMore.value
                                ? "Loading…"
                                : "Load more"),
                          ),
                        ),
                      ],
                    ],
                  );
                }

                // No properties yet (or fetch failed) — friendly CTA either way.
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: kCream,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: kLine),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.home_work_outlined,
                          size: 44, color: kMuted),
                      const SizedBox(height: 10),
                      const Text(
                        "No properties listed yet",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: kInk,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Add your first property to start receiving bookings.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: kMuted),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text("Add Property"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kprimaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            Navigator.push<void>(
                              context,
                              CupertinoPageRoute<void>(
                                builder: (_) =>
                                    const HostPropertyListingScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 24),
              // A-78 — every page a host can reach, on the profile.
              //
              // These lived only in the home drawer, which opens from the
              // Dashboard tab's header: a host sitting on Profile could not
              // reach Payouts, Bank Account, Terms, Privacy or even Logout.
              // Same list the drawer renders, from one declaration.
              //
              // Below the listings, on the client's instruction. A host opens
              // this page to look at their properties; the menu is somewhere
              // you go afterwards, and sitting above the listings it pushed
              // them a full screen down.
              _buildSectionTitle('Menu'),
              const SizedBox(height: 10),
              const HostMenuList(),
              const SizedBox(height: 8),
            ],
          ),
              ),
              const SizedBox(height: 8),
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

    final isActive = property.isActive;
    final isLuxury = (property.isLuxury == 1);

    // Admin-approval status (mirrors web): host submissions stay Pending until
    // an admin approves; rejected listings show the rejected state.
    final vs = property.verificationStatus.toLowerCase();
    final bool approved =
        (property.isActive && property.isVerify) || vs == 'verified' || vs == 'approved';
    // Whether the ADMIN has cleared this listing — deliberately independent of
    // isActive, which is the host's own on/off. Folding isActive into the
    // approval test made the pause switch vanish the moment it was used: the
    // listing stopped counting as approved, the control that had just been
    // flipped disappeared, and the host had no way to turn it back on.
    final bool adminCleared =
        property.isVerify || vs == 'verified' || vs == 'approved';
    // is_verify carries the rejection too, and it is the field the admin's
    // decision actually writes — verification_status stays "unverified" on a
    // rejected listing, which is how a turned-down stay sat under "Pending
    // review" telling the host to keep waiting for a decision already made.
    final bool rejected =
        property.isRejected || vs == 'rejected' || vs == 'declined';
    final String statusLabel =
        approved ? 'Approved' : (rejected ? 'Rejected' : 'Pending review');
    final Color statusColor =
        approved ? Colors.green : (rejected ? Colors.red : Colors.orange);
    final IconData statusIcon = approved
        ? Icons.verified
        : (rejected ? Icons.cancel : Icons.hourglass_bottom);

    final String? cover = property.coverImage?.toString();
    final bool hasCover = cover != null && cover.isNotEmpty && cover != 'null';
    final String checkIn =
        (property.propDetailsPropDetailInTime ?? '-').toString();
    final String checkOut =
        (property.propDetailsPropDetailOutTime ?? '-').toString();

    return GestureDetector(
      onTap: () => Get.to(() => HostPropertyDetails(property: property)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: kCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero cover with overlays
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: hasCover
                      ? Image.network(cover!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              color: kSand,
                              child: const Icon(
                                  Icons.image_not_supported_outlined,
                                  color: kMuted)))
                      : Image.asset("assets/home_1.jpg", fit: BoxFit.cover),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.center,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, kInk.withOpacity(0.42)],
                      ),
                    ),
                  ),
                ),
                // status pill
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.94),
                        borderRadius: BorderRadius.circular(999)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 5),
                      Text(statusLabel,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: statusColor)),
                    ]),
                  ),
                ),
                // luxury + edit (top-right)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(children: [
                    if (isLuxury)
                      Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.94),
                            borderRadius: BorderRadius.circular(999)),
                        child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.star,
                                  size: 12, color: kIndigo),
                              SizedBox(width: 4),
                              Text('Luxury',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: kIndigo)),
                            ]),
                      ),
                    Material(
                      color: Colors.white.withOpacity(0.94),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Get.to(
                            () => UpdatePropertyPage(property: property)),
                        child: const Padding(
                          padding: EdgeInsets.all(7),
                          child:
                              Icon(Iconsax.edit4, size: 16, color: kIndigo),
                        ),
                      ),
                    ),
                  ]),
                ),
                // price pill
                Positioned(
                  left: 10,
                  bottom: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('₹${property.propertyPrice}',
                          style: fraunces(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: kInk)),
                      const Text(' /night',
                          style: TextStyle(fontSize: 10, color: kMuted)),
                    ]),
                  ),
                ),
              ],
            ),
            // details
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(property.propertyName,
                      style: fraunces(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: kInk),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on, size: 15, color: kClay),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(property.propertyAddress,
                          style:
                              const TextStyle(fontSize: 12.5, color: kInk2),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Wrap(spacing: 6, runSpacing: 4, children: [
                    _buildChip(
                        label: 'In $checkIn · Out $checkOut',
                        color: kInk2,
                        icon: Icons.schedule),
                  ]),
                  // Active/Paused was a badge that only reported the state —
                  // pausing a listing meant opening it first. It is a switch
                  // now, and flipping it patches this one row through the
                  // controller instead of refetching the whole list. Only
                  // approved listings get it: there is nothing to pause while
                  // the listing is still waiting on (or turned down by) an
                  // admin.
                  if (adminCleared && !rejected) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      Expanded(
                        child: Text(
                          isActive
                              ? 'Active — visible to guests'
                              : 'Paused — hidden from guests',
                          style:
                              const TextStyle(fontSize: 12.5, color: kInk2),
                        ),
                      ),
                      Transform.scale(
                        scale: 0.85,
                        child: Switch(
                          value: isActive,
                          activeColor: kSuccess,
                          activeTrackColor: kSuccess.withOpacity(0.35),
                          inactiveThumbColor: kMuted,
                          inactiveTrackColor: kMuted.withOpacity(0.3),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          onChanged: (v) => hostController.setPropertyActive(
                              property.propertyId, v),
                        ),
                      ),
                    ]),
                  ],
                ],
              ),
            ),
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
            style: const TextStyle(
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

/// The host profile's hero band — the guest profile's header, for hosts.
///
/// The two profiles in this app used to look like they came from two different
/// apps: the guest's opened on a teal gradient with the avatar in a white
/// ring, the host's on a bare heading over ivory. The client asked for one
/// look, and the guest's is the one the website matches.
///
/// The status bar is handled here rather than by a Scaffold-level SafeArea,
/// because the gradient is supposed to run under it.
class _HostProfileHero extends StatelessWidget {
  const _HostProfileHero({
    required this.name,
    required this.image,
    required this.onPickImage,
    required this.onOpenMenu,
  });

  final String name;
  final XFile? image;
  final VoidCallback onPickImage;
  final VoidCallback onOpenMenu;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [kIndigo, kIndigo600],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 8, 24),
          child: Column(
            children: [
              Row(
                children: [
                  Text('Profile',
                      style: fraunces(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Menu',
                    icon: const Icon(Icons.menu_rounded,
                        size: 24, color: Colors.white),
                    // A-79 — slides the menu in from the right. This was a
                    // Scaffold endDrawer, which never opened: this page is
                    // nested inside the shell's IndexedStack, so its Scaffold
                    // is a child of MainScreen's and never gets a drawer
                    // surface of its own. The button was inert on device.
                    onPressed: onOpenMenu,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black26,
                            blurRadius: 14,
                            spreadRadius: 2),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 52,
                      backgroundColor: kCream,
                      backgroundImage: image != null
                          ? FileImage(File(image!.path))
                          : const AssetImage('assets/boy.png')
                              as ImageProvider,
                    ),
                  ),
                  Material(
                    color: kClay,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onPickImage,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.camera_alt,
                            size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(name,
                  textAlign: TextAlign.center,
                  style: fraunces(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('Host',
                    style: inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
