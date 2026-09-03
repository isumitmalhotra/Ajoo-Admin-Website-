// State for the 5-step listing wizard.
//
// Holds the same buckets the website's ListProperty page holds — foundation,
// specification + category attributes, amenities/experiences/views/nearby,
// pricing/booking/rules, verification + declarations — and saves each step to
// its own endpoint as the host leaves it.
//
// The step boundaries matter: /listing/step1 is what CREATES the draft and
// returns the property_id every later call is keyed on, so nothing after step
// 1 can run until it has one. That is also what makes the wizard resumable —
// a listing exists from the first Continue, and closing the app costs one
// step rather than the whole form.
import 'dart:io';


import 'package:get/get.dart';
import 'package:rent_home/models/listing_schema.dart';
import 'package:rent_home/service/listing_service.dart';
import 'package:rent_home/utils/money.dart';

/// The seven declarations. All must be true before a listing can be submitted.
const List<MapEntry<String, String>> kListingDeclarations = [
  MapEntry('declaration_accurate',
      "The information I've provided is accurate"),
  MapEntry('declaration_documents_genuine', 'My documents are genuine'),
  MapEntry('declaration_terms', "I accept Aajoo's Terms"),
  MapEntry('declaration_host_agreement', 'I accept the Host Agreement'),
  MapEntry('declaration_cancellation', 'I agree to the cancellation policy'),
  MapEntry('declaration_commission', 'I agree to the commission policy'),
  MapEntry('declaration_verification', 'I understand the verification process'),
];

const List<String> kListingSteps = [
  'Property Foundation',
  'Property Details',
  'Amenities & Location',
  'Pricing & Booking',
  'Verify & Publish',
];

const List<String> kMonths = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

class ListingWizardController extends GetxController {
  ListingWizardController({int? propertyId}) : _initialPropertyId = propertyId;

  final int? _initialPropertyId;
  final ListingService _service = ListingService();

  // ── Lifecycle state ───────────────────────────────────────────────────────
  final Rx<ListingSchema?> schema = Rx<ListingSchema?>(null);
  final RxBool loading = true.obs;
  final RxBool busy = false.obs;
  final RxString loadError = ''.obs;
  final RxString error = ''.obs;
  final RxInt step = 0.obs;
  final RxnInt propertyId = RxnInt();

  /// Per-field messages for the step on screen.
  final RxMap<String, String> fieldErrors = <String, String>{}.obs;

  // ── Step 1 — foundation ───────────────────────────────────────────────────
  final RxMap<String, dynamic> f = <String, dynamic>{
    'host_type': 'owner',
    'is_owner': true,
    'country': 'India',
    'property_status': 'ready',
    'show_exact_location': true,
  }.obs;
  final RxList<String> seasonalMonths = <String>[].obs;

  // ── Step 2 — specification + category attributes ──────────────────────────
  final RxMap<String, dynamic> spec = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> attrs = <String, dynamic>{}.obs;

  // ── Step 3 — amenities, experiences, views, nearby, photos ────────────────
  final RxMap<String, List<String>> amenities =
      <String, List<String>>{}.obs;
  final RxList<String> experiences = <String>[].obs;
  final RxList<String> views = <String>[].obs;
  final RxMap<String, Map<String, dynamic>> nearby =
      <String, Map<String, dynamic>>{}.obs;
  final RxMap<String, dynamic> details = <String, dynamic>{}.obs;
  final RxList<Map<String, dynamic>> media = <Map<String, dynamic>>[].obs;
  final RxMap<String, dynamic> photoReadiness = <String, dynamic>{}.obs;
  final RxBool uploading = false.obs;

  // ── Step 4 — pricing & booking ────────────────────────────────────────────
  final RxMap<String, dynamic> p4 = <String, dynamic>{
    'currency': 'INR',
    'negotiation_enabled': true,
  }.obs;
  final RxList<Map<String, dynamic>> ratePeriods =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> cancellationTiers =
      <Map<String, dynamic>>[].obs;
  final RxMap<String, bool> houseRules = <String, bool>{}.obs;

  // ── Step 5 — verification & publish ───────────────────────────────────────
  final RxMap<String, dynamic> p5 = <String, dynamic>{}.obs;
  final RxMap<String, bool> declarations = <String, bool>{}.obs;
  final RxMap<String, dynamic> readiness = <String, dynamic>{}.obs;

