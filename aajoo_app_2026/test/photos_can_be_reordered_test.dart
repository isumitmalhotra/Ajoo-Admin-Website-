// The server has taken `sortOrder` on PATCH /listing/media since the engine
// shipped and nothing on either client ever sent it — the gallery order was
// the upload order for good (300-case run, HL-055, 2026-09-21). Now a photo
// moves one place earlier or later, and EVERY photo's position is sent.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rent_home/service/listing_service.dart';
import 'package:rent_home/ui/screens_host/listing/listing_wizard_controller.dart';

class _StubService extends ListingService {
  List<Map<String, dynamic>>? sent;
  @override
  Future<Map<String, dynamic>> updateMedia({required int propertyId, required List<Map<String, dynamic>> media}) async {
    sent = media;
    // The server answers with the list in the new order.
    final byId = {for (final m in _current) m['id']: m};
    return {'media': [for (final it in media..sort((a, b) => (a['sortOrder'] as int).compareTo(b['sortOrder'] as int))) byId[it['id']]]};
  }
  List<Map<String, dynamic>> _current = [];
}

void main() {
  group('photos can be reordered', () {
    test('moving the third photo earlier sends every position, and the list follows', () async {
      final svc = _StubService();
      final c = ListingWizardController(propertyId: 77, service: svc);
      c.propertyId.value = 77;
      final three = [
        {'id': 1, 'url': 'a', 'type': 'image'},
        {'id': 2, 'url': 'b', 'type': 'image'},
        {'id': 3, 'url': 'c', 'type': 'image'},
        {'id': 9, 'url': 'deed', 'type': 'document'},
      ];
      c.media.assignAll(three);
      svc._current = three;
      expect(await c.movePhoto(3, -1), isNull);
      expect(svc.sent, [
        {'id': 1, 'sortOrder': 1},
        {'id': 3, 'sortOrder': 2},
        {'id': 2, 'sortOrder': 3},
      ]);
      expect(c.photos.map((m) => m['id']).toList(), [1, 3, 2]);
    });

    test('the ends do not move, and a document is never part of the order', () async {
      final svc = _StubService();
      final c = ListingWizardController(propertyId: 77, service: svc);
      c.propertyId.value = 77;
      final two = [
        {'id': 1, 'url': 'a', 'type': 'image'},
        {'id': 2, 'url': 'b', 'type': 'image'},
      ];
      c.media.assignAll(two);
      svc._current = two;
      expect(await c.movePhoto(1, -1), isNull);
      expect(svc.sent, isNull, reason: 'the first photo cannot move earlier');
      expect(await c.movePhoto(2, 1), isNull);
      expect(svc.sent, isNull, reason: 'the last photo cannot move later');
    });

    test('the tile offers the two controls, disabled at the ends', () {
      final src = File('lib/ui/screens_host/listing/listing_wizard_screen.dart').readAsStringSync();
      expect(src, contains('onMoveEarlier: i == 0'));
      expect(src, contains('onMoveLater: i == photos.length - 1'));
      expect(src, contains('_moveButton(Icons.chevron_left_rounded, onMoveEarlier)'));
    });
  });
}
