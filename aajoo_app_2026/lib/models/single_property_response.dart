import 'package:rent_home/utils/nightly_rates.dart';
import 'package:rent_home/models/property_offer.dart';
import 'package:rent_home/models/pet_policy.dart';

import 'package:rent_home/utils/app_log.dart';
class SinglePropertyResponse {
  final bool? success;
  final String? message;
  final SinglePropertyData? data;

  SinglePropertyResponse({
    this.success,
    this.message,
    this.data,
  });

  factory SinglePropertyResponse.fromJson(Map<String, dynamic> json) {
    return SinglePropertyResponse(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null
          ? SinglePropertyData.fromJson(json['data'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.toJson(),
    };
  }
}

class SinglePropertyData {
  final int? propertyId;
  final int? propertyHostId;
  final String? propertyName;
  final String? propertyAddress;
  final String? propertyLongitude;
  final String? propertyLatitude;
  final String? propertyDesc;
  final String? propertyPrice;
  final String? propertyMiniPrice;

  /// A discount running on this listing right now, priced by the server.
  /// Null when there is none — see [PropertyOffer].
  final PropertyOffer? offer;
  final PetPolicy pets;
  final String? propertyCity;
  final String? propertyZip;
  /// The state's NAME, e.g. "Haryana".
  ///
  /// This was typed `int?` and run through _parseIntSafely, but the column is
  /// a STRING(255) and the server has always sent a name. Every property load
  /// therefore threw the parse away and logged `Failed to parse "Haryana" to
  /// int` — the field was null on every listing the app has ever shown.
  /// host_properties_reponse.dart had it right as a String all along.
  final String? propertyState;
  final String? propertyCountry;
  final String? propertyContact;
  final String? propertyEmail;
  final bool? isActive;
  /// Legacy flag. Kept because other screens still read it, but do NOT gate the
  /// verified badge on it: it is 1 on 29,229 of the 29,232 live listings, so
  /// the "Aajoo Verified Home" card it used to guard appeared on every listing
  /// nobody had reviewed. Use [isVerified] instead.
  final bool? isVerify;

  /// "verified" | "unverified" | "draft" — the column admin verification
  /// actually writes. Ten listings are verified today.
  final String? verificationStatus;

  /// Distances the host entered at listing time (airport, hospital, bus stand…).
  /// Empty for every listing created before the listing wizard, which is nearly
  /// all of them — an empty list means "the host didn't say", never
  /// "there is nothing nearby", so the section hides rather than showing zeros.
  final List<NearbyGroup> nearby;

  /// The highlights strip — the nearest place in each section.
  ///
  /// DERIVED on the server from [nearby], so it can never disagree with the
  /// sections below it, and a host never has to keep a shortlist in step with
  /// a list. Null when there is nothing to highlight.
  final NearbyGroup? nearbyPopular;

  /// Structured house rules from the listing wizard, or null when the host
  /// never filled them in (the legacy pet/smoking flags carry it then).
  final PropertyHouseRules? houseRules;

  /// Whether this host takes offers at all (`pn_enabled` on the server).
  ///
  /// Until 2026-09-10 the only way a guest could find out was to open the
  /// offer sheet, fill it in and have the server refuse it. Defaults to true —
  /// "not stated" is not a refusal, and the server is still the real gate, so
  /// failing open costs a wasted tap at worst and never hides a live feature.
  final bool negotiationEnabled;

  /// Whether THIS guest may open a negotiation here right now, and why not.
  ///
  /// The website greys its offer button and says which of three things is
  /// true; the app had no idea any of them existed, so it showed a live
  /// button and let the server refuse the filled-in form afterwards — the
  /// dead end the client asked us to remove, still present on the phone.
  ///
  /// Null when nothing bars them (including for a signed-out visitor, whom
  /// the server never asks about).
  final NegotiationLock? negotiationLock;

  /// What the host ticked in the 5-step wizard, grouped the way the FORM
  /// grouped it, with labels already resolved server-side from the same
  /// schema the wizard renders from. A group the host left empty never
  /// arrives, so the page can render these straight through.
  final List<AmenityGroup> amenityGroups;
  final List<LabelledPick> experiences;
  final List<LabelledPick> views;
  final List<SpecLine> specifications;

  /// The host's Friday/Saturday/Sunday rates, when they set any. Null means
  /// "flat rate" — every night costs [propertyPrice].
  final PricingRule? pricing;

  /// The host's chosen cancellation policy key — flexible | moderate | firm |
  /// strict | non_refundable | custom. The API has always returned it and this
  /// model never read it, which is why the Policies panel printed an invented
  /// "free cancellation up to 48 hours" to every guest.
  final String? cancellationPolicy;
  /// Real average rating and review count from the backend aggregate; null
  /// rating means nobody has reviewed this stay yet.
  final double? rating;
  final int reviewCount;
  final int? isLuxury;
  final int? bathrooms;

  /// How many people the stay sleeps, and in how many rooms — from the 5-step
  /// listing wizard's own table.
  ///
  /// The wizard writes property_capacity; the legacy add-property form wrote
  /// tbl_property_details. This model only ever read the legacy one, so a stay
  /// created by the wizard showed a lone "2 Baths" (the one figure that lives
  /// on the property row itself) while its guest count, bedrooms and beds sat
  /// in the database unread.
  final PropertyCapacity? capacity;

  final SinglePropertyDetails? propDetails;
  final List<String>? images;
  final List<dynamic>? tags;
  final List<dynamic>? categories;
  final List<dynamic>? amenities;

  SinglePropertyData({
    this.offer,
    this.pets = PetPolicy.none,
    this.propertyId,
    this.propertyHostId,
    this.propertyName,
    this.propertyAddress,
    this.propertyLongitude,
    this.propertyLatitude,
    this.propertyDesc,
    this.propertyPrice,
    this.propertyMiniPrice,
    this.propertyCity,
    this.propertyZip,
    this.propertyState,
    this.propertyCountry,
    this.propertyContact,
    this.propertyEmail,
    this.isActive,
    this.isVerify,
    this.verificationStatus,
    this.nearby = const [],
    this.nearbyPopular,
    this.houseRules,
    this.negotiationEnabled = true,
    this.negotiationLock,
    this.amenityGroups = const [],
    this.experiences = const [],
    this.views = const [],
    this.specifications = const [],
    this.pricing,
    this.cancellationPolicy,
    this.rating,
    this.reviewCount = 0,
    this.isLuxury,
    this.bathrooms,
    this.capacity,
    this.propDetails,
    this.images,
    this.tags,
    this.categories,
    this.amenities,
  });

  factory SinglePropertyData.fromJson(Map<String, dynamic> json) {
    // Handle propDetails fields directly in the main JSON
    SinglePropertyDetails? details;
    final hasAnyPropDetail = json.keys
        .any((k) => k.toString().startsWith('propDetails.propDetail_'));
    if (hasAnyPropDetail) {
      details = SinglePropertyDetails(
        propDetailId: _parseIntSafely(json['propDetails.propDetail_id']),
        propDetailPropId:
            _parseIntSafely(json['propDetails.propDetail_propId']),
        isPetFriendly: json['propDetails.propDetail_isPetFriendly'],
        isSmoke: json['propDetails.propDetail_isSmoke'],
        inTime: json['propDetails.propDetail_inTime']?.toString(),
        outTime: json['propDetails.propDetail_outTime']?.toString(),
        extra: json['propDetails.propDetail_extra']?.toString(),
        weeklyMiniPrice:
            json['propDetails.propDetail_weeklyMini_price']?.toString(),
        weeklyMaxPrice:
            json['propDetails.propDetail_weeklyMax_price']?.toString(),
        monthlySecurity:
            json['propDetails.propDetail_monthly_security']?.toString(),
        noOfBeds:
            _parseIntSafely(json['propDetails.propDetail_no_of_beds']),
        noOfGuests:
            _parseIntSafely(json['propDetails.propDetail_no_of_guests']),
      );
    }

    return SinglePropertyData(
      offer: PropertyOffer.fromJson(json['offer']),
        pets: PetPolicy.fromJson(json['pets']),
      propertyId: _parseIntSafely(json['property_id']),
      propertyHostId: _parseIntSafely(json['property_host_id']),
      propertyName: json['property_name'],
      propertyAddress: json['property_address'],
      // A number as often as a string.
      //
      // property_latitude/longitude are floating-point columns, and whether
      // the driver hands one back as `28.47938` or `"28.47938"` depends on how
      // the row was written -- both shapes are live in tbl_properties right
      // now. Assigned raw into a String? field, the numeric form threw
      //   type 'double' is not a subtype of type 'String?'
      // and listing 29303 could not be opened at all (2026-09-12).
      //
      // Stringified rather than retyped to double: every reader already runs
      // double.tryParse over this, and toString() on the number the API sent is
      // exactly the text the other rows carry, so the map pin does not move.
      // Pinned by test/coordinates_are_not_always_strings_test.dart.
      propertyLongitude: json['property_longitude']?.toString(),
      propertyLatitude: json['property_latitude']?.toString(),
      propertyDesc: json['property_desc'],
      propertyPrice: json['property_price'],
      propertyMiniPrice: json['property_mini_price'],
      propertyCity: json['property_city'],
      propertyZip: json['property_zip'],
      propertyState: json['property_state']?.toString(),
      propertyCountry: json['property_contry'],
      propertyContact: json['property_contact'],
      propertyEmail: json['property_email'],
      isActive: json['is_active'],
      isVerify: json['is_verify'] == true || json['is_verify'] == 1,
      verificationStatus: json['verification_status']?.toString(),
      nearby: (json['nearby'] is List)
          ? (json['nearby'] as List)
              .whereType<Map>()
              .map((e) => NearbyGroup.fromJson(Map<String, dynamic>.from(e)))
              .where((g) => g.places.isNotEmpty)
              .toList()
          : const [],
      // The server already drops empty sections; this guard is for a payload
      // that predates it, not a second opinion about the rule.
      nearbyPopular: (json['nearbyPopular'] is Map)
          ? () {
              final g = NearbyGroup.fromJson(
                  Map<String, dynamic>.from(json['nearbyPopular'] as Map));
              return g.places.isEmpty ? null : g;
            }()
          : null,
      negotiationEnabled: json['negotiation'] is Map
          ? (Map<String, dynamic>.from(json['negotiation'] as Map)['enabled']
              as bool? ??
              true)
          : true,
      negotiationLock: json['negotiation'] is Map
          ? NegotiationLock.fromJson(
              Map<String, dynamic>.from(json['negotiation'] as Map))
          : null,
      houseRules: json['houseRules'] is Map
          ? PropertyHouseRules.fromJson(
              Map<String, dynamic>.from(json['houseRules'] as Map))
          : null,
      amenityGroups: (json['amenityGroups'] is List)
          ? (json['amenityGroups'] as List)
              .whereType<Map>()
              .map((e) => AmenityGroup.fromJson(Map<String, dynamic>.from(e)))
              .where((g) => g.items.isNotEmpty)
              .toList()
          : const [],
      experiences: LabelledPick.listFrom(json['experiences']),
      views: LabelledPick.listFrom(json['views']),
      specifications: (json['specifications'] is List)
          ? (json['specifications'] as List)
              .whereType<Map>()
              .map((e) => SpecLine.fromJson(Map<String, dynamic>.from(e)))
              .where((l) => l.value.isNotEmpty)
              .toList()
          : const [],
      pricing: PricingRule.fromJson(json['pricing']),
      cancellationPolicy: (() {
        final v = json['property_cancellation_policy']?.toString().trim() ?? '';
        return v.isEmpty ? null : v;
      })(),
      rating: json['rating'] == null
          ? null
          : double.tryParse(json['rating'].toString()),
      reviewCount: int.tryParse('${json['review_count'] ?? 0}') ?? 0,
      isLuxury: _parseIntSafely(json['is_luxury']),
      bathrooms: _parseIntSafely(json['bathrooms']),
      capacity: PropertyCapacity.fromJson(json['capacity']),
      propDetails: details,
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      tags: json['tags'] != null ? List<dynamic>.from(json['tags']) : null,
      categories: json['categories'] != null
          ? List<dynamic>.from(json['categories'])
          : null,
      amenities: json['amenities'] != null
          ? List<dynamic>.from(json['amenities'])
          : null,
    );
  }

  /// A-27 — the only honest source for the verified badge.
  bool get isVerified => (verificationStatus ?? '').toLowerCase() == 'verified';

  // Helper method to safely parse integers from various types
  static int? _parseIntSafely(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        appLog('Failed to parse "$value" to int: $e');
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'property_id': propertyId,
      'property_host_id': propertyHostId,
      'property_name': propertyName,
      'property_address': propertyAddress,
      'property_longitude': propertyLongitude,
      'property_latitude': propertyLatitude,
      'property_desc': propertyDesc,
      'property_price': propertyPrice,
      'property_mini_price': propertyMiniPrice,
      'property_city': propertyCity,
      'property_zip': propertyZip,
      'property_state': propertyState,
      'property_contry': propertyCountry,
      'property_contact': propertyContact,
      'property_email': propertyEmail,
      'is_active': isActive,
      'is_verify': isVerify,
      'is_luxury': isLuxury,
      'images': images,
    };

    // Add property details directly to the main JSON if available
    if (propDetails != null) {
      data['propDetails.propDetail_id'] = propDetails!.propDetailId;
      data['propDetails.propDetail_propId'] = propDetails!.propDetailPropId;
      data['propDetails.propDetail_isPetFriendly'] = propDetails!.isPetFriendly;
      data['propDetails.propDetail_isSmoke'] = propDetails!.isSmoke;
      data['propDetails.propDetail_inTime'] = propDetails!.inTime;
      data['propDetails.propDetail_outTime'] = propDetails!.outTime;
      data['propDetails.propDetail_extra'] = propDetails!.extra;
    }

    return data;
  }
}

class SinglePropertyDetails {
  final int? propDetailId;
  final int? propDetailPropId;
  final bool? isPetFriendly;
  final bool? isSmoke;
  final String? inTime;
  final String? outTime;
  final String? extra;
  final String? weeklyMiniPrice;
  final String? weeklyMaxPrice;
  final String? monthlySecurity;
  final int? noOfBeds;
  final int? noOfGuests;

