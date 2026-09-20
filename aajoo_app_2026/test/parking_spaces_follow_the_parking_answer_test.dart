// "Number of parking spaces" is asked only once the host has said there IS
// parking: shown for Covered/Open/Street, hidden for None (HL-036/037,
// 2026-09-21). The schema says it with `showIf: { key, in: [...] }`, which
// this model reads beside the older `equals`.
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/models/listing_schema.dart';

void main() {
  group('parking spaces follow the parking answer', () {
    final field = SchemaField.fromJson({
      'key': 'parking_spaces',
      'label': 'Number of parking spaces',
      'type': 'number',
      'showIf': {'key': 'parking', 'in': ['covered', 'open', 'street']},
    });

    test('shown for covered, open and street', () {
      for (final v in ['covered', 'open', 'street']) {
        expect(isFieldVisible(field, {'parking': v}), isTrue, reason: v);
      }
    });

    test('hidden for none, and until the host answers', () {
      expect(isFieldVisible(field, {'parking': 'none'}), isFalse);
      expect(isFieldVisible(field, {}), isFalse);
    });

    test('the older equals form still works', () {
      final pool = SchemaField.fromJson({
        'key': 'pool_type', 'label': 'Pool Type', 'type': 'multiselect',
        'showIf': {'key': 'swimming_pool', 'equals': true},
      });
      expect(isFieldVisible(pool, {'swimming_pool': '1'}), isTrue);
      expect(isFieldVisible(pool, {'swimming_pool': false}), isFalse);
    });
  });
}
