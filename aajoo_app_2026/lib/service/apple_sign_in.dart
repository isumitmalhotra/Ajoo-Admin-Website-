// Sign in with Apple, as far as a Firebase ID token.
//
// Kept out of the controller because three details here are easy to get
// subtly wrong, fail silently, and look like "Apple sign-in is broken":
//
// 1. THE NONCE IS SENT TWICE, IN TWO FORMS. Apple is given the SHA-256 of a
//    random string; Firebase is given the string itself and hashes it again to
//    compare. Send the same form to both and Firebase rejects the credential
//    with a generic "invalid credential" that says nothing about nonces.
//
// 2. THE NAME COMES BACK ONCE, FROM HERE, NOT FROM THE TOKEN. Apple returns
//    givenName/familyName on the FIRST authorization for this app and never
//    again — and never inside the identity token at all. If the client does
//    not carry it to our server on that first call, the account is named
//    after the local part of an email address for ever.
//
// 3. ANDROID NEEDS webAuthenticationOptions. iOS uses the system sheet; every
//    other platform is redirected through Apple's web flow, which needs the
//    Services ID as its client id and the Firebase handler as its return URL.
//    Omit it and the call throws on Android before a sheet ever appears.
//
// Why Apple on Android at all: an account created on an iPhone with Sign in
// with Apple has an unusable password by design, so without this the same
// person cannot get into their own account on an Android handset. Firebase
// issues one user record per Apple identity per project, so the uid — which is
// what our server stores — is the same on both, and it is the same account.

import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// The Services ID registered at developer.apple.com, used as the OAuth client
/// id for the web redirect flow (Android, and the website).
const String kAppleServicesId = 'com.aajoo.aajoohomes.web';

/// The bundle id, which is the OAuth client id for a NATIVE iOS sign-in.
///
/// Not interchangeable with the Services ID: Apple issues its tokens against
/// whichever client asked, and a token minted for one cannot be revoked with
/// the other — Apple answers invalid_client and revokes nothing. So the client
/// is reported to the server alongside the code, rather than assumed there.
const String kAppleBundleId = 'com.aajoo.aajoohomes';

/// Firebase's auth handler, registered as the Return URL on that Services ID.
/// The two must agree exactly or Apple refuses the redirect.
const String kAppleRedirectUri =
    'https://aajoo-bdb20.firebaseapp.com/__/auth/handler';

/// What an Apple sign-in produced: a Firebase token our server can verify, and
/// the name if Apple happened to send one.
class AppleSignInResult {
  const AppleSignInResult({
    required this.firebaseIdToken,
    required this.clientId,
    this.fullName,
    this.authorizationCode,
  });

  final String firebaseIdToken;

  /// Which Apple client this sign-in went through — the bundle id natively,
  /// the Services ID through the web flow. The server stores it beside the
  /// token, because revoking with the wrong one silently does nothing.
  final String clientId;

  /// Only ever non-null on the FIRST authorization. Never treat it as identity.
  final String? fullName;

  /// The one-time code the server trades for a refresh token, so it can revoke
  /// this link when the account is deleted. Deleting without revoking leaves
  /// Apple believing the app is still authorised — and Apple then sends no
  /// email if the person ever signs up again, which the server cannot accept.
  final String? authorizationCode;
}

/// Raised when the person backs out of the Apple sheet. Not an error.
class AppleSignInCancelled implements Exception {}

/// A cryptographically random string for the nonce.
///
/// Not `Random()`: a predictable nonce defeats the replay protection the nonce
/// exists for.
String generateRawNonce([int length = 32]) {
  const charset =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  final random = Random.secure();
  return List.generate(length, (_) => charset[random.nextInt(charset.length)])
      .join();
}

/// The form Apple is given: the SHA-256 of the raw nonce, as hex.
String sha256OfNonce(String rawNonce) =>
    sha256.convert(utf8.encode(rawNonce)).toString();

/// Join the two halves of an Apple name, tolerating either being absent.
///
/// Apple can send a given name with no family name, both, or neither, and
/// "null null" has been shipped as a display name by more than one app.
String? appleFullName(String? givenName, String? familyName) {
  final parts = [givenName, familyName]
      .map((p) => (p ?? '').trim())
      .where((p) => p.isNotEmpty)
      .toList();
  return parts.isEmpty ? null : parts.join(' ');
}

/// Run the whole flow and return a Firebase ID token.
///
/// Throws [AppleSignInCancelled] when the person dismisses the sheet, and
/// rethrows anything else for the caller to report.
Future<AppleSignInResult> signInWithApple() async {
  final rawNonce = generateRawNonce();

  final AuthorizationCredentialAppleID credential;
  try {
    credential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      // Apple gets the HASH.
      nonce: sha256OfNonce(rawNonce),
      webAuthenticationOptions: WebAuthenticationOptions(
        clientId: kAppleServicesId,
        redirectUri: Uri.parse(kAppleRedirectUri),
      ),
    );
  } on SignInWithAppleAuthorizationException catch (e) {
    if (e.code == AuthorizationErrorCode.canceled) {
      throw AppleSignInCancelled();
    }
    rethrow;
  }

  final oauth = fb.OAuthProvider('apple.com').credential(
    idToken: credential.identityToken,
    // Firebase gets the RAW string and hashes it itself.
    rawNonce: rawNonce,
  );

  final userCredential =
      await fb.FirebaseAuth.instance.signInWithCredential(oauth);
  final token = await userCredential.user?.getIdToken();
  if (token == null) {
    throw StateError('Apple sign-in produced no Firebase token');
  }

  return AppleSignInResult(
    firebaseIdToken: token,
    // iOS talks to Apple directly as the app; everywhere else goes through the
    // web flow, which identifies itself with the Services ID.
    clientId: Platform.isIOS ? kAppleBundleId : kAppleServicesId,
    fullName: appleFullName(credential.givenName, credential.familyName),
    authorizationCode: credential.authorizationCode,
  );
}