  SinglePropertyDetails({
    this.propDetailId,
    this.propDetailPropId,
    this.isPetFriendly,
    this.isSmoke,
    this.inTime,
    this.outTime,
    this.extra,
    this.weeklyMiniPrice,
    this.weeklyMaxPrice,
    this.monthlySecurity,
    this.noOfBeds,
    this.noOfGuests,
  });

  factory SinglePropertyDetails.fromJson(Map<String, dynamic> json) {
    return SinglePropertyDetails(
      propDetailId: SinglePropertyData._parseIntSafely(json['propDetail_id']),
      propDetailPropId:
          SinglePropertyData._parseIntSafely(json['propDetail_propId']),
      isPetFriendly: json['propDetail_isPetFriendly'],
      isSmoke: json['propDetail_isSmoke'],
      inTime: json['propDetail_inTime'],
      outTime: json['propDetail_outTime'],
      extra: json['propDetail_extra'],
      weeklyMiniPrice: json['propDetail_weeklyMini_price']?.toString(),
      weeklyMaxPrice: json['propDetail_weeklyMax_price']?.toString(),
      monthlySecurity: json['propDetail_monthly_security']?.toString(),
      noOfBeds: SinglePropertyData._parseIntSafely(json['propDetail_no_of_beds']),
      noOfGuests:
          SinglePropertyData._parseIntSafely(json['propDetail_no_of_guests']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'propDetail_id': propDetailId,
      'propDetail_propId': propDetailPropId,
      'propDetail_isPetFriendly': isPetFriendly,
      'propDetail_isSmoke': isSmoke,
      'propDetail_inTime': inTime,
      'propDetail_outTime': outTime,
      'propDetail_extra': extra,
      'propDetail_weeklyMini_price': weeklyMiniPrice,
      'propDetail_weeklyMax_price': weeklyMaxPrice,
      'propDetail_monthly_security': monthlySecurity,
    };
  }
}

/// One nearby category ("Transport") and the places under it, as
/// GET /properties/:id returns them. Distances are in kilometres.
/// One labelled thing the host picked (an amenity, a view, an experience).
class LabelledPick {
  final String key;
  final String label;
  const LabelledPick({required this.key, required this.label});

