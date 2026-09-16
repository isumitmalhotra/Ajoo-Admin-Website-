// The renter's property page no longer reaches into a host controller.
//
// Opening any listing as a guest used to `Get.put` NewPropertyController —
// 313 lines of the HOST's add-property form state: every field of the listing
// wizard, its image pickers, its submit calls — for three members. All the
// page ever wanted was the reviews, and the renter side already had its own
// PropertyReviewController with exactly those three members and identical
// bodies. The host controller's file was named `..._legacy.dart`, and the
// wizard replaced the form it belonged to long ago; it survived only because
// this one import kept it reachable, so nothing flagged it as dead.
//
// Deleted, with the renter page pointed at the renter's controller.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final page = File('lib/ui/screens_renter/property_details/property_page.dart')
      .readAsStringSync();

  test('the legacy host add-property controller is gone from the tree', () {
    expect(
      File('lib/ui/screens_host/add_property/new_property_controller_legacy.dart')
          .existsSync(),
      isFalse,
      reason: 'the wizard replaced the form this controller drove',
    );
  });

  test('the renter page reads reviews from the renter controller', () {
    expect(page, contains('Get.put<PropertyReviewController>(PropertyReviewController())'));
    expect(page, contains('Get.find<PropertyReviewController>()'));
    expect(
      page,
      contains(
          'package:rent_home/ui/screens_renter/history/history_description/property_review_controller.dart'),
    );
  });

  test('nothing on the renter page names the host controller any more', () {
    expect(page, isNot(contains('NewPropertyController')));
    expect(page, isNot(contains('new_property_controller_legacy')));
  });

  test('the widget the stay banner replaced is gone', () {
    // OngoingBookingWidget only showed a stay while the guest was PHYSICALLY
    // in the property; StayBanner shows the stay in progress or the next one
    // coming, and the rail renders that. The old widget stayed reachable
    // through an import homescreen never used.
    expect(File('lib/ui/screens_renter/home/ongoing_widget.dart').existsSync(), isFalse);
    final home = File('lib/ui/screens_renter/home/homescreen.dart').readAsStringSync();
    expect(home, isNot(contains('ongoing_widget.dart')));
    expect(home, contains('HomeBannerRail(userController: userController)'));
  });

  test('the shared state/city dropdown is not stranded in a deleted host folder', () {
    expect(File('lib/widgets/state_city_dropdowns.dart').existsSync(), isTrue);
    expect(Directory('lib/ui/screens_host/add_property').existsSync(), isFalse);
    for (final p in [
      'lib/ui/screens_common/update_profile/update_profile_screen.dart',
      'lib/ui/screens_renter/profile/profile_screen.dart',
    ]) {
      expect(File(p).readAsStringSync(),
          contains('package:rent_home/widgets/state_city_dropdowns.dart'),
          reason: '$p must import the moved widget');
    }
  });
}
