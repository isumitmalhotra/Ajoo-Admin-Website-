import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/service/listing_service.dart';
import 'package:rent_home/ui/screens_host/listing/listing_wizard_controller.dart';

/// An upload the server completed is not a failed upload.
///
/// On 2026-09-11 five photographs went up for a new listing and the step
/// went on reading "0 of 5 required photos added". Every one of them was on
/// the server. The next photograph was then uploaded as if it were the
/// listing's first — tagged "Cover Photo" beside the real cover — and a host
/// in the same spot would have uploaded the same five again.
///
/// When the upload call fails, or answers without a list, the controller now
/// asks the server what it holds before it tells the host anything.
void main() {
  final five = List.generate(5, (i) => File('p$i.jpg'));
  final noTags = List.filled(5, '');

  test('a failed call whose photographs arrived is a success', () async {
    final service = _StubService()
      ..throwOnUpload = true
      ..onServer = [for (var i = 0; i < 5; i++) _photo(70 + i, cover: i == 0)];
    final c = ListingWizardController(propertyId: 29303, service: service);
    c.propertyId.value = 29303;
    expect(c.photos, isEmpty);

    final err = await c.uploadPhotos(five, noTags);
    expect(err, isNull,
        reason: 'the server has all five; "Upload failed" sends the host '
            'back to upload them again');
    expect(c.photos, hasLength(5));
    expect(service.draftReads, 1);
  });

  test('a failed call whose photographs did NOT arrive is still a failure',
      () async {
    final service = _StubService()
      ..throwOnUpload = true
      ..onServer = [];
    final c = ListingWizardController(propertyId: 29303, service: service);
    c.propertyId.value = 29303;

    final err = await c.uploadPhotos(five, noTags);
    expect(err, 'Upload failed.');
    expect(c.photos, isEmpty);
    expect(service.draftReads, 1, reason: 'the server was not asked');
  });

  test('an answer without a list is not "no photos"', () async {
    final service = _StubService()
      ..uploadAnswer = {'message': 'ok'}
      ..onServer = [for (var i = 0; i < 5; i++) _photo(70 + i, cover: i == 0)];
    final c = ListingWizardController(propertyId: 29303, service: service);
    c.propertyId.value = 29303;

    final err = await c.uploadPhotos(five, noTags);
    expect(err, isNull);
    expect(c.photos, hasLength(5));
  });

  test('a normal answer needs no second opinion', () async {
    final service = _StubService()
      ..uploadAnswer = {
        'media': [for (var i = 0; i < 5; i++) _photo(70 + i, cover: i == 0)],
        'photoReadiness': {'count': 5, 'minimum': 5},
      };
    final c = ListingWizardController(propertyId: 29303, service: service);
    c.propertyId.value = 29303;

    final err = await c.uploadPhotos(five, noTags);
    expect(err, isNull);
    expect(c.photos, hasLength(5));
    expect(service.draftReads, 0);
  });
}

Map<String, dynamic> _photo(int id, {bool cover = false}) => {
      'id': id,
      'type': 'photo',
      'category': cover ? 'cover_photo' : null,
      'url': 'https://x/$id.jpg',
      'isCover': cover,
      'sortOrder': id - 70,
    };

class _StubService extends ListingService {
  bool throwOnUpload = false;
  Map<String, dynamic>? uploadAnswer;
  List<Map<String, dynamic>> onServer = const [];
  int draftReads = 0;

  @override
  Future<Map<String, dynamic>> uploadMedia({
    required int propertyId,
    required List<File> files,
    required List<String> categories,
    List<String> alts = const [],
  }) async {
    if (throwOnUpload) throw ListingException('Upload failed.');
    return uploadAnswer ?? {};
  }

  @override
  Future<Map<String, dynamic>> getDraft(int propertyId) async {
    draftReads += 1;
    return {'media': onServer};
  }
}