  factory LabelledPick.fromJson(Map<String, dynamic> json) => LabelledPick(
        key: (json['key'] ?? '').toString(),
        label: (json['label'] ?? json['key'] ?? '').toString(),
      );

  static List<LabelledPick> listFrom(dynamic raw) => raw is List
      ? raw
          .whereType<Map>()
          .map((e) => LabelledPick.fromJson(Map<String, dynamic>.from(e)))
          .where((p) => p.label.isNotEmpty)
          .toList()
      : const [];
}

/// A group of amenities as the wizard asked for them (Bathroom, Internet…).
class AmenityGroup {
  final String key;
  final String label;
  final List<LabelledPick> items;
  const AmenityGroup({required this.key, required this.label, required this.items});

  factory AmenityGroup.fromJson(Map<String, dynamic> json) => AmenityGroup(
        key: (json['key'] ?? '').toString(),
        label: (json['label'] ?? '').toString(),
        items: LabelledPick.listFrom(json['items']),
      );
}

/// A step-2 property detail, already formatted for printing.
class SpecLine {
  final String key;
  final String label;
  final String value;
  const SpecLine({required this.key, required this.label, required this.value});

  factory SpecLine.fromJson(Map<String, dynamic> json) => SpecLine(
        key: (json['key'] ?? '').toString(),
        label: (json['label'] ?? '').toString(),
        value: (json['value'] ?? '').toString(),
      );
}

/// One section of "what's around this property".
///
/// The server sends these already filtered — an empty section is not sent —
/// and in the order a guest asks the questions. Neither rule is repeated
/// here, because the website renders the same payload and two copies of a
/// rule is how two screens come to disagree.
class NearbyGroup {
  final String key;
  final String label;

