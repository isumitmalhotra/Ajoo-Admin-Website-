import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/utils/category_label.dart';

/// `{cat_id: 2, cat_title: Resort, cat_slug: resort}` over a listing's photo.
///
/// Photographed by the tester on 2026-09-23. The backend sends two shapes on
/// purpose — `category_titles` are names, `categories` are records — and five
/// call sites turned whichever they had into a label with `.toString()`.
///
/// The nastiest part is the third case below. The model layer flattened the
/// record on the way in, so by the time the hero pill asked "is this a Map?"
/// the answer was no: it was a String that happened to look like a record.
/// That is why the pill's own Map-handling did not save it, and why the label
/// corrected itself a second later when the detail payload arrived with the
/// real records.
void main() {
  group('whatever the API sent, a guest sees a name', () {
    test('a record', () {
      expect(categoryLabel({'cat_id': 2, 'cat_title': 'Resort', 'cat_slug': 'resort'}),
          'Resort');
    });

    test('a name', () {
      expect(categoryLabel('Resort'), 'Resort');
    });

    test('a record somebody else already flattened', () {
      // Exactly the string in the screenshot.
      expect(categoryLabel('{cat_id: 2, cat_title: Resort, cat_slug: resort}'),
          'Resort');
    });

    test('a flattened record whose title has spaces', () {
      expect(categoryLabel('{cat_id: 5, cat_title: Pool House, cat_slug: pool-house}'),
          'Pool House');
    });

    test('alternative key names', () {
      expect(categoryLabel({'title': 'Villas'}), 'Villas');
      expect(categoryLabel({'name': 'Cottages'}), 'Cottages');
    });
  });

  group('nothing usable is nothing shown', () {
    test('null, empty and blank', () {
      expect(categoryLabel(null), isNull);
      expect(categoryLabel(''), isNull);
      expect(categoryLabel('   '), isNull);
    });

    test('a record with no title is dropped, not printed', () {
      expect(categoryLabel({'cat_id': 9}), isNull);
      expect(categoryLabel('{cat_id: 9, cat_slug: mystery}'), isNull,
          reason: 'better no pill than a record over the photo');
    });
  });

  group('lists', () {
    test('mixed shapes all come back as names, in order', () {
      expect(
        categoryLabels([
          {'cat_id': 2, 'cat_title': 'Resort'},
          'Homestay',
          '{cat_id: 7, cat_title: Farm Stay, cat_slug: farm-stay}',
        ]),
        ['Resort', 'Homestay', 'Farm Stay'],
      );
    });

    test('unusable entries are dropped rather than blanking the row', () {
      expect(categoryLabels([{'cat_id': 1}, 'Villas', null, '']), ['Villas']);
    });

    test('null and a single value', () {
      expect(categoryLabels(null), isEmpty);
      expect(categoryLabels('Cottages'), ['Cottages']);
    });
  });
}
