import 'package:flutter/material.dart';

// Icons for the listing wizard's pickers.
//
// The Dart half of `src/redesign/lib/listingIcons.ts` on the website. Both
// platforms render the same schema, so a chip that carries a picture on one
// and not the other is the sort of drift the parity rule exists to stop —
// and this app was the worse half: it drew NO icon on any wizard chip, not
// on the amenities either.
//
// Client, 2026-09-13, photographing the Homestay block: "give some icon for
// looks attached and see all identifi for categories releated to".
//
// ── THREE LOOKUPS, THE SAME THREE AS THE WEBSITE ───────────────────────────
//
//   [iconForAmenity]       free-text amenity labels, matched by KEYWORD,
//                          always returns something
//   [iconForSchemaOption]  the category-specific questions, matched EXACTLY,
//                          allowed to return null
//   (step-1 pickers)       not here — the app draws those itself
//
// The split is not tidiness. Amenity labels grow whenever somebody edits
// `config/listingSchema.js` and nobody comes back here, so those resolve by
// scanning for a word: a new "Coffee Machine" gets a cup without an edit.
// The category questions cannot work that way — their labels are short,
// generic words that mean something only under their own heading. "Private",
// "Shared", "Open", "Single", "Family", "Luxury", "None": a keyword scan over
// those would fire on the wrong thing constantly.
//
// Material icons rather than Lucide. The website resolves Lucide names
// through a generated map; Flutter has its own set, so what is shared is the
// DECISION about which question gets a picture, not the artwork — which keys
// are present, and which two are deliberately absent. Keep those in step with
// the TypeScript file; test/wizard_chips_carry_icons_test.dart pins this
// side and tests/wizardChipsCarryIcons.test.mjs pins the website's.

/// The question's own icon, used for every one of its options.
///
/// Two fields are deliberately absent and must stay absent:
/// `host_interaction_level` (High / Medium / Low) and `height` (three
/// measurements). A picture repeated down a scale is decoration standing
/// where meaning should be.
///
/// Because the fallback is per FIELD and not per option, a question draws
/// icons on all of its chips or on none — a row never ends up with one chip
/// mysteriously shorter than its neighbours.
const Map<String, IconData> kFieldIcons = <String, IconData>{
  // What kind of thing is it
  'homestay_type': Icons.home_outlined,
  'villa_type': Icons.villa_outlined,
  'apartment_type': Icons.apartment_outlined,
  'cottage_style': Icons.home_outlined,
  'heritage_type': Icons.account_balance_outlined,
  'camp_type': Icons.cabin_outlined,
  'glamping_unit': Icons.holiday_village_outlined,
  'farm_type': Icons.agriculture_outlined,
  'resort_type': Icons.beach_access_outlined,
  'society_type': Icons.apartment_outlined,
  'room_type': Icons.bed_outlined,
  'furnishing': Icons.weekend_outlined,

  // What can you do there
  'local_experience': Icons.auto_awesome_outlined,
  'adventure_activities': Icons.terrain_outlined,
  'farm_activities': Icons.agriculture_outlined,
  'animals': Icons.pets_outlined,
  'orchard': Icons.park_outlined,
  'pool_type': Icons.pool_outlined,
  'meals': Icons.restaurant_outlined,

  // Who and how
  'staff': Icons.groups_outlined,
  'shared_spaces': Icons.groups_outlined,
  'target_audience': Icons.groups_outlined,
  'gender': Icons.groups_outlined,

  // Practicalities
  'parking': Icons.local_parking_outlined,
  'minimum_stay': Icons.calendar_month_outlined,
  'access': Icons.stairs_outlined,
};

/// Keyed `"<field>.<value>"`, so a generic word is never ambiguous:
/// `pool_type` has `private` and `shared`, and so does half the schema.
const Map<String, IconData> kOptionIcons = <String, IconData>{
  'local_experience.home_cooked_food': Icons.restaurant_menu_outlined,
  'local_experience.traditional_food': Icons.restaurant_outlined,
  'local_experience.bonfire': Icons.local_fire_department_outlined,
  'local_experience.village_walk': Icons.explore_outlined,
  'local_experience.local_guide': Icons.how_to_reg_outlined,
  'local_experience.local_culture': Icons.account_balance_outlined,

  'staff.chef': Icons.restaurant_menu_outlined,
  'staff.driver': Icons.directions_car_outlined,
  'staff.security_guard': Icons.security_outlined,
  'staff.housekeeping': Icons.auto_awesome_outlined,
  'staff.caretaker': Icons.how_to_reg_outlined,

  'adventure_activities.river_rafting': Icons.pool_outlined,
  'adventure_activities.trekking': Icons.terrain_outlined,
  'adventure_activities.rock_climbing': Icons.terrain_outlined,
  'adventure_activities.atv': Icons.directions_car_outlined,

  'farm_activities.fishing': Icons.pool_outlined,
  'farm_activities.horse_riding': Icons.pets_outlined,
  'farm_activities.village_tour': Icons.explore_outlined,

  'shared_spaces.shared_kitchen': Icons.restaurant_outlined,
  'shared_spaces.shared_living_room': Icons.weekend_outlined,
  'shared_spaces.shared_entrance': Icons.sensor_door_outlined,

  'meals.no_meals': Icons.close_rounded,
  'orchard.none': Icons.close_rounded,
  'parking.none': Icons.close_rounded,
};