  bool get isLastStep => step.value == kListingSteps.length - 1;

  /// Whether this listing is ALREADY approved and on the site.
  ///
  /// Editing a live listing is an update, not an application: it keeps its
  /// verification tier, stays live, and the admin is told to take a look
  /// rather than asked to approve it from scratch. The wording has to match,
  /// or a host correcting a typo believes they have taken their own property
  /// off the market.
  bool get isLive {
    final p = readiness['published'];
    return p is Map && p['approved'] == true;
  }

  /// The category flow for the chosen category, if the schema defines one.
  CategoryFlow? get flow {
    final cat = f['property_category']?.toString();
    if (cat == null) return null;
    return schema.value?.categoryFlows[cat];
  }

  /// Every declaration ticked?
  bool get allDeclared =>
      kListingDeclarations.every((d) => declarations[d.key] == true);

  @override
  void onInit() {
    super.onInit();

    // Readiness follows the step, not the act of pressing Continue.
    //
    // It used to be fetched in one place only: the handler that ADVANCES a
    // step, when the new step happened to be the last one. Resume a draft from
    // "unfinished listings" and the wizard opens straight on step 5 without
    // that handler ever running, so `readiness` stayed empty — and an empty
    // readiness renders as no completion percentage, no list of what is
    // missing, and an identity section asking a already-verified host to
    // upload their documents again.
    //
    // The website has always keyed this on [step, propertyId]; this is the
    // same rule, so arriving at the step by any route loads it.
    everAll([step, propertyId], (_) {
      if (step.value == 4 && propertyId.value != null) refreshReadiness();
    });

    _load();
  }

  Future<void> _load() async {
    loading.value = true;
    loadError.value = '';
    try {
      schema.value = await _service.getSchema();
      if (_initialPropertyId != null) {
        propertyId.value = _initialPropertyId;
        await _hydrateDraft(_initialPropertyId);
      }
    } catch (e) {
      loadError.value = e is ListingException ? e.message : e.toString();
    } finally {
      loading.value = false;
    }
  }

  Future<void> retryLoad() => _load();

