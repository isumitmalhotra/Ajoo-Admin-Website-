/// The public, display-safe part of a host's profile.
///
/// Backed by GET /properties/host/:hostId, which the web's property detail has
/// used since it was built. The property payload itself carries no host name —
/// only `property_host_id`, `property_contact` and `property_email` — so
/// without this call there is nothing on the page to identify the host with.
/// The endpoint deliberately withholds email, phone and KYC.
class HostProfile {
  const HostProfile({
    required this.hostId,
    required this.name,
    this.city,
    this.image,
    this.propertyCount,
    this.memberSince,
  });

  final int hostId;
  final String name;
  final String? city;
  final String? image;
  final int? propertyCount;
  final int? memberSince;

  factory HostProfile.fromJson(Map<String, dynamic> json) => HostProfile(
        hostId: int.tryParse('${json['hostId']}') ?? 0,
        name: (json['name'] ?? '').toString().trim().isEmpty
            ? 'Host'
            : json['name'].toString().trim(),
        city: (json['city'] as String?)?.trim().isEmpty ?? true
            ? null
            : (json['city'] as String).trim(),
        image: (json['image'] as String?)?.trim().isEmpty ?? true
            ? null
            : (json['image'] as String).trim(),
        propertyCount: int.tryParse('${json['propertyCount']}'),
        memberSince: int.tryParse('${json['memberSince']}'),
      );

  /// "9 properties · Member since 2026 · Goa" — the same line the web builds,
  /// with the parts the host actually has. Never empty.
  String get subtitle {
    final parts = <String>[
      if (propertyCount != null && propertyCount! > 0)
        '$propertyCount ${propertyCount == 1 ? 'property' : 'properties'}',
      if (memberSince != null) 'Member since $memberSince',
      if (city != null) city!,
    ];
    return parts.isEmpty ? 'Verified Aajoo host' : parts.join(' · ');
  }
}
