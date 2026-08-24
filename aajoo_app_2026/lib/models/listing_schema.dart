// The listing schema, as the backend defines it.
//
// This is a Dart mirror of the website's `ListingSchema` (services/listingApi.ts).
// It exists so the app's listing wizard can be the SAME form as the website's
// rather than a hand-copied likeness of it: the eleven category flows, the
// accommodation rules, the amenity groups and the validation all live once,
// server-side, in GET /listing/schema. Neither client hard-codes a category.
//
// The practical consequence: when the platform adds a category or moves a
// field, both the site and the app pick it up on the next launch, and they
// cannot drift apart in the meantime.
library;

/// One selectable value.
class Option {
  const Option({required this.value, required this.label});

  final String value;
  final String label;

  factory Option.fromJson(Map<String, dynamic> j) => Option(
        value: (j['value'] ?? '').toString(),
        label: (j['label'] ?? j['value'] ?? '').toString(),
      );

  static List<Option> listFrom(dynamic v) => v is List
      ? v
          .whereType<Map>()
          .map((e) => Option.fromJson(Map<String, dynamic>.from(e)))
          .toList()
      : const [];
}

/// A status option, which can carry extra rules.
class StatusOption extends Option {
  const StatusOption({
    required super.value,
    required super.label,
    this.blocksPublish = false,
    this.requiresMonths = false,
  });

  /// Choosing this status means the listing cannot be published yet.
  final bool blocksPublish;

  /// Choosing this status requires the host to name the months they operate.
  final bool requiresMonths;

  factory StatusOption.fromJson(Map<String, dynamic> j) => StatusOption(
        value: (j['value'] ?? '').toString(),
        label: (j['label'] ?? '').toString(),
        blocksPublish: j['blocksPublish'] == true,
        requiresMonths: j['requiresMonths'] == true,
      );
}

/// "Show this field only when a sibling currently equals X."
class ShowIf {
  const ShowIf({required this.key, required this.equals});

  final String key;
  final dynamic equals;

  static ShowIf? fromJson(dynamic v) {
    if (v is! Map) return null;
    return ShowIf(key: (v['key'] ?? '').toString(), equals: v['equals']);
  }
}

enum FieldType { text, number, select, multiselect, boolean, time, textarea }

FieldType _fieldType(String? raw) {
  switch (raw) {
    case 'number':
      return FieldType.number;
    case 'select':
      return FieldType.select;
    case 'multiselect':
      return FieldType.multiselect;
    case 'boolean':
      return FieldType.boolean;
    case 'time':
      return FieldType.time;
    case 'textarea':
      return FieldType.textarea;
    default:
      return FieldType.text;
  }
}

/// One field of the form, exactly as the server describes it.
class SchemaField {
  const SchemaField({
    required this.key,
    required this.label,
    required this.type,
    this.options = const [],
    this.required = false,
    this.help,
    this.showIf,
  });

  final String key;
  final String label;
  final FieldType type;
  final List<Option> options;
  final bool required;
  final String? help;
  final ShowIf? showIf;

  factory SchemaField.fromJson(Map<String, dynamic> j) => SchemaField(
        key: (j['key'] ?? '').toString(),
        label: (j['label'] ?? '').toString(),
        type: _fieldType(j['type']?.toString()),
        options: Option.listFrom(j['options']),
        required: j['required'] == true,
        help: j['help']?.toString(),
        showIf: ShowIf.fromJson(j['showIf']),
      );

  static List<SchemaField> listFrom(dynamic v) => v is List
      ? v
          .whereType<Map>()
          .map((e) => SchemaField.fromJson(Map<String, dynamic>.from(e)))
          .toList()
      : const [];
}

/// Should this field show, given the current values of its siblings?
///
/// Same rule as the website's `isVisible`: booleans arrive as `true`/`false`
/// or `"1"`/`"0"` depending on whether they came from the host or from a
/// saved draft, so both spellings have to count.
bool isFieldVisible(SchemaField field, Map<String, dynamic> values) {
  final cond = field.showIf;
  if (cond == null) return true;
  final current = values[cond.key];
  final want = cond.equals;
  if (want is bool) {
    final asBool = current == true || current == '1' || current == 1;
    return asBool == want;
  }
  return current == want;
}

