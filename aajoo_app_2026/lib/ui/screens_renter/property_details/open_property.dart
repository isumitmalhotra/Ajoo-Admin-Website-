import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:rent_home/controller/user_controller.dart';
import 'package:rent_home/models/properties_response_model.dart';
import 'package:rent_home/ui/screens_renter/property_details/property_page.dart';

/// Open a stay knowing only its id.
///
/// Several surfaces hold nothing but a property id — a negotiated deal, a blog
/// post written about one stay, a notification — and each needs the same three
/// steps: fetch the detail, shape it into a [Property], push [PropertyPage].
/// The deal banner grew its own copy of this; a second copy for the blog would
/// be the start of drift, so the sequence lives here once.
///
/// [dealCode]/[dealFrom]/[dealTo]/[dealPercent] ride along when the caller is
/// a negotiated deal, so the page opens with the agreed nights and coupon
/// pre-filled exactly as before.
Future<void> openPropertyById(
  int propertyId, {
  String? dealCode,
  String? dealFrom,
  String? dealTo,
  int? dealPercent,
  String errorTitle = 'Property',
}) async {
  if (propertyId <= 0) return;
  Get.dialog(const Center(child: CircularProgressIndicator()),
      barrierDismissible: false);
  try {
    final userController = Get.find<UserController>();
    await userController.getProperty(propertyId);
    final resp = userController.property.value;
    if (Get.isDialogOpen ?? false) Get.back();
    final pd = resp?.data;
    if (pd == null) {
      Get.snackbar(errorTitle, 'Could not open this property. Please try again.',
          snackPosition: SnackPosition.TOP);
      return;
    }
    final property = Property(
      propertyId: pd.propertyId ?? propertyId,
      propertyName: pd.propertyName ?? 'Property',
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
    Get.to(() => PropertyPage(
          property: property,
          price: property.propertyPrice,
          name: property.propertyName,
          location: property.propertyAddress,
          image: property.coverImage ?? '',
          id: property.propertyId,
          // '' lets the detail page say "New" instead of inventing a score.
          rating: '',
          description: property.propertyDesc,
          lat: property.propertyLatitude,
          long: property.propertyLongitude,
          galleryImages: property.images.map((e) => e.toString()).toList(),
          inTime: property.propDetailsPropDetailInTime,
          outTime: property.propDetailsPropDetailOutTime,
          dealCode: dealCode,
          dealFrom: dealFrom,
          dealTo: dealTo,
          dealPercent: dealPercent,
        ));
  } catch (_) {
    if (Get.isDialogOpen ?? false) Get.back();
    Get.snackbar(errorTitle, 'Could not open this property. Please try again.',
        snackPosition: SnackPosition.TOP);
  }
}
