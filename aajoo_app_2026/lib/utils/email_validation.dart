/// One definition of "is this an email", for the whole app.
///
/// There were four, and they disagreed. The login/signup screen used
/// `^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$`, which rejects two things it should not:
///
///   - a `+` in the local part — `you+tag@gmail.com` is a real, extremely
///     common address, and the screen refused it at BOTH login and signup, so
///     such an account could never be created in the first place;
///   - any TLD longer than four characters — `.online`, `.travel`, `.museum`.
///
/// The backend accepts both (its login schema does no format check at all), so
/// the app was the only thing saying no.
///
/// This pattern is deliberately the same shape as the web's `isEmail` in
/// `src/redesign/lib/formErrors.ts` — an address accepted on one platform has
/// to be accepted on the other, or a guest who signs up on the website cannot
/// log into the app.
///
/// It is intentionally permissive. Client-side email validation exists to
/// catch a typo, not to adjudicate RFC 5322; the address is proven by the OTP
/// that follows, and every pattern strict enough to reject a real edge case
/// rejects some real addresses too.
library;

final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[A-Za-z]{2,}$');

/// True when [value] looks like an email address.
bool isValidEmail(String? value) => _email.hasMatch((value ?? '').trim());

/// True when [value] looks like an Indian 10-digit mobile number rather than
/// an email. Used by the login field, which accepts either.
bool looksLikeMobile(String? value) {
  final v = (value ?? '').trim();
  if (v.contains('@')) return false;
  return v.replaceAll(RegExp(r'\D'), '').length == 10;
}