/// A labelled set of checkbox-style options (amenities, safety, views…).
class OptionGroup {
  const OptionGroup({
    required this.key,
    required this.label,
    required this.options,
    this.showIf,
  });

  final String key;
  final String label;
  final List<Option> options;
  final ShowIf? showIf;

  factory OptionGroup.fromJson(Map<String, dynamic> j) => OptionGroup(
        key: (j['key'] ?? '').toString(),
        label: (j['label'] ?? '').toString(),
        options: Option.listFrom(j['options']),
        showIf: ShowIf.fromJson(j['showIf']),
      );

  static List<OptionGroup> listFrom(dynamic v) => v is List
      ? v
          .whereType<Map>()
          .map((e) => OptionGroup.fromJson(Map<String, dynamic>.from(e)))
          .toList()
      : const [];

  static OptionGroup single(dynamic v) => v is Map
      ? OptionGroup.fromJson(Map<String, dynamic>.from(v))
      : const OptionGroup(key: '', label: '', options: []);
}

/// The questions unique to one property category.
class CategoryFlow {
  const CategoryFlow({required this.label, required this.fields});

  final String label;
  final List<SchemaField> fields;

  factory CategoryFlow.fromJson(Map<String, dynamic> j) => CategoryFlow(
        label: (j['label'] ?? '').toString(),
        fields: SchemaField.listFrom(j['fields']),
      );
}

class PhotoRules {
  const PhotoRules({
    this.minimum = 0,
    this.recommended = 0,
    this.categories = const [],
    this.required = const [],
    this.videoMaxMinutes = 0,
    this.byCategory = const {},
  });

  final int minimum;
  final int recommended;
  final List<Option> categories;
  final List<String> required;
  final int videoMaxMinutes;

  /// Per-category overrides, when an admin set one in the flow editor —
  /// a villa can be required to show more photos than a room. Keyed by the
  /// category value stored in `property_category`. This arrived in the schema
  /// and was dropped here, so the app quoted the platform default for every
  /// category while the web enforced the category's own number.
  final Map<String, int> byCategory;

  /// The minimum for THIS category — its own rule when the admin set one,
  /// the platform default otherwise. Same resolution as the web wizard.
  int minimumFor(String? category) {
    if (category == null || category.isEmpty) return minimum;
    return byCategory[category] ?? minimum;
  }

  factory PhotoRules.fromJson(Map<String, dynamic> j) {
    final byCat = <String, int>{};
    final raw = j['byCategory'];
    if (raw is Map) {
      raw.forEach((k, v) {
        final min = (v is Map) ? _int(v['minimum']) : _int(v);
        if (min > 0) byCat[k.toString()] = min;
      });
    }
    return PhotoRules(
      minimum: _int(j['minimum']),
      recommended: _int(j['recommended']),
      categories: Option.listFrom(j['categories']),
      required: (j['required'] is List)
          ? (j['required'] as List).map((e) => e.toString()).toList()
          : const [],
      videoMaxMinutes: _int(j['videoMaxMinutes']),
      byCategory: byCat,
    );
  }
}

class PricingRules {
  const PricingRules({
    this.minBasePrice = 0,
    this.maxBasePrice = 0,
    this.maxDiscountPercent = 0,
    this.currencies = const [],
    this.cleaningFeeTypes = const [],
    this.childAgeGroups = const [],
  });

  final num minBasePrice;
  final num maxBasePrice;
  final num maxDiscountPercent;
  final List<Option> currencies;
  final List<Option> cleaningFeeTypes;
  final List<Option> childAgeGroups;

  factory PricingRules.fromJson(Map<String, dynamic> j) => PricingRules(
        minBasePrice: _num(j['minBasePrice']),
        maxBasePrice: _num(j['maxBasePrice']),
        maxDiscountPercent: _num(j['maxDiscountPercent']),
        currencies: Option.listFrom(j['currencies']),
        cleaningFeeTypes: Option.listFrom(j['cleaningFeeTypes']),
        childAgeGroups: Option.listFrom(j['childAgeGroups']),
      );
}

class BookingRules {
  const BookingRules({
    this.bookingTypes = const [],
    this.responseTimes = const [],
    this.availability = const [],
    this.earlyCheckin = const [],
    this.selfCheckinMethods = const [],
    this.payoutCycles = const [],
  });