  /// Fill the form from a saved draft, so editing picks up where it left off.
  Future<void> _hydrateDraft(int id) async {
    final d = await _service.getDraft(id);

    // The draft comes back as DATABASE ROWS, not as the payload that made
    // them: /listing/step1 is posted `city`, and /listing/draft returns
    // `pl_city`. Merging the rows straight in therefore filled the form with
    // keys nothing reads, and a resumed draft opened blank with all its
    // answers sitting one prefix away. Strip the table prefix on the way in.
    //
    // Prefixes as the server names them: pf_ foundation, pl_ location,
    // pc_ capacity, ps_ specification, pm_ manager, pp_ pricing, pb_ booking,
    // ph_ house rules, pn_ negotiation, pst_ settlement.
    void merge(RxMap<String, dynamic> target, dynamic src, [String? prefix]) {
      if (src is! Map) return;
      src.forEach((key, value) {
        var k = key.toString();
        if (prefix != null && k.startsWith(prefix)) {
          k = k.substring(prefix.length);
        }
        // Row bookkeeping is not form data.
        if (k.endsWith('_id') && k != 'property_id') return;
        if (k == 'created_at' || k == 'updated_at' || k == 'step_completed') {
          return;
        }
        if (value != null) target[k] = value;
      });
    }

    merge(f, d['foundation'], 'pf_');
    merge(f, d['manager'], 'pm_');
    merge(f, d['location'], 'pl_');
    merge(f, d['capacity'], 'pc_');
    merge(spec, d['specification'], 'ps_');
    merge(attrs, d['attributes']);
    merge(details, d['details']);
    // 'ppr_', not 'pp_'. The pricing columns are ppr_base_price, ppr_weekly_
    // price and so on, so a 'pp_' prefix matched nothing and every key stayed
    // as ppr_* — meaning Step 4 opened EMPTY when editing a listing that
    // already had prices, and a host re-typed the lot. Same fault below for
    // booking rules, whose columns are pbr_*.
    merge(p4, d['pricing'], 'ppr_');
    merge(p4, d['negotiation'], 'pn_');
    // The two negotiation tiers live on the flat property row, not in the
    // modular negotiation table, and the form keys are the ones the save
    // endpoint reads — so they are mapped explicitly rather than by prefix.
    final tierRow = d['property'];
    if (tierRow is Map) {
      if (tierRow['property_mini_price'] != null) {
        p4['negotiation_minimum_price'] = tierRow['property_mini_price'];
      }
      if (tierRow['property_ideal_price'] != null) {
        p4['negotiation_ideal_price'] = tierRow['property_ideal_price'];
      }
    }
    // The weekly and monthly tiers come off the pricing row under the names
    // the save endpoint reads, which are not the column names.
    const tierKeys = {
      'weekly_min': 'weekly_minimum_price',
      'weekly_ideal': 'weekly_ideal_price',
      'monthly_min': 'monthly_minimum_price',
      'monthly_ideal': 'monthly_ideal_price',
      'advance_discount': 'advance_booking_discount',
    };
    tierKeys.forEach((column, formKey) {
      final v = p4[column];
      if (v != null) p4[formKey] = v;
    });
    merge(p4, d['bookingRules'], 'pbr_');
    merge(p4, d['settlement'], 'pst_');
    merge(p5, d['houseRules'], 'ph_');

    // Booleans come back as MySQL 1/0; the pill rows compare against true.
    for (final key in const [
      'is_owner',
      'is_luxury',
      'show_exact_location',
      'manager_authorization_available',
    ]) {
      if (f.containsKey(key)) f[key] = f[key] == 1 || f[key] == true;
    }

    // Seasonal months are stored as a JSON string or a list.
    final months = f.remove('seasonal_months');
    if (months is List) {
      seasonalMonths.assignAll(months.map((e) => e.toString()));
    }

    final prop = d['property'];
    if (prop is Map) {
      f['property_name'] = prop['property_name'];
      f['is_luxury'] = prop['is_luxury'] == 1 || prop['is_luxury'] == true;
      // merge() above already pulls pf_description in as `description`. This is
      // the fallback for listings that predate that column — seeded rows, and
      // anything the admin property form wrote straight to property_desc —
      // so editing an older listing shows its real text instead of an empty
      // box that then fails validation.
      if ((f['description'] ?? '').toString().trim().isEmpty &&
          (prop['property_desc'] ?? '').toString().trim().isNotEmpty) {
        f['description'] = prop['property_desc'];
      }
    }
    if (d['amenities'] is Map) {
      amenities.assignAll((d['amenities'] as Map).map((k, v) => MapEntry(
          k.toString(),
          v is List ? v.map((e) => e.toString()).toList() : <String>[])));
    }
    if (d['experiences'] is List) {
      experiences.assignAll(
          (d['experiences'] as List).map((e) => e.toString()));
    }
    if (d['views'] is List) {
      views.assignAll((d['views'] as List).map((e) => e.toString()));
    }
    if (d['nearby'] is Map) {
      nearby.assignAll((d['nearby'] as Map).map((k, v) => MapEntry(
          k.toString(),
          v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{})));
    }
    if (d['media'] is List) {
      media.assignAll((d['media'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e)));
    }
    if (d['ratePeriods'] is List) {
      ratePeriods.assignAll((d['ratePeriods'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e)));
    }
    if (d['cancellationTiers'] is List) {
      cancellationTiers.assignAll((d['cancellationTiers'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e)));
    }
    // Resume on the step after the last one completed, capped at the end.
    final done = d['stepCompleted'];
    if (done is num) {
      step.value = done.toInt().clamp(0, kListingSteps.length - 1);
    }
  }

  // ── Value setters ─────────────────────────────────────────────────────────

  void setF(String key, dynamic value) {
    f[key] = value;
    fieldErrors.remove(key);
    // Changing the category invalidates the answers that belonged to the old
    // one — leaving them would post a villa's pool questions on a tree house.
    if (key == 'property_category') {
      attrs.clear();
      experiences.clear();
      final allowed =
          schema.value?.accommodationFor(value?.toString()).map((o) => o.value);
      if (allowed != null && !allowed.contains(f['accommodation_type'])) {
        f.remove('accommodation_type');
      }
    }
  }

  void setSpec(String key, dynamic value) => spec[key] = value;
  void setAttr(String key, dynamic value) => attrs[key] = value;
  void setDetail(String key, dynamic value) => details[key] = value;
  void setP4(String key, dynamic value) {
    p4[key] = value;
    fieldErrors.remove(key);
  }

  void setP5(String key, dynamic value) {
    p5[key] = value;
    fieldErrors.remove(key);
  }