  /// A Lucide-style name chosen server-side, so the app and the website show
  /// the same picture for the same section. Empty for older payloads.
  final String icon;
  final String blurb;
  final List<NearbyPlace> places;

  const NearbyGroup({
    required this.key,
    required this.label,
    this.icon = '',
    this.blurb = '',
    required this.places,
  });

  factory NearbyGroup.fromJson(Map<String, dynamic> json) => NearbyGroup(
        key: (json['key'] ?? '').toString(),
        label: (json['label'] ?? '').toString(),
        icon: (json['icon'] ?? '').toString(),
        blurb: (json['blurb'] ?? '').toString(),
        places: (json['places'] is List)
            ? (json['places'] as List)
                .whereType<Map>()
                .map((e) => NearbyPlace.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : const [],
      );
}

class NearbyPlace {
  /// The place's own name — "Hidimba Devi Temple", not "Temple".
  ///
  /// Falls back to [place] so a payload from before this feature still reads:
  /// the server sends both for exactly that reason.
  final String name;

  /// The older field name. Same value on a current payload.
  final String place;
  final String slug;
  final double km;

  /// Where it is. BOTH or NEITHER — a directions link built from half a
  /// coordinate opens the middle of the ocean, and a guest would trust it,
  /// follow it, and blame the listing.
  final double? lat;
  final double? lng;
  final String? placeId;

