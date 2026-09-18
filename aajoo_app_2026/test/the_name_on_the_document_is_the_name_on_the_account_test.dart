// A DIDIT approval is granted only when the document's name is the account's
// (backend, 2026-09-19 — a signup had verified with a friend's Aadhaar). The
// app's share: a refused check says WHY, in the alert after the check and on
// the dashboard nudge, and the user model carries the server's reason.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rent_home/models/user_models.dart';

String codeOnly(String src) => src
    .replaceAll('\r\n', '\n')
    .split('\n')
    .where((l) => !l.trimLeft().startsWith('//') && !l.trimLeft().startsWith('///'))
    .join('\n');

Map<String, dynamic> userJson({String status = 'declined', String? reason}) => {
      'cred_id': 1, 'cred_user_id': 501, 'cred_username': 'r', 'cred_user_email': 'r@x.in',
      'user_isHost': 0, 'user_isUser': 1, 'userId': 501, 'user_fullName': 'Aajoo Renter',
      'user_pnumber': '9999999999', 'user_isVerified': 0, 'user_address': '', 'user_city': '',
      'user_state': '', 'user_zipcode': '', 'verification_status': status,
      if (reason != null) 'verification_reason': reason,
    };

void main() {
  final service = codeOnly(File('lib/service/verify_service.dart').readAsStringSync());
  final controller = codeOnly(File('lib/ui/screens_common/auth/kyc/kyc_controller.dart').readAsStringSync());
  final nudge = codeOnly(File('lib/ui/widgets/verify_nudge.dart').readAsStringSync());

  group('the user model', () {
    test('carries the reason the server sends for a declined account', () {
      final u = UserDetail.fromJson(userJson(reason: 'name_mismatch'));
      expect(u.verificationStatus, 'declined');
      expect(u.verificationReason, 'name_mismatch');
      expect(u.toJson()['verification_reason'], 'name_mismatch');
    });

    test('has no reason when the server sends none', () {
      expect(UserDetail.fromJson(userJson(status: 'verified')).verificationReason, isNull);
      expect(UserDetail.fromJson(userJson()).verificationReason, isNull);
    });
  });

  group('the service', () {
    test('keeps the reason beside the status it returns', () {
      expect(service, contains('String? lastReason;'));
      expect(service, contains("final r = data['reason'];"));
      expect(service, contains('lastReason = null;'), reason: 'a later read without a reason must clear it');
    });
  });

  group('the alert after the check', () {
    test('a name refusal gets its own words, not "please try again"', () {
      expect(controller, contains("_service.lastReason == 'name_mismatch'"));
      expect(controller, contains('"The name on the document didn\'t match"'));
      expect(controller, contains('Verify with your own government ID'));
    });
  });

  group('the dashboard nudge', () {
    test('reads the reason and swaps the declined copy', () {
      expect(nudge, contains("user.verificationReason == 'name_mismatch'"));
      expect(nudge, contains("'declined' when nameMismatch => ("));
      expect(nudge, contains("cta: 'Use your own ID'"));
      final start = nudge.indexOf("'declined' when nameMismatch");
      final block = nudge.substring(start, nudge.indexOf('),', start));
      expect(block, isNot(contains('clearer photo')), reason: "a clearer photo of a friend's document would not help");
    });
  });
}
