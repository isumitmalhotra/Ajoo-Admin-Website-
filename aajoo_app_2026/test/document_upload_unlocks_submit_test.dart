import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:rent_home/service/listing_service.dart';
import 'package:rent_home/ui/screens_host/listing/listing_wizard_controller.dart';

/// Uploading the ownership document must be enough to unlock Submit.
///
/// Found on the device on 2026-09-11, on the first listing filed after the
/// document gate shipped: the PDF uploaded, the card still read "Before
/// publishing, upload a document proving you can list this property", and
/// Submit stayed grey. The server's gate reads the verification row, which
/// only step 5's save writes — and that save ran inside Submit, which the
/// gate had disabled for want of the document. A deadlock the wizard could
/// not get out of.
///
/// The upload now puts the document on file and asks the server again.
void main() {
  test('an uploaded document is saved to step 5 and readiness re-asked',
      () async {
    final service = _StubService();
    final c = ListingWizardController(propertyId: 77, service: service);
    c.propertyId.value = 77;
    c.readiness.assignAll({
      'canSubmit': false,
      'blockedReason':
          'Before publishing, upload a document proving you can list this property.',
    });
    expect(c.serverAllowsSubmit, isFalse);

    final err = await c.uploadDocument(File('deed.pdf'), 'ownership_doc');
    expect(err, isNull);

    expect(service.step5Payloads, hasLength(1),
        reason: 'the document was never put on file, so the server '
            'cannot see it until Submit — which it has disabled');
    expect(service.step5Payloads.single['ownership_doc'],
        'https://x/deed.pdf');
    expect(service.step5Payloads.single['property_id'], 77);
    expect(service.readinessCalls, 1,
        reason: 'the server was never asked again, so the button stays grey');
    expect(c.serverAllowsSubmit, isTrue,
        reason: 'the host uploaded what was asked for and still cannot submit');
    expect(c.blockedReason, isNull);
  });

  test('a failed upload saves nothing and says so', () async {
    final service = _StubService()..uploadFails = true;
    final c = ListingWizardController(propertyId: 77, service: service);
    c.propertyId.value = 77;
    final err = await c.uploadDocument(File('deed.pdf'), 'ownership_doc');
    expect(err, isNotNull);
    expect(service.step5Payloads, isEmpty);
    expect(service.readinessCalls, 0);
  });
}

class _StubService extends ListingService {
  final step5Payloads = <Map<String, dynamic>>[];
  int readinessCalls = 0;
  bool uploadFails = false;

  @override
  Future<String?> uploadDocument({
    required int propertyId,
    required File file,
  }) async =>
      uploadFails ? null : 'https://x/deed.pdf';

  @override
  Future<void> saveStep5(Map<String, dynamic> payload) async {
    step5Payloads.add(Map<String, dynamic>.from(payload));
  }

  @override
  Future<Map<String, dynamic>> getReadiness(int propertyId) async {
    readinessCalls += 1;
    // Once the document is on file, the server lets the listing through.
    final onFile = step5Payloads.any((p) => p['ownership_doc'] != null);
    return {'canSubmit': onFile, 'blockedReason': onFile ? null : 'blocked'};
  }
}