  /// Who says so: 'google' for a place the host picked off the map, 'manual'
  /// for a name and a distance they typed themselves.
  ///
  /// A Google-picked place carries a place_id, a real position and a
  /// directions link — the platform can stand behind the distance. A manual
  /// entry has nothing checking either half of it, and rendered in the same
  /// row a guest cannot tell the two apart.
  final String source;

  bool get isHostProvided => source == 'manual';

  const NearbyPlace({
    required this.name,
    required this.place,
    required this.slug,
    required this.km,
    this.lat,
    this.lng,
    this.placeId,
    this.source = 'manual',
  });

  factory NearbyPlace.fromJson(Map<String, dynamic> json) {
    final place = (json['place'] ?? '').toString();
    final name = (json['name'] ?? '').toString();
    final lat = double.tryParse('${json['lat']}');
    final lng = double.tryParse('${json['lng']}');
    final located = lat != null && lng != null;
    return NearbyPlace(
      name: name.isNotEmpty ? name : place,
      place: place.isNotEmpty ? place : name,
      slug: (json['slug'] ?? '').toString(),
      km: double.tryParse('${json['km']}') ?? 0,
      lat: located ? lat : null,
      lng: located ? lng : null,
      placeId: (json['placeId'] ?? '').toString().isEmpty ? null : json['placeId'].toString(),
      // Defaults to 'manual' — the cautious answer. An older payload with no
      // source is more likely a typed entry than a verified one, and marking
      // a verified place "Host provided" costs nothing while the reverse
      // vouches for something nobody checked.
      source: (json['source'] ?? 'manual').toString(),
    );
  }

