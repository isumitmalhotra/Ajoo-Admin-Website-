/// What a host said about pets.
///
/// The backend has collected this since the listing wizard shipped — pets
/// allowed, a fee, an allowed size — and until 2026-08-31 none of it reached a
/// guest on either platform. `/properties/search`, `/properties/list` and
/// `/properties/:id` all carry the same `pets` block now, which is the point:
/// they used to describe one policy three different ways, and the property page
/// found nothing because it was looking for the shape the cards used.
///
/// The fee is **per pet, per night**, matching the extra-guest charge. Pets
/// never count toward guest capacity — they do not occupy beds — so they are
/// counted apart, with their own cap.
class PetPolicy {
  const PetPolicy({
    this.petsAllowed = false,
    this.feePerNight = 0,
    this.size,
    this.maxPets = 0,
  });

  final bool petsAllowed;
  final double feePerNight;

  /// "Small / Medium / Large", free text the host typed. Null when unset.
  final String? size;

  /// The host's cap. 0 means they stated none, the same way the extra-guest
  /// cap reads — not "no pets".
  final int maxPets;

  /// A listing with no policy of its own. A host who was never asked has not
  /// said yes, so this is the safe reading rather than a permissive one.
  static const none = PetPolicy();

  /// Tolerant of every shape the field arrives in.
  ///
  /// `phr_pet_fee` is a DECIMAL and reaches Dart as the string "200.00" —
  /// `int.parse` returns null on that, which is exactly how a five-star review
  /// once rendered as five empty stars. Parsed as a number and left as one.
  factory PetPolicy.fromJson(dynamic json) {
    if (json is! Map) return none;
    double num_(dynamic v) =>
        v is num ? v.toDouble() : (double.tryParse('${v ?? ''}') ?? 0);
    final rawSize = '${json['petSize'] ?? ''}'.trim();
    return PetPolicy(
      petsAllowed: json['petsAllowed'] == true || json['petsAllowed'] == 1,
      feePerNight: num_(json['petFeePerNight']),
      size: rawSize.isEmpty ? null : rawSize,
      maxPets: num_(json['maxPets']).round(),
    );
  }

  /// What this many pets cost for this many nights — the same arithmetic the
  /// server does, kept here only so a stepper can preview it. The charge that
  /// is actually billed always comes from /pricing/quote.
  double feeFor(int pets, int nights) {
    if (!petsAllowed || feePerNight <= 0 || pets <= 0 || nights <= 0) return 0;
    return pets * feePerNight * nights;
  }

  Map<String, dynamic> toJson() => {
        'petsAllowed': petsAllowed,
        'petFeePerNight': feePerNight,
        'petSize': size,
        'maxPets': maxPets,
      };
}