  void toggleAmenity(String group, String value) {
    final list = [...(amenities[group] ?? const <String>[])];
    list.contains(value) ? list.remove(value) : list.add(value);
    amenities[group] = list;
    amenities.refresh();
  }

  void toggleIn(RxList<String> list, String value) {
    list.contains(value) ? list.remove(value) : list.add(value);
  }

  void setNearby(String group, String place, String distance) {
    final g = {...(nearby[group] ?? const <String, dynamic>{})};
    if (distance.trim().isEmpty) {
      g.remove(place);
    } else {
      g[place] = distance;
    }
    nearby[group] = g;
    nearby.refresh();
  }

  void toggleMonth(String m) => toggleIn(seasonalMonths, m);

  void toggleHouseRule(String key, bool on) {
    houseRules[key] = on;
    houseRules.refresh();
  }

  void toggleDeclaration(String key, bool on) {
    declarations[key] = on;
    declarations.refresh();
  }

  // ── Validation ────────────────────────────────────────────────────────────

  static final RegExp _mobile = RegExp(r'^[6-9]\d{9}$');
  static final RegExp _pin = RegExp(r'^\d{6}$');
  static final RegExp _email =
      RegExp(r'^[^@\s]+@[^@\s]+\.[A-Za-z]{2,}$');
  static final RegExp _ifsc = RegExp(r'^[A-Za-z]{4}0[A-Za-z0-9]{6}$');
  static final RegExp _gstin = RegExp(
      r'^\d{2}[A-Za-z]{5}\d{4}[A-Za-z]{1}[A-Za-z\d]{1}[Zz]{1}[A-Za-z\d]{1}$');

  String _s(dynamic v) => (v ?? '').toString().trim();

