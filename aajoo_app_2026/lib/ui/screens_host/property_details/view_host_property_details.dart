import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rent_home/constants.dart';
import 'dart:io';

import 'package:rent_home/ui/screens_host/host_controller.dart';
import 'package:rent_home/ui/screens_host/update_property/update_property_page.dart';
import 'package:rent_home/data/models/host_properties_reponse.dart';
import 'package:rent_home/widgets/app_ui.dart' show withDividers, InfoRow;
import 'package:rent_home/utils/fonts.dart';

class HostPropertyDetails extends StatefulWidget {
  final Property property;

  const HostPropertyDetails({
    super.key,
    required this.property,
  });

  @override
  State<HostPropertyDetails> createState() => _HostPropertyDetailsState();
}

class _HostPropertyDetailsState extends State<HostPropertyDetails> {
  final HostController hostController = Get.find<HostController>();
  late bool isActive;
  XFile? coverImage;

  @override
  void initState() {
    super.initState();
    isActive = widget.property.isActive;
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
      // Downscaled at pick time. Uploading the camera original meant a
      // 4-12MB file per photo: measured earlier, ~4MB never completed at
      // all and ~180KB took about 90 seconds. image_picker resizes and
      // re-encodes before the file ever reaches us, so this needs no
      // extra package and costs nothing at display size.
    final value = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1920, maxHeight: 1920, imageQuality: 80);
    if (value != null) {
      setState(() {
        hostController.coverImage.value = File(value.path);
        coverImage = value;
      });
    }
  }

  // ── Approval status ────────────────────────────────────────────────────────
  ({String label, Color color, IconData icon}) get _status {
    final p = widget.property;
    final vs = p.verificationStatus.toLowerCase();
    if ((p.isActive && p.isVerify) || vs == 'verified' || vs == 'approved') {
      return (label: 'Approved', color: kSuccess, icon: Icons.verified);
    }
    if (vs == 'rejected' || vs == 'declined') {
      return (label: 'Rejected', color: kDanger, icon: Icons.cancel);
    }
    return (
      label: 'Pending review',
      color: const Color(0xFFB26A00),
      icon: Icons.hourglass_bottom
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.property;
    return Scaffold(
      backgroundColor: kscaffoldColor,
      appBar: AppBar(
        title: const Text('Property Details'),
        backgroundColor: kprimaryColor,
        foregroundColor: kcontentColor,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Get.to(() => UpdatePropertyPage(property: p)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _coverImage(p),
            const SizedBox(height: 16),
            if (coverImage != null) ...[
              _saveCoverButton(p),
              const SizedBox(height: 14),
            ],
            _headerCard(p),
            const SizedBox(height: 14),
            _priceRow(p),
            const SizedBox(height: 14),
            if (_facts(p).isNotEmpty) ...[
              _keyFactsCard(p),
              const SizedBox(height: 14),
            ],
            if (_charges(p).isNotEmpty) ...[
              _chargesCard(p),
              const SizedBox(height: 14),
            ],
            if (p.images.isNotEmpty) ...[
              _imagesCard(p),
              const SizedBox(height: 14),
            ],
            _rulesCard(p),
            const SizedBox(height: 14),
            _contactCard(p),
            const SizedBox(height: 14),
            _statusCard(p),
            const SizedBox(height: 20),
            _actions(p),
          ],
        ),
      ),
    );
  }

  // ── Cover image (hero) ──────────────────────────────────────────────────────
  Widget _coverImage(Property p) {
    final hasNetwork = p.coverImage != null &&
        p.coverImage.toString().isNotEmpty &&
        p.coverImage.toString() != 'null';
    Widget img;
    if (coverImage != null) {
      img = Image.file(File(coverImage!.path), fit: BoxFit.cover);
    } else if (hasNetwork) {
      img = Image.network(p.coverImage.toString(), fit: BoxFit.cover);
    } else {
      img = Container(
        color: kSand,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image_outlined, color: kMuted, size: 40),
              SizedBox(height: 6),
              Text('No cover image', style: TextStyle(color: kMuted)),
            ],
          ),
        ),
      );
    }

    final s = _status;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Stack(
        children: [
          SizedBox(height: 210, width: double.infinity, child: img),
          // status chip
          Positioned(
            top: 12,
            left: 12,
            child: _pill(s.label, s.color, icon: s.icon, solid: true),
          ),
          if (p.isLuxury == 1)
            Positioned(
              top: 12,
              right: 12,
              child: _pill('Luxury', kIndigo,
                  icon: Icons.star, solid: true),
            ),
          // change cover button
          Positioned(
            bottom: 12,
            right: 12,
            child: Material(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(30),
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: _pickImage,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.photo_camera_outlined,
                        color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text('Change cover',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _saveCoverButton(Property p) => SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () async {
            if (hostController.coverImage.value == null) return;
            await hostController
                .updateCoverImage(p.propertyId)
                .then((_) => hostController.getHostProperties());
            if (mounted) setState(() => coverImage = null);
          },
          icon: const Icon(Icons.cloud_upload_outlined, size: 18),
          style: ElevatedButton.styleFrom(
            backgroundColor: kprimaryColor,
            foregroundColor: kcontentColor,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 13),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          label: Obx(() => hostController.loading.value
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: kcontentColor))
              : const Text('Save new cover image',
                  style: TextStyle(fontWeight: FontWeight.w700))),
        ),
      );

  // ── Header (name / id / address) ────────────────────────────────────────────
  Widget _headerCard(Property p) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LISTING #${p.propertyId}',
              style: const TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.5,
                  fontWeight: FontWeight.w600,
                  color: kMuted)),
          const SizedBox(height: 4),
          Text(p.propertyName,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: kInk)),
          if (p.propertyType.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(p.propertyType,
                style: const TextStyle(fontSize: 13, color: kInk2)),
          ],
          if (p.propertyDesc.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(p.propertyDesc,
                style: const TextStyle(
                    fontSize: 14, color: kInk2, height: 1.4)),
          ],
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.location_on, color: kClay, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                [p.propertyAddress, p.areaLocality, p.landmark]
                    .where((e) => e.trim().isNotEmpty)
                    .join(', '),
                style: const TextStyle(fontSize: 13.5, color: kInk2),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  // ── Price row ───────────────────────────────────────────────────────────────
  Widget _priceRow(Property p) {
    return Row(children: [
      Expanded(
          child: _statTile('Price / night', '₹${p.propertyPrice}', kSuccess)),
      const SizedBox(width: 12),
      Expanded(
          child: _statTile(
              'Min. price', '₹${p.propertyMiniPrice}', kIndigo)),
    ]);
  }

  // ── Key facts ────────────────────────────────────────────────────────────────
  List<(IconData, String)> _facts(Property p) {
    final f = <(IconData, String)>[];
    if (p.bathrooms.isNotEmpty) f.add((Icons.bathtub_outlined, '${p.bathrooms} bath'));
    if (p.floorNo.isNotEmpty) f.add((Icons.stairs_outlined, 'Floor ${p.floorNo}'));
    if (p.bookingPref.isNotEmpty) {
      f.add((Icons.bolt_outlined, '${p.bookingPref[0].toUpperCase()}${p.bookingPref.substring(1)} booking'));
    }
    if (p.ownershipType.isNotEmpty) f.add((Icons.key_outlined, p.ownershipType));
    if (p.coupleFriendly) f.add((Icons.favorite_border, 'Couple friendly'));
    if (p.localIdAllowed) f.add((Icons.badge_outlined, 'Local ID ok'));
    if (p.quietHours.isNotEmpty) f.add((Icons.nightlight_outlined, p.quietHours));
    return f;
  }

  Widget _keyFactsCard(Property p) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Highlights'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _facts(p)
                .map((f) => _factChip(f.$1, f.$2))
                .toList(),
          ),
        ],
      ),
    );
  }

  // ── Charges ──────────────────────────────────────────────────────────────────
  List<(String, String)> _charges(Property p) {
    final c = <(String, String)>[];
    if (p.securityDeposit.isNotEmpty) c.add(('Security deposit', '₹${p.securityDeposit}'));
    if (p.weekendPrice.isNotEmpty) c.add(('Weekend / night', '₹${p.weekendPrice}'));
    if (p.cleaningFee.isNotEmpty) c.add(('Cleaning fee', '₹${p.cleaningFee}'));
    if (p.extraGuestCharge.isNotEmpty) c.add(('Extra guest', '₹${p.extraGuestCharge}'));
    if (p.minBookingAmount.isNotEmpty) c.add(('Min. booking', '₹${p.minBookingAmount}'));
    return c;
  }

  Widget _chargesCard(Property p) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Charges'),
          const SizedBox(height: 6),
          ...withDividers(_charges(p)
              .map((c) => InfoRow(Icons.payments_outlined, c.$1, c.$2))
              .toList()),
        ],
      ),
    );
  }

  // ── Images ───────────────────────────────────────────────────────────────────
  Widget _imagesCard(Property p) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Photos'),
          const SizedBox(height: 10),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: p.images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) => ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  p.images[index].toString(),
                  height: 96,
                  width: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 96,
                    width: 120,
                    color: kSand,
                    child: const Icon(Icons.broken_image_outlined,
                        color: kMuted),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Rules / additional info ──────────────────────────────────────────────────
  Widget _rulesCard(Property p) {
    final petOk = (p.propDetailsPropDetailIsPetFriendly ?? false) == true ||
        p.propDetailsPropDetailIsPetFriendly == 1;
    final smokeOk = (p.propDetailsPropDetailIsSmoke ?? false) == true ||
        p.propDetailsPropDetailIsSmoke == 1;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('House rules & timings'),
          const SizedBox(height: 6),
          ...withDividers([
            InfoRow(Icons.pets_outlined, 'Pet friendly', petOk ? 'Yes' : 'No'),
            InfoRow(Icons.smoking_rooms_outlined, 'Smoking allowed',
                smokeOk ? 'Yes' : 'No'),
            InfoRow(Icons.login, 'Check-in',
                (p.propDetailsPropDetailInTime ?? '—').toString()),
            InfoRow(Icons.logout, 'Check-out',
                (p.propDetailsPropDetailOutTime ?? '—').toString()),
          ]),
        ],
      ),
    );
  }

  // ── Contact ──────────────────────────────────────────────────────────────────
  Widget _contactCard(Property p) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Contact'),
          const SizedBox(height: 6),
          ...withDividers([
            InfoRow(Icons.email_outlined, 'Email',
                p.propertyEmail.isEmpty ? '—' : p.propertyEmail),
            InfoRow(Icons.phone_outlined, 'Phone',
                p.propertyContact.isEmpty ? '—' : p.propertyContact),
          ]),
        ],
      ),
    );
  }

  // ── Status toggle ────────────────────────────────────────────────────────────
  Widget _statusCard(Property p) {
    return _card(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Listing visibility'),
                const SizedBox(height: 2),
                Text(isActive ? 'Active — visible to guests' : 'Paused — hidden',
                    style: const TextStyle(fontSize: 12.5, color: kInk2)),
              ],
            ),
          ),
          Switch(
            value: isActive,
            activeColor: kSuccess,
            activeTrackColor: kSuccess.withOpacity(0.35),
            inactiveThumbColor: kDanger,
            inactiveTrackColor: kDanger.withOpacity(0.3),
            onChanged: (value) => _confirmStatus(value),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmStatus(bool value) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Obx(
        () => hostController.loading.value
            ? const Center(child: CircularProgressIndicator(color: kprimaryColor))
            : AlertDialog(
                title: const Text('Update listing status'),
                content: Text(value
                    ? 'Make this listing active and visible to guests?'
                    : 'Pause this listing so guests can\'t see it?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      await hostController
                          .updatePropertyStatus(
                              widget.property.propertyId, value ? 1 : 0)
                          .then((_) => hostController.getHostProperties());
                      if (mounted) Navigator.of(context).pop();
                      hostController.getHostProperties();
                      setState(() => isActive = value);
                    },
                    child: Text(value ? 'Activate' : 'Pause'),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────────────
  Widget _actions(Property p) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Get.to(() => UpdatePropertyPage(property: p)),
            icon: const Icon(Icons.edit_outlined, size: 18),
            style: OutlinedButton.styleFrom(
              foregroundColor: kIndigo,
              side: const BorderSide(color: kIndigo),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            label: const Text('Edit',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _confirmDelete,
            icon: const Icon(Icons.delete_outline, size: 18),
            style: ElevatedButton.styleFrom(
              backgroundColor: kDanger,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            label: Obx(() => hostController.loading.value
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Delete',
                    style: TextStyle(fontWeight: FontWeight.w700))),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete property'),
        content: const Text(
            'Are you sure you want to delete this property? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await hostController
                  .deleteProperty(widget.property.propertyId)
                  .then((_) => Navigator.of(context).pop());
              if (mounted) Navigator.of(context).pop();
              hostController.getHostProperties();
            },
            child: const Text('Delete', style: TextStyle(color: kDanger)),
          ),
        ],
      ),
    );
  }

  // ── Reusable bits ────────────────────────────────────────────────────────────
  Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: kCardShadow,
        ),
        child: child,
      );

  Widget _sectionTitle(String t) => Text(t,
      style: fraunces(fontSize: 16.5, fontWeight: FontWeight.w700, color: kInk));

  Widget _statTile(String label, String value, Color color) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: kSurface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: kCardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 12, color: kMuted)),
            const SizedBox(height: 6),
            Text(value,
                style: fraunces(
                    fontSize: 22, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      );

  Widget _factChip(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: kSand,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 15, color: kIndigo),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 12.5, fontWeight: FontWeight.w600, color: kInk)),
        ]),
      );

  Widget _pill(String label, Color color, {IconData? icon, bool solid = false}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: solid ? color : color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: solid ? Colors.white : color),
            const SizedBox(width: 5),
          ],
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: solid ? Colors.white : color)),
        ]),
      );
}
