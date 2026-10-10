// Property 6 was uploaded with four AVIF images, its cover among them.
// Browsers decode AVIF, so the website looked fine; Flutter does not, so on
// iOS and Android Image.network threw and the card painted the "not
// supported" placeholder. f_auto has Cloudinary send a format the app's HTTP
// client can decode.
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/models/properties_response_model.dart';
import 'package:rent_home/utils/cloudinary_url.dart';

const _base = 'https://res.cloudinary.com/due5czusf/image/upload';

void main() {
  test('an upload URL gets f_auto as its own first transformation', () {
    expect(
      deliverableImageUrl('$_base/v1791500196/property_folder/villa-10-9f09.avif'),
      '$_base/f_auto/v1791500196/property_folder/villa-10-9f09.avif',
    );
  });

  test('an existing transformation is kept, f_auto chained before it', () {
    expect(
      deliverableImageUrl('$_base/c_fill,w_400/v1/property_folder/a.jpg'),
      '$_base/f_auto/c_fill,w_400/v1/property_folder/a.jpg',
    );
  });

  test('a URL that already names a format is left alone', () {
    for (final url in [
      '$_base/f_auto/v1/a.avif',
      '$_base/f_jpg,q_auto/v1/a.avif',
      '$_base/q_auto,f_webp/v1/a.avif',
    ]) {
      expect(deliverableImageUrl(url), url);
    }
  });

  test('null, empty, non-Cloudinary and non-image URLs are left alone', () {
    expect(deliverableImageUrl(null), isNull);
    expect(deliverableImageUrl(''), '');
    expect(deliverableImageUrl('https://example.com/image/upload/a.avif'),
        'https://example.com/image/upload/a.avif');
    expect(deliverableImageUrl('https://res.cloudinary.com/x/video/upload/v1/a.mp4'),
        'https://res.cloudinary.com/x/video/upload/v1/a.mp4');
  });

  test('applying it twice changes nothing more', () {
    final once = deliverableImageUrl('$_base/v1/a.avif');
    expect(deliverableImageUrl(once), once);
  });

  test('a listing card gets decodable URLs for its cover and gallery', () {
    final p = Property.fromJson({
      'property_id': 6,
      'coverImage': '$_base/v1/property_folder/villa-10-9f09.avif',
      'images': ['$_base/v1/property_folder/villa-2-4egl.jpg'],
    });
    expect(p.coverImage, '$_base/f_auto/v1/property_folder/villa-10-9f09.avif');
    expect(p.images.single, '$_base/f_auto/v1/property_folder/villa-2-4egl.jpg');
  });
}