  /// A Google Maps directions URL, or null when the position is unknown.
  String? get directionsUrl {
    if (lat == null || lng == null) return null;
    final id = placeId == null ? '' : '&destination_place_id=$placeId';
    return 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng$id';
  }

  /// "600 m" reads better than "0.6 km" and is what the spec asks for.
  String get distanceLabel =>
      km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(km == km.roundToDouble() ? 0 : 1)} km';
}

/// House rules from the listing wizard.
///
/// Every flag is nullable and null means the host never answered — which is
/// NOT the same as "no". A null is left out of the list rather than rendered
/// as a red cross against a rule the host never considered.
class PropertyHouseRules {
  final bool? petsAllowed;
  final double? petFee;

  /// Asked of hosts since the wizard shipped and shown to nobody until
  /// 2026-09-10 — they existed in the backend schema file and nowhere else.
  /// Null when pets are not allowed, so a no-pets listing cannot advertise a
  /// pet bed.
  final bool? petBeds;
  final bool? petFood;
  final bool? petArea;
  final bool? smoking;
  final bool? alcohol;
  final bool? visitors;
  final bool? parties;
  final bool? loudMusic;
  final bool? commercialShoot;
  final bool? cookingAllowed;
  final bool? selfCheckin;
  final bool? caretakerAvailable;
  final String? quietHours;
  final bool? damageDeposit;

  const PropertyHouseRules({
    this.petsAllowed,
    this.petFee,
    this.petBeds,
    this.petFood,
    this.petArea,
    this.smoking,
    this.alcohol,
    this.visitors,
    this.parties,
    this.loudMusic,
    this.commercialShoot,
    this.cookingAllowed,
    this.selfCheckin,
    this.caretakerAvailable,
    this.quietHours,
    this.damageDeposit,
  });

  static bool? _b(dynamic v) => v == null ? null : (v == true || v == 1);

  factory PropertyHouseRules.fromJson(Map<String, dynamic> json) =>
      PropertyHouseRules(
        petsAllowed: _b(json['petsAllowed']),
        petFee: json['petFee'] == null
            ? null
            : double.tryParse('${json['petFee']}'),
        petBeds: _b(json['petBeds']),
        petFood: _b(json['petFood']),
        petArea: _b(json['petArea']),
        smoking: _b(json['smoking']),
        alcohol: _b(json['alcohol']),
        visitors: _b(json['visitors']),
        parties: _b(json['parties']),
        loudMusic: _b(json['loudMusic']),
        commercialShoot: _b(json['commercialShoot']),
        cookingAllowed: _b(json['cookingAllowed']),
        selfCheckin: _b(json['selfCheckin']),
        caretakerAvailable: _b(json['caretakerAvailable']),
        quietHours: json['quietHours']?.toString(),
        damageDeposit: _b(json['damageDeposit']),
      );
}


/// The wizard's capacity record for one stay.
///
/// Every figure is nullable on purpose: a host who has not answered is not the
/// same as a host who answered zero, and a stay that sleeps an unknown number
/// must show nothing rather than "0 guests".
class PropertyCapacity {
  const PropertyCapacity({
    this.totalGuests,
    this.adults,
    this.children,
    this.infants,
    this.bedrooms,
    this.beds,
    this.bathrooms,
  });