  /// Same rules the website enforces before it will post step 1.
  Map<String, String> validateStep1() {
    final errs = <String, String>{};
    final name = _s(f['property_name']);
    final rules = schema.value?.propertyNameRules;
    if (name.isEmpty) {
      errs['property_name'] = 'Give the property a name';
    } else if (rules != null) {
      // The SCHEMA's rule, not a hardcoded 3. The server requires 5 and the
      // hint under the field says "Use 5–80 characters", so a 4-character
      // name passed this check, contradicted the hint on screen, and was then
      // refused by the server.
      final problem = rules.validate(name);
      if (problem != null) errs['property_name'] = problem;
    } else if (name.length < 5) {
      // No schema in hand (offline draft): fall back to the server's minimum
      // rather than something more permissive than it.
      errs['property_name'] = 'Give the property a name — at least 5 characters';
    }
    final desc = _s(f['description']);
    if (desc.isEmpty) {
      errs['description'] =
          'Describe the place — this is what guests read first';
    } else if (desc.length < 40) {
      errs['description'] =
          'Say a little more — at least 40 characters (${desc.length} so far)';
    }
    if (_s(f['property_category']).isEmpty) {
      errs['property_category'] = 'Choose a property category';
    } else if (_s(f['accommodation_type']).isEmpty) {
      errs['accommodation_type'] = 'Choose what guests are booking';
    }
    if (f['host_type'] == 'manager') {
      if (_s(f['manager_full_name']).isEmpty) {
        errs['manager_full_name'] = "The manager's name is required";
      }
      if (!_mobile.hasMatch(_s(f['manager_mobile']))) {
        errs['manager_mobile'] = 'Enter a valid 10-digit mobile number';
      }
      final em = _s(f['manager_email']);
      if (em.isNotEmpty && !_email.hasMatch(em)) {
        errs['manager_email'] = "This email doesn't look right";
      }
      // "Authorization = No -> Cannot Continue". The server has always
      // rejected this; neither client did, so the host waited for a round
      // trip to be told.
      if (f['manager_authorization_available'] != true) {
        errs['manager_authorization_available'] =
            "You need the owner's written authorisation before this listing can continue";
      }
    }
    if (_s(f['state']).isEmpty) errs['state'] = 'State is required';
    if (_s(f['city']).isEmpty) errs['city'] = 'City is required';
    if (!_pin.hasMatch(_s(f['pincode']))) {
      errs['pincode'] = 'Enter the 6-digit PIN code';
    }
    // "wd23fd" used to sail through as a street address, because the only rule
    // was "not empty". A real address is several words and contains letters.
    final addr = _s(f['street_address']);
    if (addr.isEmpty) {
      errs['street_address'] = 'Street address is required';
    } else if (addr.length < 8 ||
        !RegExp(r'[A-Za-z]{3}').hasMatch(addr) ||
        !addr.contains(RegExp(r'\s'))) {
      errs['street_address'] =
          'Enter the full address — house/flat, street and area';
    }

    // ── Capacity has to add up (W5 · LP-P0-05/06, LP-27) ────────────────────
    // Mirrors utils/listingCapacity on the server, which stays the authority.
    // Here so the number that is wrong is marked, rather than the host being
    // told about whichever problem the server reached first.
    int? count(String k) {
      final raw = _s(f[k]);
      if (raw.isEmpty) return null;
      return int.tryParse(raw);
    }

    final adults = count('max_adults');
    final children = count('max_children');
    final bedrooms = count('bedrooms');
    final beds = count('beds');
    // DERIVED, not entered — same as the website since 2026-08-31. The host
    // used to type adults, children, infants AND a total, and the form then
    // policed the four against each other; every one of those errors was the
    // form asking the host to do arithmetic it could do itself. Infants are
    // excluded, the rule the guest selector already uses: a cot is not a bed.
    final total = (adults ?? 0) + (children ?? 0);

    for (final k in const [
      'max_adults', 'max_children',
      'max_infants', 'bedrooms', 'beds', 'bathrooms',
    ]) {
      final v = count(k);
      if (v != null && v < 0) errs[k] = "This can't be negative";
    }
    if (total < 1) {
      errs['max_adults'] = 'A listing has to sleep at least one guest';
    }
    if (bedrooms != null && beds != null && bedrooms > 0 && beds < bedrooms) {
      errs['beds'] = '$bedrooms bedrooms need at least $bedrooms beds between them';
    }
    if (beds != null && beds > 0 && total > beds * 4) {
      // Reported against BEDS: the host can no longer lower a total they do
      // not type, so the actionable field is the one they can change.
      errs['beds'] =
          "$total guests in $beds bed${beds == 1 ? '' : 's'} won't work — "
          'add beds, or lower the guest counts';
    }

    // A seasonal property has to say which months it is open, or the calendar
    // has no idea when it can be booked (W5 · LP-P0-07).
    //
    // Read [seasonalMonths], NOT `f['seasonal_months']`. The month pills write
    // to the list; `f` never receives that key — loading a draft deliberately
    // moves it OUT of `f` (see hydrate), and it is only folded into the
    // payload at submit. So this check used to read a key that was guaranteed
    // absent and rejected every seasonal property however many months were
    // lit up on screen, which is no listing at all rather than a wrong one.
    if (_s(f['property_status']) == 'seasonal') {
      final named = seasonalMonths.where((m) => _s(m).isNotEmpty).length;
      if (named == 0) {
        errs['seasonal_months'] = 'Choose the months this property is open';
      }
    }

    return errs;
  }

  /// Step 4 — the nine-value pricing grid, every value required.
  ///
  /// Min / Ideal / Max across night, week and month. The server enforces
  /// exactly this in utils/pricingGrid; this copy exists so the host is told
  /// which field is wrong beside the field, rather than by one message about
  /// whichever problem the server reached first.
  Map<String, String> validateStep4() {
    final errs = <String, String>{};
    final rules = schema.value?.pricingRules;

    num? val(String k) => num.tryParse(_s(p4[k]));
    bool set(String k) => (val(k) ?? 0) > 0;

    final price = val('base_price');
    if (price == null || price <= 0) {
      errs['base_price'] = 'Enter the nightly price';
    } else if (rules != null &&
        (price < rules.minBasePrice || price > rules.maxBasePrice)) {
      errs['base_price'] =
          // Grouped, like the website's own message — it renders the ceiling
          // with toLocaleString("en-IN"), so printing the raw number here made
          // the same rule read differently on the two platforms:
          // "₹1000000" against "₹10,00,000".
          'Price must be between ${rupees(rules.minBasePrice)} and '
          '${rupees(rules.maxBasePrice)}';
    }

    const periods = [
      ['base_price', 'negotiation_minimum_price', 'negotiation_ideal_price', 'nightly', '0'],
      ['weekly_price', 'weekly_minimum_price', 'weekly_ideal_price', 'weekly', '7'],
      ['monthly_price', 'monthly_minimum_price', 'monthly_ideal_price', 'monthly', '28'],
    ];
    for (final period in periods) {
      final priceKey = period[0];
      final minKey = period[1];
      final idealKey = period[2];
      final label = period[3];
      final nights = int.parse(period[4]);

      if (!set(priceKey)) errs[priceKey] = 'Enter the $label price';
      if (!set(minKey)) errs[minKey] = "Required — the least you'd accept";
      if (!set(idealKey)) {
        errs[idealKey] = 'Required — offers at or above this are accepted for you';
      }
      if (set(priceKey) && set(minKey) && val(minKey)! > val(priceKey)!) {
        errs[minKey] = "Can't be above your $label price";
      }
      if (set(priceKey) && set(idealKey) && val(idealKey)! > val(priceKey)!) {
        errs[idealKey] = "Can't be above your $label price";
      }
      if (set(minKey) && set(idealKey) && val(idealKey)! < val(minKey)!) {
        errs[idealKey] = "Can't be below your minimum";
      }
      // A package must beat buying its nights one by one, or it is not one.
      if (nights > 0 &&
          set(priceKey) &&
          price != null &&
          val(priceKey)! > price * nights) {
        errs[priceKey] =
            'More than $nights nights at ${rupees(price)} — set it below '
            '${rupees(price * nights)}';
      }
    }
    return errs;
  }

