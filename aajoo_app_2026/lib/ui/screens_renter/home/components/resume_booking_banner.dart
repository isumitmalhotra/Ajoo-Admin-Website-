import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/ui/design/aajoo_skin.dart';
import 'package:rent_home/utils/lux_mode.dart';
import 'package:rent_home/controller/user_controller.dart';
import 'package:rent_home/models/properties_response_model.dart';
import 'package:rent_home/service/pending_booking.dart';
import 'package:rent_home/ui/screens_renter/home/map/map_controller.dart';
import 'package:rent_home/ui/screens_renter/property_details/property_page.dart';
import 'package:rent_home/utils/fonts.dart';

/// "Pick up where you left off."
///
/// A guest who taps Book Now without a verified ID is sent to DIDIT, which
/// runs in the system browser. Android may destroy the app while they are over
/// there, so they finish their verification and return to a home screen with
/// no memory of the booking — the dates, the coupon and the property all gone.
/// That is the "I did the KYC and didn't get back to my booking" report.
///
/// The property page writes the intent to disk before it hands control away;
/// this reads it back and reopens that property with the same dates. It hides
/// itself when there is nothing pending, and the intent expires after two days
/// because stale dates help nobody.
class ResumeBookingBanner extends StatefulWidget {
  const ResumeBookingBanner({super.key});

  @override
  State<ResumeBookingBanner> createState() => _ResumeBookingBannerState();
}

class _ResumeBookingBannerState extends State<ResumeBookingBanner> {
  PendingBooking? _intent;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final intent = await PendingBookingStore.read();
    if (!mounted) return;
    setState(() => _intent = intent);
  }

  Future<void> _dismiss() async {
    await PendingBookingStore.clear();
    if (!mounted) return;
    setState(() => _intent = null);
  }

  Future<void> _resume() async {
    final intent = _intent;
    if (intent == null || _opening) return;
    setState(() => _opening = true);
    try {
      final userController = Get.find<UserController>();
      await userController.getProperty(intent.propertyId);
      final pd = userController.property.value?.data;
      if (pd == null) {
        Get.snackbar('Booking', "Couldn't reopen that stay. Please try again.",
            snackPosition: SnackPosition.TOP);
        return;
      }
      final property = Property(
        propertyId: pd.propertyId ?? intent.propertyId,
        propertyName: pd.propertyName ?? intent.propertyName,
        propertyAddress: pd.propertyAddress ?? '',
        propertyDesc: pd.propertyDesc ?? '',
        propertyPrice: pd.propertyPrice ?? '0',
        propertyCity: pd.propertyCity ?? '',
        propertyLongitude: pd.propertyLongitude ?? '0.0',
        propertyLatitude: pd.propertyLatitude ?? '0.0',
        propertyHostId: pd.propertyHostId ?? 0,
        propertyZip: pd.propertyZip,
        propertyContact: pd.propertyContact,
        propDetailsPropDetailIsPetFriendly: pd.propDetails?.isPetFriendly,
        propDetailsPropDetailIsSmoke: pd.propDetails?.isSmoke,
        propDetailsPropDetailInTime: pd.propDetails?.inTime,
        propDetailsPropDetailOutTime: pd.propDetails?.outTime,
        propDetailsPropDetailExtra: pd.propDetails?.extra,
        coverImage: (pd.images != null && pd.images!.isNotEmpty)
            ? pd.images!.first.toString()
            : null,
        images: (pd.images ?? const []).map((e) => e.toString()).toList(),
        categoryTitles: const [],
        tags: pd.tags?.map((e) => e.toString()).toList(),
        categories: pd.categories?.map((e) => e.toString()).toList(),
        amenities: pd.amenities?.map((e) => e.toString()).toList(),
      );
      // The party size travels through MapController — the property page
      // falls back to it when no deal dictates one — so a resumed booking
      // reopens for the same number of people it was being made for.
      if (intent.guests > 0 && Get.isRegistered<MapController>()) {
        Get.find<MapController>().setStay(guests: intent.guests);
      }
      // dealFrom/dealTo is the page's existing "open with these dates already
      // chosen" input, so the guest lands on their own stay, not a blank sheet.
      Get.to(() => PropertyPage(
            property: property,
            price: property.propertyPrice,
            name: property.propertyName,
            location: property.propertyAddress,
            image: property.coverImage ?? '',
            id: property.propertyId,
            rating: '0',
            description: property.propertyDesc,
            lat: property.propertyLatitude,
            long: property.propertyLongitude,
            galleryImages: property.images.map((e) => e.toString()).toList(),
            inTime: property.propDetailsPropDetailInTime,
            outTime: property.propDetailsPropDetailOutTime,
            dealFrom: intent.bookFrom,
            dealTo: intent.bookTo,
            dealCode: intent.couponCode,
          ));
    } catch (_) {
      Get.snackbar('Booking', "Couldn't reopen that stay. Please try again.",
          snackPosition: SnackPosition.TOP);
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final skin = AajooSkin.of(LuxMode.instance.isOn);
    final intent = _intent;
    if (intent == null) return const SizedBox.shrink();

    final dates = [intent.bookFrom, intent.bookTo]
        .where((d) => d != null && d.isNotEmpty)
        .join('  →  ');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kIndigo50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kIndigo600.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.bookmark_added_outlined,
              color: kIndigo600, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Finish your booking',
                    style: inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: skin.ink)),
                const SizedBox(height: 2),
                Text(
                  intent.propertyName.isEmpty
                      ? 'Pick up where you left off'
                      : [intent.propertyName, if (dates.isNotEmpty) dates]
                          .join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: inter(fontSize: 12, color: skin.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _opening
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: kIndigo600))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: _resume,
                      style: TextButton.styleFrom(
                          foregroundColor: kIndigo600,
                          padding: const EdgeInsets.symmetric(horizontal: 8)),
                      child: Text('Resume',
                          style: inter(
                              fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                    IconButton(
                      onPressed: _dismiss,
                      tooltip: 'Dismiss',
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.close, size: 16, color: skin.muted),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}
