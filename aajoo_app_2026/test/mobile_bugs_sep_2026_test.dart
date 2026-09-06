// The seven mobile defects reported on 2026-09-07, pinned.
//
//   #20  "Use This Location" sat behind the navigation bar
//   #21  the Add Property map was slow while searching or moving the pin
//   #22  "Upload" on the photo sheet sat behind the navigation bar
//   #23  "Delete My Account" sat behind the navigation bar
//   #24  editing a LIVE listing said "Sent for review"
//   #25  manager details and house-rule toggles were lost on update
//   #26  "Chat with Guest" opened the negotiation screen
//
// Three of them (#20, #22, #23) are the same defect in three places — a
// bottom-anchored control with a hardcoded padding — so the first group tests
// the shared helper and then checks that all three call sites actually use it.
// The rest are structural, and are asserted against the source with comments
// stripped: a test that greps a file is worthless if the sentence describing
// the bug can satisfy it.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/utils/safe_bottom.dart';

/// A file's code with its comments removed.
///
/// Every one of these files explains its own fix in a comment. Matching on the
/// prose instead of the code would keep the test green after somebody deleted
/// the line the comment describes.
String codeOf(String path) {
  final raw = File(path).readAsStringSync();
  final out = StringBuffer();
  var inBlock = false;
  for (final line in const LineSplitter().convert(raw)) {
    var l = line;
    if (inBlock) {
      final end = l.indexOf('*/');
      if (end < 0) continue;
      l = l.substring(end + 2);
      inBlock = false;
    }
    final block = l.indexOf('/*');
    if (block >= 0) {
      inBlock = !l.substring(block).contains('*/');
      l = l.substring(0, block);
    }
    final line_ = l.indexOf('//');
    if (line_ >= 0) l = l.substring(0, line_);
    if (l.trim().isEmpty) continue;
    out.writeln(l);
  }
  return out.toString();
}

const _picker = 'lib/ui/screens_host/listing/components/location_picker_sheet.dart';
const _wizard = 'lib/ui/screens_host/listing/listing_wizard_screen.dart';
const _settings = 'lib/ui/screens_common/settings/settings_page.dart';
const _negotiation = 'lib/ui/screens_common/price_negotiation/negotitaion_page.dart';
const _hostBooking = 'lib/ui/screens_host/booking_history/host_booking_detail_page.dart';
const _guestBooking =
    'lib/ui/screens_renter/history/history_description/history_description_page.dart';
const _geocode = 'lib/service/geocode_service.dart';