/// The icon for one option of a category-specific question, or null.
///
/// Null means "this question does not take icons". Callers must render
/// nothing rather than substituting a fallback, or the scales get decorated
/// after all.
IconData? iconForSchemaOption(String? fieldKey, String? value) {
  final f = (fieldKey ?? '').trim();
  if (f.isEmpty) return null;
  final exact = kOptionIcons['$f.${(value ?? '').trim()}'];
  if (exact != null) return exact;
  return kFieldIcons[f];
}

/// Amenity labels, matched by keyword. Order matters — entries that share a
/// stem with something else come first.
const List<List<Object>> _amenityKeywords = <List<Object>>[
  // Share a stem with something else, so they go first.
  ['dishwash', Icons.restaurant_outlined],
  ['washing machine', Icons.local_laundry_service_outlined],
  ['washer', Icons.local_laundry_service_outlined],
  ['air condition', Icons.ac_unit],

  // Connectivity
  ['wifi', Icons.wifi],
  ['wi-fi', Icons.wifi],
  ['internet', Icons.wifi],
  ['ethernet', Icons.settings_ethernet],
  ['network', Icons.wifi],

  // Kitchen
  ['refrigerator', Icons.kitchen_outlined],
  ['fridge', Icons.kitchen_outlined],
  ['microwave', Icons.microwave_outlined],
  ['oven', Icons.microwave_outlined],
  ['stove', Icons.local_fire_department_outlined],
  ['induction', Icons.local_fire_department_outlined],
  ['kettle', Icons.local_cafe_outlined],
  ['coffee', Icons.local_cafe_outlined],
  ['toaster', Icons.restaurant_menu_outlined],
  ['rice cooker', Icons.restaurant_menu_outlined],
  ['blender', Icons.restaurant_menu_outlined],
  ['cook', Icons.restaurant_menu_outlined],
  ['kitchen', Icons.restaurant_outlined],
  ['dining', Icons.restaurant_outlined],
  ['utensil', Icons.restaurant_outlined],
  ['crockery', Icons.restaurant_outlined],
  ['purifier', Icons.water_drop_outlined],

  // Bath
  ['bathtub', Icons.bathtub_outlined],
  ['bathroom', Icons.bathtub_outlined],
  ['shower', Icons.shower_outlined],
  ['toilet', Icons.wc_outlined],
  ['hair dryer', Icons.air],
  ['shampoo', Icons.water_drop_outlined],
  ['soap', Icons.water_drop_outlined],
  ['towel', Icons.water_drop_outlined],
  ['hot water', Icons.water_drop_outlined],
  ['geyser', Icons.water_drop_outlined],

  // Climate and bedroom
  ['heater', Icons.local_fire_department_outlined],
  ['heating', Icons.local_fire_department_outlined],
  ['ceiling fan', Icons.mode_fan_off_outlined],
  ['fan', Icons.mode_fan_off_outlined],
  ['blanket', Icons.bed_outlined],
  ['pillow', Icons.bed_outlined],
  ['linen', Icons.bed_outlined],
  ['mattress', Icons.bed_outlined],
  ['bed', Icons.bed_outlined],
  ['wardrobe', Icons.checkroom_outlined],
  ['hanger', Icons.checkroom_outlined],
  ['iron', Icons.checkroom_outlined],
  ['cupboard', Icons.checkroom_outlined],

  // Safety
  ['fire extinguisher', Icons.fire_extinguisher],
  ['fire exit', Icons.sensor_door_outlined],
  ['fire', Icons.local_fire_department_outlined],
  ['smoke alarm', Icons.notifications_active_outlined],
  ['carbon monoxide', Icons.notifications_active_outlined],
  ['alarm', Icons.notifications_active_outlined],
  ['emergency light', Icons.bolt_outlined],
  ['first aid', Icons.medical_services_outlined],
  ['hospital', Icons.local_hospital_outlined],
  ['doctor', Icons.medical_services_outlined],
  ['cctv', Icons.videocam_outlined],
  ['camera', Icons.videocam_outlined],
  ['security guard', Icons.security_outlined],
  ['guard', Icons.security_outlined],
  ['smart lock', Icons.lock_outline],
  ['digital lock', Icons.lock_outline],
  ['biometric', Icons.fingerprint],
  ['lock', Icons.lock_outline],
  ['gated', Icons.security_outlined],

  // Outdoor and premium
  ['swimming', Icons.pool_outlined],
  ['pool', Icons.pool_outlined],
  ['jacuzzi', Icons.hot_tub_outlined],
  ['garden', Icons.park_outlined],
  ['lawn', Icons.park_outlined],
  ['terrace', Icons.wb_sunny_outlined],
  ['balcony', Icons.wb_sunny_outlined],
  ['bonfire', Icons.local_fire_department_outlined],
  ['barbecue', Icons.outdoor_grill_outlined],
  ['bbq', Icons.outdoor_grill_outlined],
  ['gym', Icons.fitness_center_outlined],
  ['fitness', Icons.fitness_center_outlined],
  ['spa', Icons.spa_outlined],
  ['sauna', Icons.spa_outlined],

  // House and building
  ['parking', Icons.local_parking_outlined],
  ['lift', Icons.elevator_outlined],
  ['elevator', Icons.elevator_outlined],
  ['power backup', Icons.bolt_outlined],
  ['generator', Icons.bolt_outlined],
  ['inverter', Icons.bolt_outlined],
  ['electricity', Icons.bolt_outlined],
  ['workspace', Icons.work_outline],
  ['desk', Icons.work_outline],
  ['sofa', Icons.weekend_outlined],
  ['living', Icons.weekend_outlined],
  ['television', Icons.tv_outlined],
  ['tv', Icons.tv_outlined],
  ['music', Icons.music_note_outlined],
  ['wheelchair', Icons.accessible_outlined],
  ['ramp', Icons.accessible_outlined],
  ['pet', Icons.pets_outlined],
  ['child', Icons.child_care_outlined],
  ['baby', Icons.child_care_outlined],
  ['crib', Icons.child_care_outlined],
  ['housekeep', Icons.auto_awesome_outlined],
  ['cleaning', Icons.auto_awesome_outlined],
  ['laundry', Icons.local_laundry_service_outlined],

  // Nearby / transport
  ['airport', Icons.flight_outlined],
  ['railway', Icons.train_outlined],
  ['train', Icons.train_outlined],
  ['metro', Icons.train_outlined],
  ['bus', Icons.directions_bus_outlined],
  ['taxi', Icons.local_taxi_outlined],
  ['market', Icons.storefront_outlined],
  ['mall', Icons.shopping_bag_outlined],
  ['shop', Icons.shopping_bag_outlined],
  ['school', Icons.school_outlined],
  ['college', Icons.school_outlined],
  ['atm', Icons.payments_outlined],
  ['bank', Icons.payments_outlined],
  ['temple', Icons.account_balance_outlined],
  ['beach', Icons.beach_access_outlined],
  ['lake', Icons.pool_outlined],
  ['river', Icons.pool_outlined],
  ['mountain', Icons.terrain_outlined],
  ['view', Icons.visibility_outlined],
];