  /// Formats are only enforced when the host filled the field — step 5 can be
  /// saved partially — but a filled field must hold a real value.
  Map<String, String> validateStep5() {
    final errs = <String, String>{};
    final phone = _s(p5['emergency_phone']);
    if (phone.isNotEmpty && !_mobile.hasMatch(phone)) {
      errs['emergency_phone'] = 'Enter a valid 10-digit mobile number';
    }
    final ifsc = _s(p5['ifsc']);
    if (ifsc.isNotEmpty && !_ifsc.hasMatch(ifsc)) {
      errs['ifsc'] = 'IFSC looks wrong — 4 letters, 0, then 6 characters';
    }
    final acct = _s(p5['account_number']).replaceAll(RegExp(r'\s'), '');
    if (acct.isNotEmpty && !RegExp(r'^\d{9,18}$').hasMatch(acct)) {
      errs['account_number'] = 'Account numbers are 9–18 digits';
    }
    final gst = _s(p5['gst_number']);
    if (gst.isNotEmpty && !_gstin.hasMatch(gst)) {
      errs['gst_number'] = "This isn't a valid 15-character GSTIN";
    }
    return errs;
  }

  bool _fail(Map<String, String> errs) {
    fieldErrors.assignAll(errs);
    if (errs.isEmpty) return false;
    error.value = errs.values.first;
    return true;
  }

  // ── Saving ────────────────────────────────────────────────────────────────

  /// Sleeping capacity, worked out rather than asked for.
  ///
  /// Adults + children; infants excluded — a cot is not a bed, and counting one
  /// would hide places that actually fit the party. One definition, used by the
  /// read-only field on the form and by the payload, so the two cannot drift.
  int get derivedTotalGuests {
    int n(String k) => int.tryParse('${f[k] ?? ''}'.trim()) ?? 0;
    return n('max_adults') + n('max_children');
  }

  /// Save the current step and advance. Returns false if it did not save.
  Future<bool> saveAndContinue() async {
    error.value = '';
    switch (step.value) {
      case 0:
        if (_fail(validateStep1())) return false;
        return _run(() async {
          final payload = <String, dynamic>{
            ...f,
            // total_guests is DERIVED from the two counts above it and is no
            // longer a field the host types. Computed into the payload rather
            // than spread from `f`, which would send whatever the draft last
            // loaded — or nothing on a new listing — and leave the capacity
            // guests search on stale.
            'total_guests': derivedTotalGuests,
            if (propertyId.value != null) 'property_id': propertyId.value,
            if (seasonalMonths.isNotEmpty)
              'seasonal_months': seasonalMonths.toList(),
          };
          propertyId.value = await _service.saveStep1(payload);
        });
      case 1:
        return _run(() => _service.saveStep2({
              'property_id': propertyId.value,
              ...spec,
              'attributes': attrs,
            }));
      case 2:
        return _run(() async {
          final res = await _service.saveStep3({
            'property_id': propertyId.value,
            'amenities': amenities,
            'experiences': experiences.toList(),
            'views': views.toList(),
            'nearby': nearby,
            'details': details,
          });
          if (res['photoReadiness'] is Map) {
            photoReadiness
                .assignAll(Map<String, dynamic>.from(res['photoReadiness']));
          }
        });
      case 3:
        if (_fail(validateStep4())) return false;
        return _run(() => _service.saveStep4({
              'property_id': propertyId.value,
              ...p4,
              ...houseRules,
              if (ratePeriods.isNotEmpty)
                'rate_periods': ratePeriods.toList(),
              if (p4['cancellation_policy'] == 'custom' &&
                  cancellationTiers.isNotEmpty)
                'cancellation_tiers': cancellationTiers.toList(),
            }));
      default:
        return false;
    }
  }