  final int? totalGuests;
  final int? adults;
  final int? children;
  final int? infants;
  final int? bedrooms;
  final int? beds;
  final int? bathrooms;

  static int? _n(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  static PropertyCapacity? fromJson(dynamic json) {
    if (json is! Map) return null;
    final j = Map<String, dynamic>.from(json);
    final c = PropertyCapacity(
      totalGuests: _n(j['totalGuests']),
      adults: _n(j['adults']),
      children: _n(j['children']),
      infants: _n(j['infants']),
      bedrooms: _n(j['bedrooms']),
      beds: _n(j['beds']),
      bathrooms: _n(j['bathrooms']),
    );
    // An all-null record carries nothing; treat it as absent so callers can
    // fall back to the legacy figures instead of showing an empty row.
    return c.isEmpty ? null : c;
  }

  bool get isEmpty =>
      totalGuests == null &&
      adults == null &&
      children == null &&
      infants == null &&
      bedrooms == null &&
      beds == null &&
      bathrooms == null;
}


/// Why this guest cannot open a negotiation on this listing right now.
///
/// Three reasons, and they need three different sentences:
///
///   accepted  a price is already agreed for those nights -- book it
///   parting   the host walked away and left their last price for an hour
///   declined  the host answered an offer today; tomorrow is a new day
///
/// The first two are scoped to [from]..[to], so a guest who agreed a price for
/// this weekend may still negotiate next weekend on the same property. The
/// third is scoped to the IST day and carries no dates at all.
class NegotiationLock {
  final bool locked;

  /// "accepted" | "parting" | "declined", or null when nothing is barred.
  final String? reason;

  /// When it lifts -- midnight IST for a decline, the coupon's expiry for the
  /// other two.
  final DateTime? until;

  /// What the held deal comes to per night. Zero when there is none to name:
  /// a host who declines an OPENING offer never named a price, and inventing
  /// one would be a promise nobody made.
  final double price;

  /// The nights the deal covers, DD-MM-YYYY, or null for a day-scoped lock.
  final String? from;
  final String? to;

  const NegotiationLock({
    required this.locked,
    this.reason,
    this.until,
    this.price = 0,
    this.from,
    this.to,
  });

  factory NegotiationLock.fromJson(Map<String, dynamic> json) {
    String? str(dynamic v) {
      final s = v?.toString().trim() ?? '';
      return s.isEmpty ? null : s;
    }

    final until = str(json['lockedUntil']);
    return NegotiationLock(
      // The server sends lockedUntil only when something is actually barred,
      // so its presence IS the lock -- there is no separate boolean to drift
      // out of step with it.
      locked: until != null,
      reason: str(json['lockReason']),
      until: until == null ? null : DateTime.tryParse(until),
      price: double.tryParse((json['lockPrice'] ?? 0).toString()) ?? 0,
      from: str(json['lockFrom']),
      to: str(json['lockTo']),
    );
  }

  /// Does this lock bar the dates on screen?
  ///
  /// A decline shuts the whole listing for the day, so it bars any dates. A
  /// held deal bars only its own nights -- and when the guest has not picked
  /// any yet, the deal is still worth saying out loud.
  bool barsDates(String? stayFrom, String? stayTo) {
    if (!locked) return false;
    if (reason == 'declined') return true;
    if (from == null || to == null) return true;
    if (stayFrom == null || stayTo == null) return true;
    return from == stayFrom && to == stayTo;
  }

  /// The line under the greyed button. Same words as the website's.
  String get shortLabel {
    switch (reason) {
      case 'accepted':
        return 'Already agreed for these dates';
      case 'parting':
        return 'This negotiation has ended';
      default:
        return 'Available again tomorrow';
    }
  }

  /// Whole minutes left, floored at zero. Used only by the parting sentence,
  /// which is the one with an hour on it.
  int get minutesLeft {
    if (until == null) return 0;
    final ms = until!.difference(DateTime.now()).inMinutes;
    return ms > 0 ? ms : 0;
  }
}