/// The group an amenity belongs to, when its own label does not give it away.
///
/// "Attached" and "Shared" mean nothing by themselves and everything under
/// the heading Bathroom. Matching the group is also what keeps this honest as
/// the schema grows: a new bathroom fitting inherits the bath icon rather
/// than the generic tag, without anybody adding a keyword for it.
const Map<String, IconData> kGroupIcons = <String, IconData>{
  'internet': Icons.wifi,
  'kitchen_appliances': Icons.restaurant_outlined,
  'bathroom': Icons.bathtub_outlined,
  'bedroom': Icons.bed_outlined,
  'fire_safety': Icons.local_fire_department_outlined,
  'medical': Icons.medical_services_outlined,
  'security': Icons.security_outlined,
  'outdoor': Icons.park_outlined,
  'premium': Icons.spa_outlined,
  'accessibility': Icons.accessible_outlined,
  'family': Icons.child_care_outlined,
  'experiences': Icons.auto_awesome_outlined,
  'views': Icons.terrain_outlined,
  'scenic_views': Icons.terrain_outlined,
};

/// Shown when neither the label nor its group matches: an amenity is an
/// attribute, so — a tag.
const IconData kAmenityFallback = Icons.sell_outlined;

/// The icon for an amenity label. Always returns something, so one
/// unrecognised amenity cannot leave a single short chip in an even grid.
///
/// [groupKey] is the schema group the option came from, consulted only when
/// the label itself says nothing.
IconData iconForAmenity(String? label, [String? groupKey]) {
  final l = (label ?? '').toLowerCase().trim();
  if (l.isEmpty) return _groupIcon(groupKey);

  // "AC" is too short to keyword-match safely — it sits inside "backup",
  // "terrace" and half a dozen other words — so it is matched whole.
  if (l == 'ac' || l == 'a/c') return Icons.ac_unit;

  for (final entry in _amenityKeywords) {
    if (l.contains(entry[0] as String)) return entry[1] as IconData;
  }
  return _groupIcon(groupKey);
}

IconData _groupIcon(String? groupKey) =>
    kGroupIcons[(groupKey ?? '').toLowerCase().trim()] ?? kAmenityFallback;