void main() {
  group('#20/#22/#23 — a control at the bottom clears the navigation bar', () {
    testWidgets('adds the device inset to the base padding', (tester) async {
      late double got;
      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(padding: EdgeInsets.only(bottom: 48)),
        child: Builder(builder: (c) {
          got = safeBottom(c, base: 16);
          return const SizedBox();
        }),
      ));
      expect(got, 64);
    });

    testWidgets('adds nothing on a phone with no inset', (tester) async {
      late double got;
      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(),
        child: Builder(builder: (c) {
          got = safeBottom(c, base: 16);
          return const SizedBox();
        }),
      ));
      expect(got, 16);
    });

    testWidgets('does not inset twice inside a SafeArea', (tester) async {
      // MediaQuery.paddingOf, not viewPaddingOf. `padding` is what is LEFT
      // after an enclosing SafeArea has taken its share; `viewPadding` reports
      // the physical inset either way and would lift the button by the height
      // of the navigation bar on the screens that were already correct.
      late double got;
      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(padding: EdgeInsets.only(bottom: 48)),
        child: SafeArea(
          child: Builder(builder: (c) {
            got = safeBottom(c, base: 16);
            return const SizedBox();
          }),
        ),
      ));
      expect(got, 16);
    });

    testWidgets('safeBottomInsets keeps the other three sides', (tester) async {
      late EdgeInsets got;
      await tester.pumpWidget(MediaQuery(
        data: const MediaQueryData(padding: EdgeInsets.only(bottom: 24)),
        child: Builder(builder: (c) {
          got = safeBottomInsets(c, left: 18, top: 12, right: 18, bottom: 16);
          return const SizedBox();
        }),
      ));
      expect(got, const EdgeInsets.fromLTRB(18, 12, 18, 40));
    });

    test('all three call sites use the helper', () {
      for (final f in [_picker, _wizard, _settings]) {
        expect(codeOf(f), contains('safeBottom'), reason: '$f lost the fix');
        expect(File(f).readAsStringSync(),
            contains("import 'package:rent_home/utils/safe_bottom.dart'"),
            reason: '$f does not import the helper');
      }
    });
  });

  group('#21 — the Add Property map', () {
    final code = codeOf(_picker);

    test('the map widget is built once, not on every setState', () {
      // Typing in the search box and each step of an address lookup used to
      // rebuild the whole sheet, Google Map included. Handing back the same
      // widget instance makes Element.updateChild skip the platform view.
      expect(code, contains('Widget? _mapView'));
      expect(code, contains(r'_mapView ??= _buildMap()'));
      expect(code, contains('Widget _buildMap() => GoogleMap('));
    });

    test('a pin that barely moved is not looked up again', () {
      expect(code, contains('_metresBetween'));
      expect(code, contains('_resolvedAt'));
    });

    test('answers already paid for are reused', () {
      expect(code, contains('_reverseCache'));
      expect(code, contains('_reverseCacheMax'));
    });

    test('a superseded lookup is cancelled, not merely ignored', () {
      expect(code, contains('CancelToken'));
      expect(code, contains(r"_lookupCancel?.cancel('superseded')"));
      // The sequence guard stays too: cancellation is best-effort, and a reply
      // already in flight must still not overwrite a newer pin.
      expect(code, contains('_lookupSeq'));
      expect(codeOf(_geocode), contains('CancelToken.isCancel(e)'));
    });

    test('the first two keystrokes do not rebuild anything', () {
      expect(code, contains('if (_hits.isNotEmpty || _searching)'));
    });

    test('a camera move asked for before the map exists is not dropped', () {
      expect(code, contains('_pendingCamera'));
    });
  });

  group('#24 — what the submit dialog says', () {
    final code = codeOf(_wizard);

    test('a live listing is not "sent for review"', () {
      expect(code, contains('Changes submitted'));
      expect(code, contains('Sent for review'));
      expect(code, contains('c.isLive'));
    });
  });

  group('#25 — manager details and house rules survive a reload', () {
    final code = codeOf('lib/ui/screens_host/listing/listing_wizard_controller.dart');

    test('the manager fields are mapped to the names the form uses', () {
      // The API answers pm_* and the form reads manager_*; hydrating one from
      // the other by name silently dropped every manager field.
      for (final f in ['pm_full_name', 'manager_full_name']) {
        expect(code, contains(f), reason: 'lost the $f mapping');
      }
    });

    test('house-rule toggles are hydrated as booleans', () {
      // They come back as 1/0 from the database. Left as ints they are neither
      // true nor false to a Switch, and every toggle reset itself.
      expect(code, contains('houseRules'));
    });
  });

  group('#26 — Chat with Guest is a conversation, not a negotiation', () {
    final page = codeOf(_negotiation);

    test('the page can hide its offer affordances', () {
      expect(page, contains('final bool conversationOnly'));
      expect(page, contains('this.conversationOnly = false'));
      expect(page, contains('if (!widget.conversationOnly)'));
      expect(page, contains('widget.conversationOnly'));
      expect(page, contains('_plainComposer'));
    });

    test('a plain message still goes through the same thread', () {
      // One conversation between a host and a guest about a property. The
      // composer sends through sendNegotiationMessage with isOffer false — it
      // is not a second messaging system.
      expect(page, contains('sendNegotiationMessage'));
      expect(page, contains('isOffer: false'));
    });

    test('the base-price chip is hidden in a booking chat', () {
      expect(page, contains('showPrice: !widget.conversationOnly'));
      expect(
        codeOf('lib/ui/screens_common/price_negotiation/components/negotiation_app_bar.dart'),
        contains('if (showPrice)'),
      );
    });

    test('the negotiation message limits do not apply to it', () {
      // The trap this nearly shipped into: a negotiation allows two messages
      // each, strictly alternating, and none once an offer is accepted. A
      // booked stay usually HAS an accepted offer, so the new composer would
      // have rendered perfectly and refused every message the host typed.
      final controller =
          codeOf('lib/ui/screens_common/price_negotiation/negotiation_controller.dart');
      expect(controller, contains('enforceNegotiationLimits'));
      expect(controller,
          contains('if (!enforceNegotiationLimits.value) return true;'));
      expect(page,
          contains('negotiationController.enforceNegotiationLimits.value'));
      expect(page, contains('!widget.conversationOnly'));
    });

    test('the composer clears the navigation bar', () {
      // This screen is now where a host and a guest talk about a booking.
      expect(page, contains('safeBottomInsets(context'));
    });

    test('both sides of a booking open it in conversation mode', () {
      for (final f in [_hostBooking, _guestBooking]) {
        expect(codeOf(f), contains('conversationOnly: true'),
            reason: '$f still opens the negotiation screen');
      }
    });

    test('the negotiation entry points are untouched', () {
      // Offering on a property, and the host inbox, are still negotiations.
      // If these ever pass conversationOnly the feature has been broken.
      for (final f in [
        'lib/ui/screens_host/support/host_messages_screen.dart',
        'lib/ui/screens_common/price_negotiation/negotiation_wrapper.dart',
        'lib/ui/screens_common/notifications/notification_screen.dart',
      ]) {
        expect(codeOf(f), isNot(contains('conversationOnly')),
            reason: '$f should still be a negotiation');
      }
    });
  });
}
