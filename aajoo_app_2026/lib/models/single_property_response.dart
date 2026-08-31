import 'package:rent_home/utils/nightly_rates.dart';
import 'package:rent_home/models/property_offer.dart';

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

  /// Structured house rules from the listing wizard, or null when the host
  /// never filled them in (the legacy pet/smoking flags carry it then).
  final PropertyHouseRules? houseRules;

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
    this.houseRules,
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
      propertyId: _parseIntSafely(json['property_id']),
      propertyHostId: _parseIntSafely(json['property_host_id']),
      propertyName: json['property_name'],
      propertyAddress: json['property_address'],
      propertyLongitude: json['property_longitude'],
      propertyLatitude: json['property_latitude'],
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
        print('Failed to parse "$value" to int: $e');
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

class NearbyGroup {
  final String key;
  final String label;
  final List<NearbyPlace> places;

  const NearbyGroup({
    required this.key,
    required this.label,
    required this.places,
  });

  factory NearbyGroup.fromJson(Map<String, dynamic> json) => NearbyGroup(
        key: (json['key'] ?? '').toString(),
        label: (json['label'] ?? '').toString(),
        places: (json['places'] is List)
            ? (json['places'] as List)
                .whereType<Map>()
                .map((e) => NearbyPlace.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : const [],
      );
}

class NearbyPlace {
  final String place;
  final String slug;
  final double km;

  const NearbyPlace({required this.place, required this.slug, required this.km});

  factory NearbyPlace.fromJson(Map<String, dynamic> json) => NearbyPlace(
        place: (json['place'] ?? '').toString(),
        slug: (json['slug'] ?? '').toString(),
        km: double.tryParse('${json['km']}') ?? 0,
      );

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