  /// Save step 5's fields without submitting — the host can come back.
  Future<bool> saveStep5() async {
    error.value = '';
    if (_fail(validateStep5())) return false;
    return _run(() => _service.saveStep5({
          'property_id': propertyId.value,
          ...p5,
        }));
  }

  Future<bool> _run(Future<void> Function() body) async {
    busy.value = true;
    try {
      await body();
      fieldErrors.clear();
      if (step.value < kListingSteps.length - 1) step.value++;
      return true;
    } catch (e) {
      error.value = e is ListingException
          ? e.message
          : "Couldn't save. Please check the fields.";
      return false;
    } finally {
      busy.value = false;
    }
  }

  /// Score the listing so step 5 can show what is still missing.
  Future<void> refreshReadiness() async {
    final id = propertyId.value;
    if (id == null) return;
    try {
      readiness.assignAll(await _service.getReadiness(id));
    } catch (_) {
      // A missing score is not worth an error banner over a form that works.
    }
  }

  /// Send for review.
  Future<String?> submitListing() async {
    final id = propertyId.value;
    if (id == null) return 'Finish the earlier steps first.';
    if (!allDeclared) return 'Accept all the declarations to submit.';
    if (_fail(validateStep5())) return error.value;
    busy.value = true;
    try {
      // Save the verification fields first, so a submit never races the
      // values the host just typed on this same screen.
      await _service.saveStep5({'property_id': id, ...p5});
      await _service.submit({
        'property_id': id,
        for (final d in kListingDeclarations) d.key: true,
      });
      return null;
    } catch (e) {
      final msg = e is ListingException ? e.message : 'Could not submit.';
      error.value = msg;
      return msg;
    } finally {
      busy.value = false;
    }
  }

  // ── Photos ────────────────────────────────────────────────────────────────

  Future<String?> uploadPhotos(
    List<File> files,
    String category, {
    List<String> alts = const [],
  }) async {
    final id = propertyId.value;
    if (id == null) return 'Finish step 1 first.';
    uploading.value = true;
    try {
      final res = await _service.uploadMedia(
        propertyId: id,
        files: files,
        categories: List.filled(files.length, category),
        alts: alts,
      );
      if (res['media'] is List) {
        media.assignAll((res['media'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e)));
      }
      if (res['photoReadiness'] is Map) {
        photoReadiness
            .assignAll(Map<String, dynamic>.from(res['photoReadiness']));
      }
      return null;
    } catch (e) {
      return e is ListingException ? e.message : 'Upload failed.';
    } finally {
      uploading.value = false;
    }
  }

  Future<void> removePhoto(int mediaId) async {
    try {
      final res = await _service.deleteMedia(mediaId);
      if (res['media'] is List) {
        media.assignAll((res['media'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e)));
      }
      if (res['photoReadiness'] is Map) {
        photoReadiness
            .assignAll(Map<String, dynamic>.from(res['photoReadiness']));
      }
    } catch (e) {
      error.value = e is ListingException ? e.message : 'Could not remove it.';
    }
  }

  Future<String?> uploadDocument(File file, String key) async {
    final id = propertyId.value;
    if (id == null) return 'Finish step 1 first.';
    busy.value = true;
    try {
      final url = await _service.uploadDocument(propertyId: id, file: file);
      if (url == null) return 'The document did not upload.';
      setP5(key, url);
      return null;
    } catch (e) {
      return e is ListingException ? e.message : 'Upload failed.';
    } finally {
      busy.value = false;
    }
  }

  void back() {
    if (step.value > 0) {
      step.value--;
      error.value = '';
      fieldErrors.clear();
    }
  }
}
