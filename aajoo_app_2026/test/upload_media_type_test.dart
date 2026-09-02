// Labelling an upload.
//
// The bug these guard against: Dio labels every multipart part
// `application/octet-stream` unless told otherwise, and nothing in this app
// was telling it otherwise. The listing-photo route refuses anything that is
// not `image/*`, so a host picking an ordinary JPEG was told it was not an
// image and could not add a single photo to a listing from the app.
import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/utils/upload_media_type.dart';

void main() {
  group('mediaTypeForPath', () {
    test('names the common photo formats', () {
      expect(mediaTypeForPath('/cache/a.jpg').toString(), 'image/jpeg');
      expect(mediaTypeForPath('/cache/a.jpeg').toString(), 'image/jpeg');
      expect(mediaTypeForPath('/cache/a.png').toString(), 'image/png');
      expect(mediaTypeForPath('/cache/a.webp').toString(), 'image/webp');
      expect(mediaTypeForPath('/cache/a.heic').toString(), 'image/heic');
    });

    test('is case insensitive — a camera roll is full of .JPG', () {
      expect(mediaTypeForPath('/DCIM/IMG_0001.JPG').toString(), 'image/jpeg');
      expect(mediaTypeForPath('/DCIM/Shot.PNG').toString(), 'image/png');
    });

    test('names PDFs, which identity documents are allowed to be', () {
      expect(mediaTypeForPath('/docs/id.pdf').toString(), 'application/pdf');
    });

    test('handles the real shape of an image_picker path', () {
      // What actually arrives on Android: a cache file with a generated name.
      expect(
        mediaTypeForPath(
                '/data/user/0/com.aajoo.aajoohomes/cache/image_picker_1234.jpg')
            .toString(),
        'image/jpeg',
      );
    });

    test('answers null rather than guessing at an unknown extension', () {
      // Null lets Dio fall back to its own default. Claiming a type we cannot
      // support would be lying to the validator on the other end.
      expect(mediaTypeForPath('/cache/mystery.xyz'), isNull);
      expect(mediaTypeForPath('/cache/no_extension'), isNull);
      expect(mediaTypeForPath('/cache/trailing.'), isNull);
      expect(mediaTypeForPath(''), isNull);
    });

    test('reads the LAST dot, not the first', () {
      expect(mediaTypeForPath('/cache/my.holiday.photo.png').toString(),
          'image/png');
    });
  });
}
