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
import 'package:rent_home/utils/booking_chat.dart';
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
const _messages = 'lib/ui/screens_renter/messages/messages_screen.dart';

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

    test('all the call sites use the helper', () {
      // The last two were not in the report: the negotiation composer, and
      // the guest booking screen's floating "Get Directions" bar, which was
      // pinned at a hardcoded `bottom: 10` and sat under the gesture pill.
      // Both were seen on the emulator while checking the other fixes.
      for (final f in [_picker, _wizard, _settings, _negotiation, _guestBooking]) {
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

  group('#26 — a booking chat is the regular chat', () {
    // The reported bug: "Chat with Guest incorrectly redirects to the
    // Negotiation chat after booking completion... should open the regular
    // chat with the guest".
    //
    // There IS a regular chat, and it is not the negotiation screen.
    // `tbl_messages` carries person-to-person conversations with no property
    // attached; MessagesScreen is its inbox; and the WEBSITE has routed
    // "Contact Host" into it for months, prefilling a line that names the
    // stay (redesign/lib/contactHost.ts). The app's booking screens went to
    // the property-scoped negotiation page instead. Matching the website is
    // the fix — not hiding the offer box on the wrong screen.
    final host = codeOf(_hostBooking);
    final guest = codeOf(_guestBooking);

    test('neither booking screen opens the negotiation page', () {
      for (final entry in {'host': host, 'guest': guest}.entries) {
        expect(entry.value, isNot(contains('PriceNegotiationPage')),
            reason: 'the ${entry.key} booking screen still negotiates');
        expect(entry.value, isNot(contains('negotitaion_page.dart')),
            reason: 'the ${entry.key} booking screen still imports it');
      }
    });

    test('both open MessagesScreen with the other person', () {
      for (final code in [host, guest]) {
        expect(code, contains('MessagesScreen('));
        expect(code, contains('openWith:'));
        expect(code, contains('draft:'));
      }
    });

    test('the screen accepts a prefilled, unsent draft', () {
      final screen = codeOf(_messages);
      expect(screen, contains('final String? draft'));
      expect(screen, contains('_input.text = draft'));
      // Passed down to the conversation, or the inbox would swallow it.
      expect(screen, contains('draft: widget.draft'));
    });

    test('a request made before the socket is up is not dropped', () {
      // Found by opening the fixed screen on a device: the thread rendered
      // "No messages yet" on a conversation that had messages, because
      // initState asks for the history while the socket is still shaking
      // hands and both emitters returned silently when it was not connected.
      // The send path was worse — the composer drew its optimistic bubble and
      // the message was thrown away.
      final svc = codeOf('lib/service/messages_service.dart');
      expect(svc, contains('_pendingLoad'));
      expect(svc, contains('_pendingSends'));
      expect(svc, contains('void _flush()'));
      expect(svc, contains('_flush();'));
      // Bounded, and dropped on sign-out — a queued message belongs to the
      // account that typed it.
      expect(svc, contains('_maxPendingSends'));
      expect(svc, contains('_pendingSends.clear();'));
    });

    test('the negotiation entry points are untouched', () {
      // Offering on a property, the host inbox and a negotiation push
      // notification are all still negotiations.
      for (final f in [
        'lib/ui/screens_host/support/host_messages_screen.dart',
        'lib/ui/screens_common/price_negotiation/negotiation_wrapper.dart',
        'lib/ui/screens_common/notifications/notification_screen.dart',
      ]) {
        expect(codeOf(f), contains('PriceNegotiationPage'),
            reason: '$f should still be a negotiation');
      }
    });

    test('the negotiation composer clears the navigation bar', () {
      // Not part of the report, but the same defect as #20/#22/#23 on a
      // screen this pass touched.
      expect(codeOf(_negotiation), contains('safeBottomInsets(context'));
    });
  });

  group('#26 — the opening line', () {
    // Word for word the website's, so a guest who writes from the site and
    // then from the app does not read as two different people.
    test('names the stay, the dates and the reference', () {
      expect(
        guestOpeningMessage(
          propertyName: 'Aajoo Homes',
          bookingCode: 'B703473',
          from: '06-09-2026',
          to: '07-09-2026',
        ),
        "Hi! I'd like to ask about my stay at Aajoo Homes "
        '(06 Sep – 07 Sep 2026). Booking ref: B703473.',
      );
    });

    test('drops the parts it does not know', () {
      expect(guestOpeningMessage(propertyName: 'Aajoo Homes'),
          "Hi! I'd like to ask about my stay at Aajoo Homes.");
      expect(guestOpeningMessage(bookingCode: 'B1'),
          "Hi! I'd like to ask about my booking. Booking ref: B1.");
    });

    test('is empty when there is nothing to say', () {
      // An empty draft leaves the box alone rather than prefilling "Hi!".
      expect(guestOpeningMessage(), '');
      expect(hostOpeningMessage(guestName: 'Aajoo Renter'), '');
    });

    test('the host greets the guest by first name', () {
      expect(
        hostOpeningMessage(
          guestName: 'Aajoo Renter',
          propertyName: 'Aajoo Homes',
          bookingCode: 'B703473',
          from: '06-09-2026',
          to: '07-09-2026',
        ),
        "Hello Aajoo! I'm getting in touch about your stay at Aajoo Homes "
        '(06 Sep – 07 Sep 2026). Booking ref: B703473.',
      );
    });

    test('a date it cannot parse is passed through, not dropped', () {
      // Booking dates are DD-MM-YYYY from the API. Anything else is shown as
      // it came rather than silently vanishing from the sentence.
      expect(stayRangeLabel('2026-09-06', '2026-09-07'),
          '2026-09-06 – 2026-09-07');
      expect(stayRangeLabel('06-13-2026', '07-09-2026'),
          '06-13-2026 – 07 Sep 2026');
      expect(stayRangeLabel(null, null), '');
    });
  });
}