  final List<Option> bookingTypes;
  final List<Option> responseTimes;
  final List<Option> availability;
  final List<Option> earlyCheckin;
  final List<Option> selfCheckinMethods;
  final List<Option> payoutCycles;

  factory BookingRules.fromJson(Map<String, dynamic> j) => BookingRules(
        bookingTypes: Option.listFrom(j['bookingTypes']),
        responseTimes: Option.listFrom(j['responseTimes']),
        availability: Option.listFrom(j['availability']),
        earlyCheckin: Option.listFrom(j['earlyCheckin']),
        selfCheckinMethods: Option.listFrom(j['selfCheckinMethods']),
        payoutCycles: Option.listFrom(j['payoutCycles']),
      );
}

class PropertyNameRules {
  const PropertyNameRules({
    this.minLength = 1,
    this.maxLength = 120,
    this.pattern = '',
    this.message = '',
  });

  final int minLength;
  final int maxLength;
  final String pattern;
  final String message;

  factory PropertyNameRules.fromJson(Map<String, dynamic> j) =>
      PropertyNameRules(
        minLength: _int(j['minLength'], 1),
        maxLength: _int(j['maxLength'], 120),
        pattern: (j['pattern'] ?? '').toString(),
        message: (j['message'] ?? '').toString(),
      );

  /// Null when the name is acceptable, otherwise why it is not.
  String? validate(String raw) {
    final v = raw.trim();
    if (v.isEmpty) return 'Give your property a name';
    if (v.length < minLength || v.length > maxLength) {
      return message.isEmpty
          ? 'Use $minLength–$maxLength characters.'
          : message;
    }
    if (pattern.isNotEmpty) {
      try {
        if (!RegExp(pattern).hasMatch(v)) {
          return message.isEmpty ? 'That name has characters we cannot use.' : message;
        }
      } catch (_) {
        // A pattern the server sent that Dart cannot compile is not the
        // host's problem — let the name through and let the server judge.
      }
    }
    return null;
  }
}

/// Everything the wizard needs to draw itself.
class ListingSchema {
  const ListingSchema({
    required this.hostTypes,
    required this.categories,
    required this.accommodationTypes,
    required this.accommodationRules,
    required this.statuses,
    required this.specificationFields,
    required this.categoryFlows,
    required this.propertyNameRules,
    required this.essentialAmenities,
    required this.essentialAmenityFields,
    required this.safetyGroups,
    required this.safetyFields,
    required this.outdoorAmenities,
    required this.outdoorRules,
    required this.premiumAmenities,
    required this.premiumFields,
    required this.accessibility,
    required this.petPolicyFields,
    required this.familyFields,
    required this.familyAmenities,
    required this.experiencesByCategory,
    required this.pgNearbyEssentials,
    required this.scenicViews,
    required this.nearbyGroups,
    required this.photoRules,
    required this.pricingRules,
    required this.bookingRules,
    required this.houseRuleToggles,
    required this.cancellationPolicies,
  });

  final List<Option> hostTypes;
  final List<Option> categories;
  final List<Option> accommodationTypes;

  /// e.g. `{ pg_long_stay: { hide: ["entire_property"] } }`
  final Map<String, List<String>> accommodationRules;
  final List<StatusOption> statuses;
  final List<SchemaField> specificationFields;
  final Map<String, CategoryFlow> categoryFlows;
  final PropertyNameRules propertyNameRules;

  // Step 3
  final List<OptionGroup> essentialAmenities;
  final List<SchemaField> essentialAmenityFields;
  final List<OptionGroup> safetyGroups;
  final List<SchemaField> safetyFields;
  final OptionGroup outdoorAmenities;
  final Map<String, List<String>> outdoorRules;
  final OptionGroup premiumAmenities;
  final List<SchemaField> premiumFields;
  final OptionGroup accessibility;
  final List<SchemaField> petPolicyFields;
  final List<SchemaField> familyFields;
  final OptionGroup familyAmenities;
  final Map<String, List<String>> experiencesByCategory;
  final List<String> pgNearbyEssentials;
  final OptionGroup scenicViews;
  final List<OptionGroup> nearbyGroups;
  final PhotoRules photoRules;

