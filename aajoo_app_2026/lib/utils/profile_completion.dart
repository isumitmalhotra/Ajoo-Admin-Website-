/// How complete a guest's profile is — the Dart mirror of the web's
/// redesign/components/ProfileCompletion.tsx.
///
/// The weights are not decoration. Identity verification is weighted 3 because
/// without it a booking cannot complete, so it is the one gap worth
/// interrupting somebody about; the phone is 2 because a host needs a way to
/// reach the guest on the day. Keep these in step with the web — a profile that
/// reads "80% complete" on the phone and "65%" on the site is worse than not
/// showing a number at all.
library;

class ProfileField {
  const ProfileField({
    required this.key,
    required this.label,
    required this.done,
    required this.weight,
    required this.hint,
  });

  final String key;
  final String label;
  final bool done;
  final int weight;
  final String hint;
}

class ProfileScore {
  const ProfileScore({
    required this.fields,
    required this.percent,
    required this.strength,
  });

  final List<ProfileField> fields;
  final int percent;
  final String strength;

  List<ProfileField> get missing =>
      fields.where((f) => !f.done).toList(growable: false);

  bool get isComplete => percent >= 100;
}

String _s(Object? v) => v == null ? '' : v.toString().trim();

/// [user] is the decoded /user/detail payload (or the login user object).
ProfileScore profileScore(Map<String, dynamic>? user) {
  final u = user ?? const <String, dynamic>{};

  // Verified means EITHER the legacy flag or a current DIDIT decision — the
  // same two-sided read the rest of the app uses, because verification_status
  // alone goes stale on an abandoned attempt.
  final verified = _s(u['user_isVerified']) == '1' ||
      u['user_isVerified'] == true ||
      u['user_isVerified'] == 1 ||
      _s(u['verification_status'] ?? u['kyc_status']).toLowerCase() ==
          'verified';

  final fields = <ProfileField>[
    ProfileField(
        key: 'name',
        label: 'Your name',
        done: _s(u['user_fullName']).isNotEmpty,
        weight: 1,
        hint: 'So hosts know who they are welcoming.'),
    ProfileField(
        key: 'email',
        label: 'Email address',
        done: _s(u['cred_user_email'] ?? u['user_email']).isNotEmpty,
        weight: 1,
        hint: 'Where booking confirmations go.'),
    ProfileField(
        key: 'phone',
        label: 'Mobile number',
        done: _s(u['user_pnumber']).isNotEmpty,
        weight: 2,
        hint: 'Hosts need a way to reach you on the day.'),
    ProfileField(
        key: 'photo',
        label: 'Profile photo',
        done: _s(u['attachment'] ?? u['user_image']).isNotEmpty,
        weight: 1,
        hint: 'Hosts accept guests with a photo more often.'),
    ProfileField(
        key: 'dob',
        label: 'Date of birth',
        done: _s(u['user_dob']).isNotEmpty,
        weight: 1,
        hint: 'Some stays have a minimum age.'),
    ProfileField(
        key: 'address',
        label: 'Address',
        done: _s(u['user_address']).isNotEmpty,
        weight: 1,
        hint: 'Used on your invoices.'),
    ProfileField(
        key: 'city',
        label: 'City',
        done: _s(u['user_city']).isNotEmpty,
        weight: 1,
        hint: 'Helps us suggest stays near you.'),
    ProfileField(
        key: 'kyc',
        label: 'Identity verification',
        done: verified,
        weight: 3,
        hint: 'Required before you can confirm a booking.'),
  ];

  final total = fields.fold<int>(0, (s, f) => s + f.weight);
  final earned = fields.fold<int>(0, (s, f) => s + (f.done ? f.weight : 0));
  final percent = total == 0 ? 0 : ((earned / total) * 100).round();
  final strength = percent >= 100
      ? 'Complete'
      : percent >= 75
          ? 'Strong'
          : percent >= 45
              ? 'Good'
              : 'Basic';

  return ProfileScore(fields: fields, percent: percent, strength: strength);
}