  // Step 4
  final PricingRules pricingRules;
  final BookingRules bookingRules;
  final List<Option> houseRuleToggles;
  final List<Option> cancellationPolicies;

  /// Accommodation types allowed for a category — the "hide" rules applied.
  List<Option> accommodationFor(String? category) {
    final hidden = accommodationRules[category] ?? const [];
    return accommodationTypes
        .where((a) => !hidden.contains(a.value))
        .toList();
  }

  /// Outdoor amenities allowed for a category.
  List<Option> outdoorFor(String? category) {
    final hidden = outdoorRules[category] ?? const [];
    return outdoorAmenities.options
        .where((o) => !hidden.contains(o.value))
        .toList();
  }

  factory ListingSchema.fromJson(Map<String, dynamic> j) => ListingSchema(
        hostTypes: Option.listFrom(j['hostTypes']),
        categories: Option.listFrom(j['categories']),
        accommodationTypes: Option.listFrom(j['accommodationTypes']),
        accommodationRules: _hideRules(j['accommodationRules']),
        statuses: (j['statuses'] is List)
            ? (j['statuses'] as List)
                .whereType<Map>()
                .map((e) => StatusOption.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : const [],
        specificationFields: SchemaField.listFrom(j['specificationFields']),
        categoryFlows: (j['categoryFlows'] is Map)
            ? (j['categoryFlows'] as Map).map((k, v) => MapEntry(
                k.toString(),
                CategoryFlow.fromJson(Map<String, dynamic>.from(v as Map))))
            : const {},
        propertyNameRules: PropertyNameRules.fromJson(
            Map<String, dynamic>.from(j['propertyNameRules'] ?? const {})),
        essentialAmenities: OptionGroup.listFrom(j['essentialAmenities']),
        essentialAmenityFields:
            SchemaField.listFrom(j['essentialAmenityFields']),
        safetyGroups: OptionGroup.listFrom(j['safetyGroups']),
        safetyFields: SchemaField.listFrom(j['safetyFields']),
        outdoorAmenities: OptionGroup.single(j['outdoorAmenities']),
        outdoorRules: _hideRules(j['outdoorRules']),
        premiumAmenities: OptionGroup.single(j['premiumAmenities']),
        premiumFields: SchemaField.listFrom(j['premiumFields']),
        accessibility: OptionGroup.single(j['accessibility']),
        petPolicyFields: SchemaField.listFrom(j['petPolicyFields']),
        familyFields: SchemaField.listFrom(j['familyFields']),
        familyAmenities: OptionGroup.single(j['familyAmenities']),
        experiencesByCategory: _stringLists(j['experiencesByCategory']),
        pgNearbyEssentials: _strings(j['pgNearbyEssentials']),
        scenicViews: OptionGroup.single(j['scenicViews']),
        nearbyGroups: OptionGroup.listFrom(j['nearbyGroups']),
        photoRules:
            PhotoRules.fromJson(Map<String, dynamic>.from(j['photoRules'] ?? const {})),
        pricingRules: PricingRules.fromJson(
            Map<String, dynamic>.from(j['pricingRules'] ?? const {})),
        bookingRules: BookingRules.fromJson(
            Map<String, dynamic>.from(j['bookingRules'] ?? const {})),
        houseRuleToggles: Option.listFrom(j['houseRuleToggles']),
        cancellationPolicies: Option.listFrom(j['cancellationPolicies']),
      );
}

// ── helpers ─────────────────────────────────────────────────────────────────

int _int(dynamic v, [int fallback = 0]) {
  if (v is num) return v.toInt();
  return int.tryParse('${v ?? ''}') ?? fallback;
}

num _num(dynamic v, [num fallback = 0]) {
  if (v is num) return v;
  return num.tryParse('${v ?? ''}') ?? fallback;
}

List<String> _strings(dynamic v) =>
    v is List ? v.map((e) => e.toString()).toList() : const [];

Map<String, List<String>> _stringLists(dynamic v) => v is Map
    ? v.map((k, val) => MapEntry(k.toString(), _strings(val)))
    : const {};

/// `{ key: { hide: [...] } }` → `{ key: [...] }`
Map<String, List<String>> _hideRules(dynamic v) => v is Map
    ? v.map((k, val) => MapEntry(
        k.toString(), val is Map ? _strings(val['hide']) : const <String>[]))
    : const {};
