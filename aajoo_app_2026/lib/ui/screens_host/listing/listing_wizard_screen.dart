// AAJOO HOST LISTING — the five-step wizard, on the phone.
//
// The same form the website serves at /host/list-property, section for section
// and question for question. It is the same form in the strongest sense
// available: both clients render whatever GET /listing/schema describes and
// post to the same five step endpoints, so the eleven category flows, the
// amenity groups, the pricing bounds and the validation are defined once,
// server-side, and neither client can drift from the other.
//
// This replaces the old six-step form, which wrote to /host/add — a different,
// flatter shape that the website itself retired. A listing created here lands
// in the same tables, with the same verification workflow, as one created on
// the site.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/models/listing_schema.dart';
import 'package:rent_home/ui/responsive.dart';
import 'package:rent_home/ui/screens_host/listing/listing_wizard_controller.dart';
import 'package:rent_home/ui/screens_host/listing/widgets/listing_section.dart';
import 'package:rent_home/ui/screens_host/listing/widgets/schema_field_input.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/utils/input_sanitizers.dart';

class ListingWizardScreen extends StatefulWidget {
  const ListingWizardScreen({super.key, this.propertyId});

  /// Set to edit an existing listing; null creates a new one.
  final int? propertyId;

  @override
  State<ListingWizardScreen> createState() => _ListingWizardScreenState();
}

class _ListingWizardScreenState extends State<ListingWizardScreen> {
  late final ListingWizardController c = Get.put(
    ListingWizardController(propertyId: widget.propertyId),
    tag: 'listing-${widget.propertyId ?? 'new'}',
  );
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    Get.delete<ListingWizardController>(
        tag: 'listing-${widget.propertyId ?? 'new'}');
    super.dispose();
  }

  Future<void> _continue() async {
    FocusScope.of(context).unfocus();
    if (c.isLastStep) return;
    final ok = await c.saveAndContinue();
    if (!mounted) return;
    if (ok) {
      // A new step starts at its top, not wherever the last one was scrolled.
      _scroll.jumpTo(0);
      if (c.step.value == 4) c.refreshReadiness();
      return;
    }
    // Say it where the host is.
    //
    // The banner sits at the top of a page that is several screens long, and
    // Continue is pinned to the bottom — so on device, pressing Continue with
    // a missing field did nothing visible at all. The reason was on screen,
    // just not on THIS screen. Same fix the website made: a toast at the
    // button, and the page scrolls back to the banner behind it.
    if (c.error.value.isNotEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(c.error.value, style: inter(fontSize: 13.5)),
          backgroundColor: kDanger,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final problem = await c.submitListing();
    if (!mounted) return;
    if (problem != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(problem, style: inter(fontSize: 13.5)),
          backgroundColor: kDanger,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kSurface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Sent for review',
            style: fraunces(
                fontSize: 19, fontWeight: FontWeight.w700, color: kInk)),
        content: Text(
          'Your listing is with our team. We usually verify within 24–48 hours, '
          'and you will be notified as soon as it is live.',
          style: inter(fontSize: 14, color: kInk2, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Done',
                style: inter(fontWeight: FontWeight.w700, color: kIndigo)),
          ),
        ],
      ),
    );
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (c.step.value > 0) {
          c.back();
          _scroll.jumpTo(0);
        } else {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        backgroundColor: kSand,
        appBar: AppBar(
          backgroundColor: kSurface,
          foregroundColor: kInk,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (c.step.value == 0) {
                Navigator.pop(context);
              } else {
                c.back();
                _scroll.jumpTo(0);
              }
            },
          ),
          title: Text('List Your Property',
              style: fraunces(
                  fontSize: 17, fontWeight: FontWeight.w700, color: kInk)),
        ),
        body: Obx(() {
          if (c.loading.value) return const _WizardSkeleton();
          if (c.loadError.value.isNotEmpty || c.schema.value == null) {
            return _LoadFailed(
              message: c.loadError.value.isEmpty
                  ? 'The listing form could not be loaded.'
                  : c.loadError.value,
              onRetry: c.retryLoad,
            );
          }
          return Column(
            children: [
              _progress(),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                  child: ResponsiveBody(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (c.error.value.isNotEmpty) _errorBanner(),
                        _stepBody(),
                      ],
                    ),
                  ),
                ),
              ),
              _footer(),
            ],
          );
        }),
      ),
    );
  }

  // ── Chrome ────────────────────────────────────────────────────────────────

  Widget _progress() {
    return Container(
      color: kSurface,
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (int i = 0; i < kListingSteps.length; i++) ...[
                Expanded(
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= c.step.value ? kIndigo : kLine,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (i < kListingSteps.length - 1) const SizedBox(width: 6),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Step ${c.step.value + 1} of ${kListingSteps.length} · '
            '${kListingSteps[c.step.value]}',
            style:
                inter(fontSize: 12, fontWeight: FontWeight.w600, color: kMuted),
          ),
        ],
      ),
    );
  }

  Widget _errorBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kDanger.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, size: 18, color: kDanger),
          const SizedBox(width: 10),
          Expanded(
            child: Text(c.error.value,
                style: inter(fontSize: 13, color: kDanger, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    final last = c.isLastStep;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: const BoxDecoration(
          color: kSurface,
          border: Border(top: BorderSide(color: kLine)),
        ),
        child: Row(
          children: [
            if (c.step.value > 0) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: c.busy.value
                      ? null
                      : () {
                          c.back();
                          _scroll.jumpTo(0);
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: kInk,
                    side: const BorderSide(color: kLine),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Back',
                      style: inter(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: c.busy.value
                    ? null
                    : (last
                        ? (c.allDeclared ? _submit : null)
                        : _continue),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kIndigo,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: kLine,
                  disabledForegroundColor: kMuted,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: c.busy.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(last ? 'Submit for review' : 'Continue',
                              style: inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700)),
                          if (!last) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_rounded, size: 17),
                          ],
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Steps ─────────────────────────────────────────────────────────────────

  Widget _stepBody() {
    switch (c.step.value) {
      case 0:
        return _step1();
      case 1:
        return _step2();
      case 2:
        return _step3();
      case 3:
        return _step4();
      default:
        return _step5();
    }
  }

  /// Render a schema field, honouring its showIf against the given bucket.
  Widget _field(
    SchemaField field,
    Map<String, dynamic> values,
    void Function(String, dynamic) setter,
  ) {
    if (!isFieldVisible(field, values)) return const SizedBox.shrink();
    return SchemaFieldInput(
      field: field,
      value: values[field.key],
      onChanged: setter,
      error: c.fieldErrors[field.key],
    );
  }

  // ── Step 1 — Property Foundation ──────────────────────────────────────────

  Widget _step1() {
    final s = c.schema.value!;
    final category = c.f['property_category']?.toString();
    final isCamping = category == 'camping' || category == 'glamping';
    final isPg = category == 'pg_long_stay';
    final status = s.statuses
        .where((st) => st.value == c.f['property_status'])
        .toList();
    final needsMonths = status.isNotEmpty && status.first.requiresMonths;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListingSection(
          title: 'Who is listing this property?',
          children: [
            SingleChoiceRow(
              options: s.hostTypes,
              value: c.f['host_type']?.toString(),
              onSelect: (v) => c.setF('host_type', v),
            ),
          ],
        ),

        if (c.f['host_type'] == 'manager')
          ListingSection(
            title: 'Property manager details',
            sub: "We need the owner's authorisation before this listing can "
                'continue.',
            children: [
              _text('manager_full_name', 'Manager full name', required: true),
              _text('manager_mobile', 'Manager mobile',
                  required: true, numeric: true, maxLength: 10),
              _text('manager_email', 'Manager email'),
              _text('manager_owner_name', "Owner's name"),
              _text('manager_owner_contact', "Owner's contact",
                  numeric: true, maxLength: 10),
              ListingToggle(
                label: 'I have written authorisation from the owner',
                value: c.f['manager_authorization_available'] == true,
                onChanged: (v) =>
                    c.setF('manager_authorization_available', v),
              ),
              // Without an anchor here the rejection had nowhere to appear:
              // the toggle stayed plain and the host was left guessing.
              if (c.fieldErrors['manager_authorization_available'] != null)
                _fieldError(c.fieldErrors['manager_authorization_available']!),
            ],
          ),

        ListingSection(
          title: 'What type of property are you listing?',
          sub: 'Each category opens a different listing flow.',
          children: [
            SingleChoiceRow(
              options: s.categories,
              value: category,
              onSelect: (v) => c.setF('property_category', v),
            ),
            if (c.fieldErrors['property_category'] != null)
              _fieldError(c.fieldErrors['property_category']!),
          ],
        ),

        if (category != null && category.isNotEmpty)
          ListingSection(
            title: 'What are guests booking?',
            children: [
              SingleChoiceRow(
                options: s.accommodationFor(category),
                value: c.f['accommodation_type']?.toString(),
                onSelect: (v) => c.setF('accommodation_type', v),
              ),
              if (c.fieldErrors['accommodation_type'] != null)
                _fieldError(c.fieldErrors['accommodation_type']!),
            ],
          ),

        ListingSection(
          title: 'Aajoo LUXE',
          sub: 'Luxury stays appear in our black-and-gold LUXE collection, '
              'shown to guests browsing in Luxury mode.',
          children: [
            _LuxeCard(
              on: c.f['is_luxury'] == true,
              onTap: () => c.setF('is_luxury', c.f['is_luxury'] != true),
            ),
          ],
        ),

        ListingSection(
          title: 'Property name',
          sub: s.propertyNameRules.message,
          children: [
            _text('property_name', 'Property name', required: true),
          ],
        ),

        // The paragraph the property page prints as "About this stay". The
        // wizard never asked for it, so listings showed the SEO meta
        // description generated at step 5 instead.
        ListingSection(
          title: 'About this place',
          sub: 'A short description guests read first. What is the stay like, '
              'who is it for, what is nearby?',
          children: [
            _text(
              'description',
              'Description',
              required: true,
              maxLines: 6,
              maxLength: 5000,
              help: 'At least 40 characters. This appears as '
                  '“About this stay” on your listing.',
            ),
          ],
        ),

        ListingSection(
          title: 'Where is the property?',
          children: [
            _text('country', 'Country'),
            _text('state', 'State', required: true),
            _text('city', 'City', required: true),
            _text('district', 'District'),
            _text('village', 'Village (optional)'),
            _text('pincode', 'PIN Code',
                required: true, numeric: true, maxLength: 6),
            _text('street_address', 'Street address', required: true),
            _text('landmark', 'Nearby landmark'),
            const SizedBox(height: 4),
            Text('Show exact location before booking?',
                style: inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: kInk)),
            const SizedBox(height: 8),
            SingleChoiceRow(
              options: const [
                Option(value: 'yes', label: 'Yes'),
                Option(value: 'no', label: 'No'),
              ],
              value: c.f['show_exact_location'] == false ? 'no' : 'yes',
              onSelect: (v) => c.setF('show_exact_location', v == 'yes'),
            ),
          ],
        ),

        ListingSection(
          title: 'Ownership',
          children: [
            Text('Do you own this property?',
                style: inter(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: kInk)),
            const SizedBox(height: 8),
            SingleChoiceRow(
              options: const [
                Option(value: 'yes', label: 'Yes'),
                Option(value: 'no', label: 'No'),
              ],
              value: c.f['is_owner'] == false ? 'no' : 'yes',
              onSelect: (v) => c.setF('is_owner', v == 'yes'),
            ),
          ],
        ),

        ListingSection(
          title: 'Property status',
          children: [
            SingleChoiceRow(
              options: s.statuses,
              value: c.f['property_status']?.toString(),
              onSelect: (v) => c.setF('property_status', v),
            ),
            if (status.isNotEmpty && status.first.blocksPublish) ...[
              const SizedBox(height: 10),
              _note(
                'A listing with this status can be saved, but cannot go live '
                'until the property is ready for guests.',
              ),
            ],
            if (needsMonths) ...[
              const SizedBox(height: 14),
              Text('Which months do you operate?',
                  style: inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: kInk)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in kMonths)
                    ListingPill(
                      label: m,
                      selected: c.seasonalMonths.contains(m),
                      onTap: () => c.toggleMonth(m),
                    ),
                ],
              ),
            ],
          ],
        ),

        ListingSection(
          title: 'Guest capacity',
          sub: "Adults can't exceed your total capacity.",
          children: [
            _numRow([
              _numField('max_adults', 'Maximum adults'),
              _numField('max_children', 'Children'),
            ]),
            _numRow([
              _numField('max_infants', 'Infants'),
              _numField('total_guests', 'Total guests'),
            ]),
          ],
        ),

        ListingSection(
          title: 'Basic configuration',
          children: [
            if (isCamping)
              _numRow([
                _numField('tents', 'Number of tents'),
                _numField('beds', 'Beds'),
              ])
            else
              _numRow([
                _numField('bedrooms', 'Bedrooms'),
                _numField('beds', 'Beds'),
              ]),
            _numRow([
              _numField('bathrooms', 'Bathrooms'),
              const SizedBox.shrink(),
            ]),
            if (isPg) ...[
              const SizedBox(height: 4),
              Text('Who is this for?',
                  style: inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: kInk)),
              const SizedBox(height: 8),
              SingleChoiceRow(
                options: const [
                  Option(value: 'students', label: 'Students'),
                  Option(
                      value: 'working_professionals',
                      label: 'Working Professionals'),
                  Option(value: 'both', label: 'Both'),
                ],
                value: c.f['pg_audience']?.toString(),
                onSelect: (v) => c.setF('pg_audience', v),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // ── Step 2 — Property Details ─────────────────────────────────────────────

  Widget _step2() {
    final s = c.schema.value!;
    final flow = c.flow;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListingSection(
          title: 'Property specification',
          sub: 'Shown for every property type.',
          children: [
            for (final field in s.specificationFields)
              _field(field, c.spec, c.setSpec),
          ],
        ),
        if (flow != null && flow.fields.isNotEmpty)
          ListingSection(
            title: '${flow.label} details',
            sub: 'These questions are specific to your property type.',
            children: [
              for (final field in flow.fields)
                _field(field, c.attrs, c.setAttr),
            ],
          )
        else
          _note('Pick a property category on the first step to see the '
              'questions for it.'),
      ],
    );
  }

  // ── Step 3 — Amenities & Location ─────────────────────────────────────────

  Widget _step3() {
    final s = c.schema.value!;
    final category = c.f['property_category']?.toString();
    final experienceKeys = s.experiencesByCategory[category] ?? const [];
    final isPg = category == 'pg_long_stay';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListingSection(
          title: 'Essential amenities',
          sub: 'Shown for every property.',
          children: [
            for (final g in s.essentialAmenities)
              OptionGroupPicker(
                label: g.label,
                options: g.options,
                selected: c.amenities[g.key] ?? const [],
                onToggle: (v) => c.toggleAmenity(g.key, v),
              ),
            for (final field in s.essentialAmenityFields)
              _field(field, c.details, c.setDetail),
          ],
        ),

        ListingSection(
          title: 'Safety',
          sub: 'Applies to every property.',
          children: [
            for (final g in s.safetyGroups)
              OptionGroupPicker(
                label: g.label,
                options: g.options,
                selected: c.amenities[g.key] ?? const [],
                onToggle: (v) => c.toggleAmenity(g.key, v),
              ),
            for (final field in s.safetyFields)
              _field(field, c.details, c.setDetail),
          ],
        ),

        ListingSection(
          title: 'Outdoor',
          children: [
            OptionGroupPicker(
              label: '',
              options: s.outdoorFor(category),
              selected: c.amenities[s.outdoorAmenities.key] ?? const [],
              onToggle: (v) => c.toggleAmenity(s.outdoorAmenities.key, v),
            ),
          ],
        ),

        ListingSection(
          title: 'Premium amenities',
          children: [
            OptionGroupPicker(
              label: '',
              options: s.premiumAmenities.options,
              selected: c.amenities[s.premiumAmenities.key] ?? const [],
              onToggle: (v) => c.toggleAmenity(s.premiumAmenities.key, v),
            ),
            for (final field in s.premiumFields)
              _field(field, c.details, c.setDetail),
          ],
        ),

        ListingSection(
          title: 'Accessibility',
          children: [
            OptionGroupPicker(
              label: '',
              options: s.accessibility.options,
              selected: c.amenities[s.accessibility.key] ?? const [],
              onToggle: (v) => c.toggleAmenity(s.accessibility.key, v),
            ),
          ],
        ),

        ListingSection(
          title: 'Pet policy',
          children: [
            for (final field in s.petPolicyFields)
              _field(field, c.details, c.setDetail),
          ],
        ),

        ListingSection(
          title: 'Families & children',
          children: [
            for (final field in s.familyFields)
              _field(field, c.details, c.setDetail),
            OptionGroupPicker(
              label: s.familyAmenities.label,
              options: s.familyAmenities.options,
              selected: c.amenities[s.familyAmenities.key] ?? const [],
              onToggle: (v) => c.toggleAmenity(s.familyAmenities.key, v),
            ),
          ],
        ),

        if (experienceKeys.isNotEmpty)
          ListingSection(
            title: 'Experiences',
            sub: 'What can guests do at or around your property?',
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final e in experienceKeys)
                    ListingPill(
                      label: _humanise(e),
                      selected: c.experiences.contains(e),
                      onTap: () => c.toggleIn(c.experiences, e),
                    ),
                ],
              ),
            ],
          ),

        if (isPg && s.pgNearbyEssentials.isNotEmpty)
          ListingSection(
            title: 'Nearby essentials',
            sub: "What's close by for long-stay guests?",
            children: [
              for (final place in s.pgNearbyEssentials)
                _nearbyRow('pg_essentials', place),
            ],
          ),

        ListingSection(
          title: 'Scenic views',
          children: [
            OptionGroupPicker(
              label: '',
              options: s.scenicViews.options,
              selected: c.views,
              onToggle: (v) => c.toggleIn(c.views, v),
            ),
          ],
        ),

        for (final g in s.nearbyGroups)
          ListingSection(
            title: g.label,
            sub: 'Distance in km — leave blank if it does not apply.',
            children: [
              for (final o in g.options) _nearbyRow(g.key, o.value, o.label),
            ],
          ),

        _PhotoStep(controller: c, rules: s.photoRules),
      ],
    );
  }

  Widget _nearbyRow(String group, String place, [String? label]) {
    return _NearbyField(
      label: label ?? _ListingWizardScreenState._humanise(place),
      initial: (c.nearby[group]?[place] ?? '').toString(),
      onChanged: (v) => c.setNearby(group, place, v),
    );
  }

  // ── Step 4 — Pricing & Booking ────────────────────────────────────────────

  Widget _step4() {
    final s = c.schema.value!;
    final r = s.pricingRules;
    final b = s.bookingRules;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListingSection(
          title: 'Base price',
          sub: 'What one night costs before any discount.',
          children: [
            _p4Text('base_price', 'Price per night (₹)',
                required: true,
                numeric: true,
                help: 'Your standard rate for one night, before any discount. '
                    'e.g. 2500'),
            if (r.currencies.length > 1)
              _p4Choice('currency', 'Currency', r.currencies),
          ],
        ),
        ListingSection(
          title: 'Long-stay discounts',
          sub: 'Up to ${r.maxDiscountPercent}%.',
          children: [
            _p4Text('weekly_discount', 'Weekly discount (%)',
                numeric: true,
                help: 'Off the nightly rate for stays of 7 nights or more. '
                    '5–15% is common.'),
            _p4Text('monthly_discount', 'Monthly discount (%)',
                numeric: true,
                help: 'For 28 nights or more. 20–35% is common.'),
          ],
        ),
        ListingSection(
          title: 'Fees & deposit',
          children: [
            _p4Text('cleaning_fee', 'Cleaning fee (₹)',
                numeric: true,
                help: 'Typically ₹300–₹1,500 depending on size. '
                    'Leave blank for none.'),
            if (r.cleaningFeeTypes.isNotEmpty)
              _p4Choice('cleaning_fee_type', 'Cleaning fee applies',
                  r.cleaningFeeTypes),
            _p4Text('security_deposit', 'Security deposit (₹)',
                numeric: true,
                help: 'Held against damage, commonly about one night\'s rate. '
                    'Leave blank for none.'),
            _p4Text('extra_guest_fee', 'Extra guest fee (₹)', numeric: true),
          ],
        ),
        ListingSection(
          title: 'Negotiation',
          sub: 'Aajoo is negotiation-first — guests can send you an offer.',
          children: [
            ListingToggle(
              label: 'Accept offers on this listing',
              value: c.p4['negotiation_enabled'] != false,
              onChanged: (v) => c.setP4('negotiation_enabled', v),
            ),
            if (c.p4['negotiation_enabled'] != false) ...[
              const SizedBox(height: 8),
              // The key is what the backend reads. It was
              // 'min_acceptable_price', which nothing on the server looks at,
              // so a host who set a floor here set nothing — and their listing
              // then refused every offer, because an absent floor means "this
              // stay does not negotiate".
              _p4Text('negotiation_minimum_price',
                  'Lowest price you will accept (₹)',
                  numeric: true,
                  // The old text said offers below this are declined
                  // automatically. They are not: below the floor the offer
                  // comes to you to accept, counter or decline. Nothing is
                  // ever refused on your behalf.
                  help: 'Guests never see this. Offers at or above it are '
                      'accepted for you straight away; anything below comes to '
                      'you to decide. Leave it blank and this stay takes no '
                      'offers at all.'),
              const SizedBox(height: 8),
              _p4Text('negotiation_ideal_price', 'Your ideal price (₹)',
                  numeric: true,
                  help: 'Optional, and also never shown to guests. Recorded '
                      'for future pricing guidance — it does not change what '
                      'gets accepted today.'),
            ],
          ],
        ),
        ListingSection(
          title: 'How guests book',
          children: [
            if (b.bookingTypes.isNotEmpty)
              _p4Choice('booking_type', 'Booking type', b.bookingTypes),
            if (b.responseTimes.isNotEmpty)
              _p4Choice('response_time', 'Your usual response time',
                  b.responseTimes),
            if (b.availability.isNotEmpty)
              _p4Choice('availability', 'Availability', b.availability),
            if (b.earlyCheckin.isNotEmpty)
              _p4Choice('early_checkin', 'Early check-in', b.earlyCheckin),
            if (b.selfCheckinMethods.isNotEmpty)
              _p4Choice('self_checkin_method', 'Self check-in',
                  b.selfCheckinMethods),
            _p4Text('min_nights', 'Minimum nights', numeric: true),
            _p4Text('max_nights', 'Maximum nights', numeric: true),
          ],
        ),
        ListingSection(
          title: 'Cancellation policy',
          sub: 'Guests see this before booking; it decides their refund.',
          children: [
            SingleChoiceRow(
              options: s.cancellationPolicies,
              value: c.p4['cancellation_policy']?.toString(),
              onSelect: (v) => c.setP4('cancellation_policy', v),
            ),
          ],
        ),
        ListingSection(
          title: 'House rules',
          children: [
            for (final t in s.houseRuleToggles)
              ListingToggle(
                label: t.label,
                value: c.houseRules[t.value] == true,
                onChanged: (v) => c.toggleHouseRule(t.value, v),
              ),
          ],
        ),
        ListingSection(
          title: 'Payouts',
          children: [
            if (b.payoutCycles.isNotEmpty)
              _p4Choice('payout_cycle', 'Payout cycle', b.payoutCycles),
          ],
        ),
      ],
    );
  }

  // ── Step 5 — Verify & Publish ─────────────────────────────────────────────

  Widget _step5() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ReadinessCard(controller: c),
        // Identity is asked for ONCE. A host who has been through the face
        // and document check has already given us all of this, and was asked
        // for the same document at signup as well. Verified hosts get a
        // confirmation instead of a third form.
        if (c.readiness['identity'] is Map &&
            (c.readiness['identity'] as Map)['verified'] == true)
          ListingSection(
            title: 'Identity verification',
            sub: 'Already done — nothing to fill in.',
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_user, color: kSuccess, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Identity verified. You will not be asked for your ID '
                      'again.',
                      style: inter(fontSize: 13, color: kInk2),
                    ),
                  ),
                ],
              ),
            ],
          )
        else
          ListingSection(
            title: 'Identity verification',
            sub: 'Required before your listing can go live.',
            children: [
              _p5Choice('id_type', 'Document type', const [
                Option(value: 'aadhaar', label: 'Aadhaar'),
                Option(value: 'passport', label: 'Passport'),
                Option(value: 'driving_licence', label: 'Driving Licence'),
                Option(value: 'voter_id', label: 'Voter ID'),
              ]),
              _DocumentField(
                label: 'Identity document',
                value: c.p5['id_document']?.toString(),
                onPick: (file) => c.uploadDocument(file, 'id_document'),
              ),
            ],
          ),
        ListingSection(
          title: 'Property ownership',
          sub: 'One document proving you can list this property.',
          children: [
            _DocumentField(
              label: 'Ownership proof',
              value: c.p5['ownership_document']?.toString(),
              onPick: (file) => c.uploadDocument(file, 'ownership_document'),
            ),
          ],
        ),
        // The account that actually receives money lives on the host's
        // profile — penny-drop verified and encrypted. Asking again per
        // property meant a host with five listings typed it six times, and
        // the copy typed here was never the one that got paid.
        if (c.readiness['payoutAccount'] is Map)
          ListingSection(
            title: 'Bank details',
            sub: 'Where your payouts are sent.',
            children: [
              Row(
                children: [
                  const Icon(Icons.account_balance, color: kIndigo, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Earnings from this listing go to '
                      '${(c.readiness['payoutAccount'] as Map)['bankName'] ?? 'your payout account'}'
                      ' ${(c.readiness['payoutAccount'] as Map)['masked'] ?? ''}'
                      '. Change it in Payout settings.',
                      style: inter(fontSize: 13, color: kInk2),
                    ),
                  ),
                ],
              ),
            ],
          )
        else
          ListingSection(
            title: 'Bank details',
            sub: 'Where your payouts are sent.',
            children: [
              _p5Text('account_holder_name', 'Account holder name',
                  formatters: AppInputFormatters.name),
              _p5Text('account_number', 'Account number', numeric: true),
              _p5Text('ifsc', 'IFSC code',
                  formatters: AppInputFormatters.upperAlnum(11)),
              // Held a 16-digit account number in the reported screenshot.
              _p5Text('bank_name', 'Bank name',
                  help: 'e.g. State Bank of India',
                  formatters: AppInputFormatters.place),
            ],
          ),
        ListingSection(
          title: 'Emergency contact',
          children: [
            _p5Text('emergency_name', 'Contact name',
                formatters: AppInputFormatters.name),
            _p5Text('emergency_phone', 'Contact number',
                numeric: true, maxLength: 10),
          ],
        ),
        ListingSection(
          title: 'Caretaker',
          children: [
            _p5Text('caretaker_name', 'Caretaker name',
                formatters: AppInputFormatters.name),
            _p5Text('caretaker_phone', 'Caretaker number',
                numeric: true, maxLength: 10),
          ],
        ),
        ListingSection(
          title: 'Compliance',
          children: [
            _p5Text('gst_number', 'GSTIN (optional)'),
            _p5Text('trade_licence', 'Trade licence number (optional)'),
          ],
        ),
        ListingSection(
          title: 'Declaration',
          sub: 'All of these are required before we can verify your listing.',
          children: [
            for (final d in kListingDeclarations)
              _DeclarationRow(
                label: d.value,
                value: c.declarations[d.key] == true,
                onChanged: (v) => c.toggleDeclaration(d.key, v),
              ),
          ],
        ),
      ],
    );
  }

  // ── Small builders ────────────────────────────────────────────────────────

  Widget _fieldError(String msg) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(msg, style: inter(fontSize: 11.5, color: kDanger)),
      );

  Widget _note(String text) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kIndigo50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kIndigo.withOpacity(0.18)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded, size: 17, color: kIndigo),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: inter(fontSize: 12.5, color: kInk2, height: 1.5)),
            ),
          ],
        ),
      );

  Widget _numRow(List<Widget> children) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: children[0]),
          const SizedBox(width: 12),
          Expanded(child: children[1]),
        ],
      );

  Widget _numField(String key, String label) =>
      _text(key, label, numeric: true, maxLength: 3);

  Widget _text(
    String key,
    String label, {
    bool required = false,
    bool numeric = false,
    int? maxLength,
    int maxLines = 1,
    String? help,
  }) {
    return _KeyedField(
      // Rebuilt when a draft loads over an empty form, not on every keystroke.
      fieldKey: 'f-$key',
      initial: (c.f[key] ?? '').toString(),
      label: label,
      required: required,
      numeric: numeric,
      maxLength: maxLength,
      maxLines: maxLines,
      help: help,
      error: c.fieldErrors[key],
      onChanged: (v) => c.setF(key, v),
    );
  }

  Widget _p4Text(String key, String label,
          {bool required = false, bool numeric = false, String? help}) =>
      _KeyedField(
        fieldKey: 'p4-$key',
        initial: (c.p4[key] ?? '').toString(),
        label: label,
        required: required,
        numeric: numeric,
        help: help,
        error: c.fieldErrors[key],
        onChanged: (v) => c.setP4(key, v),
      );

  Widget _p5Text(String key, String label,
          {bool numeric = false,
          int? maxLength,
          String? help,
          List<TextInputFormatter>? formatters}) =>
      _KeyedField(
        fieldKey: 'p5-$key',
        initial: (c.p5[key] ?? '').toString(),
        label: label,
        numeric: numeric,
        maxLength: maxLength,
        help: help,
        formatters: formatters,
        error: c.fieldErrors[key],
        onChanged: (v) => c.setP5(key, v),
      );

  Widget _p4Choice(String key, String label, List<Option> options) =>
      SchemaFieldInput(
        field: SchemaField(
            key: key, label: label, type: FieldType.select, options: options),
        value: c.p4[key],
        onChanged: (k, v) => c.setP4(k, v),
        error: c.fieldErrors[key],
      );

  Widget _p5Choice(String key, String label, List<Option> options) =>
      SchemaFieldInput(
        field: SchemaField(
            key: key, label: label, type: FieldType.select, options: options),
        value: c.p5[key],
        onChanged: (k, v) => c.setP5(k, v),
        error: c.fieldErrors[key],
      );

  /// "mountain_view" → "Mountain view", for the schema's bare string lists.
  static String _humanise(String raw) {
    final words = raw.replaceAll('_', ' ').trim();
    if (words.isEmpty) return raw;
    return words[0].toUpperCase() + words.substring(1);
  }
}

/// A text input that owns its controller, so typing does not rebuild the step.
class _KeyedField extends StatefulWidget {
  const _KeyedField({
    required this.fieldKey,
    required this.initial,
    required this.label,
    this.required = false,
    this.numeric = false,
    this.maxLength,
    this.maxLines = 1,
    this.help,
    this.formatters,
    this.error,
    required this.onChanged,
  });

  final String fieldKey;
  final String initial;
  final String label;
  final bool required;
  final bool numeric;
  final int? maxLength;
  final int maxLines;
  final String? help;
  /// Overrides the default numeric/length formatters when a field needs its
  /// own rule — a bank name that takes letters but not digits, say.
  final List<TextInputFormatter>? formatters;
  final String? error;
  final ValueChanged<String> onChanged;

  @override
  State<_KeyedField> createState() => _KeyedFieldState();
}

class _KeyedFieldState extends State<_KeyedField> {
  late final TextEditingController _c =
      TextEditingController(text: widget.initial);

  @override
  void didUpdateWidget(covariant _KeyedField old) {
    super.didUpdateWidget(old);
    // Adopt a value that arrived from elsewhere (a loaded draft), but never
    // fight the host while they are typing into it.
    if (widget.initial != old.initial && widget.initial != _c.text) {
      _c.text = widget.initial;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListingTextField(
      controller: _c,
      label: widget.label,
      required: widget.required,
      numeric: widget.numeric,
      maxLines: widget.maxLines,
      help: widget.help,
      error: widget.error,
      keyboardType:
          widget.numeric ? TextInputType.number : TextInputType.text,
      inputFormatters: widget.formatters ??
          (widget.numeric
              ? [
                  FilteringTextInputFormatter.digitsOnly,
                  if (widget.maxLength != null)
                    LengthLimitingTextInputFormatter(widget.maxLength),
                ]
              : (widget.maxLength != null
                  ? [LengthLimitingTextInputFormatter(widget.maxLength)]
                  : null)),
      onChanged: widget.onChanged,
    );
  }
}

/// The LUXE opt-in — the website's black-and-gold card.
class _LuxeCard extends StatelessWidget {
  const _LuxeCard({required this.on, required this.onTap});

  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: on
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1C1813), Color(0xFF12100C)],
                )
              : null,
          color: on ? null : kSurface,
          border: Border.all(
            color: on ? const Color(0xFFD4AF37) : kLine,
            width: on ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: on
                    ? const Color(0xFFD4AF37).withOpacity(0.16)
                    : kIndigo50,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(Icons.diamond_outlined,
                  size: 20,
                  color: on ? const Color(0xFFD4AF37) : kIndigo),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mark as a LUXE stay',
                      style: fraunces(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: on ? const Color(0xFFF5EFE2) : kInk)),
                  const SizedBox(height: 2),
                  Text(
                    on
                        ? 'This listing will appear in the LUXE collection.'
                        : 'Only for premium finishes, exceptional amenities '
                            'and prime locations.',
                    style: inter(
                        fontSize: 12,
                        color: on ? const Color(0xFF9C9280) : kMuted,
                        height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              on
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 22,
              color: on ? const Color(0xFFD4AF37) : kMuted,
            ),
          ],
        ),
      ),
    );
  }
}

/// Photos — the minimum the schema demands, and how far off the host is.
class _PhotoStep extends StatelessWidget {
  const _PhotoStep({required this.controller, required this.rules});

  final ListingWizardController controller;
  final PhotoRules rules;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final count = controller.media.length;
      final ready = count >= rules.minimum;
      return ListingSection(
        title: 'Photos',
        sub: 'At least ${rules.minimum}, ${rules.recommended} recommended. '
            'The first one becomes your cover.',
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: ready ? const Color(0xFFEAF6EE) : const Color(0xFFFFF6E5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  ready
                      ? Icons.check_circle_rounded
                      : Icons.photo_library_outlined,
                  size: 18,
                  color: ready ? kSuccess : kClay,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$count of ${rules.minimum} required photos added',
                    style: inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: ready ? kSuccess : kClay),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (controller.media.isNotEmpty)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final m in controller.media)
                  _Thumb(
                    url: m['url']?.toString(),
                    onRemove: () {
                      final id = m['id'];
                      if (id is num) controller.removePhoto(id.toInt());
                    },
                  ),
              ],
            ),
          if (controller.media.isNotEmpty) const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: controller.uploading.value
                  ? null
                  : () => _pick(context),
              icon: controller.uploading.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: kIndigo),
                    )
                  : const Icon(Icons.add_photo_alternate_outlined, size: 18),
              label: Text(
                  controller.uploading.value ? 'Uploading…' : 'Add photos',
                  style: inter(fontSize: 14, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                foregroundColor: kIndigo,
                side: const BorderSide(color: kIndigo),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          if (controller.propertyId.value == null) ...[
            const SizedBox(height: 8),
            Text(
              'Photos upload once the first step is saved.',
              style: inter(fontSize: 11.5, color: kMuted),
            ),
          ],
        ],
      );
    });
  }

  Future<void> _pick(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 82);
    if (picked.isEmpty) return;
    final problem = await controller.uploadPhotos(
      picked.map((x) => File(x.path)).toList(),
      // The first photo of an empty listing is its cover; the rest are
      // uncategorised until the host says otherwise on the website.
      controller.media.isEmpty ? 'cover_photo' : '',
    );
    if (problem != null && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(problem)));
    }
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url, required this.onRemove});

  final String? url;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 92,
      height: 92,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 92,
              height: 92,
              child: (url == null || url!.isEmpty)
                  ? Container(color: kIndigo50)
                  : Image.network(url!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: kIndigo50)),
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: InkWell(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pick a file, upload it, and show what was uploaded — never a URL box.
class _DocumentField extends StatelessWidget {
  const _DocumentField({
    required this.label,
    required this.value,
    required this.onPick,
  });

  final String label;
  final String? value;
  final Future<String?> Function(File file) onPick;

  @override
  Widget build(BuildContext context) {
    final has = value != null && value!.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: inter(
                  fontSize: 13.5, fontWeight: FontWeight.w600, color: kInk)),
          const SizedBox(height: 7),
          InkWell(
            onTap: () async {
              final picker = ImagePicker();
              final x = await picker.pickImage(
                  source: ImageSource.gallery, imageQuality: 88);
              if (x == null) return;
              final problem = await onPick(File(x.path));
              if (problem != null && context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(problem)));
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: has ? const Color(0xFFEAF6EE) : kSand,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: has ? kSuccess : kLine),
              ),
              child: Row(
                children: [
                  Icon(
                    has
                        ? Icons.check_circle_rounded
                        : Icons.upload_file_rounded,
                    size: 19,
                    color: has ? kSuccess : kMuted,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      has ? 'Uploaded' : 'Choose a file',
                      style: inter(
                          fontSize: 14.5,
                          fontWeight:
                              has ? FontWeight.w600 : FontWeight.w500,
                          color: has ? kSuccess : kMuted),
                    ),
                  ),
                  if (has)
                    Text('Replace',
                        style: inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: kIndigo)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeclarationRow extends StatelessWidget {
  const _DeclarationRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 26,
              height: 26,
              child: Checkbox(
                value: value,
                onChanged: (v) => onChanged(v ?? false),
                activeColor: kIndigo,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(label,
                    style: inter(fontSize: 13.5, color: kInk, height: 1.4)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The completeness score the server calculates, and what is still missing.
class _ReadinessCard extends StatelessWidget {
  const _ReadinessCard({required this.controller});

  final ListingWizardController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final r = controller.readiness['readiness'];
      if (r is! Map) return const SizedBox.shrink();
      final score = (r['score'] is num) ? (r['score'] as num).toInt() : 0;
      final missing = (r['missing'] is List)
          ? (r['missing'] as List).map((e) => e.toString()).toList()
          : <String>[];
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kIndigo50, kSurface],
          ),
          border: Border.all(color: kIndigo.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Listing readiness',
                    style: inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kMuted)),
                const Spacer(),
                Text('$score%',
                    style: fraunces(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: kIndigo)),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: (score / 100).clamp(0.0, 1.0),
                minHeight: 7,
                backgroundColor: kLine,
                color: kIndigo,
              ),
            ),
            if (missing.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Still to add: ${missing.take(4).join(', ')}'
                  '${missing.length > 4 ? '…' : ''}',
                  style: inter(fontSize: 12, color: kInk2, height: 1.45)),
            ],
          ],
        ),
      );
    });
  }
}

class _WizardSkeleton extends StatelessWidget {
  const _WizardSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (int i = 0; i < 6; i++)
          Container(
            height: 74,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: kSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kLine),
            ),
          ),
      ],
    );
  }
}

class _LoadFailed extends StatelessWidget {
  const _LoadFailed({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 46, color: kMuted),
            const SizedBox(height: 14),
            Text("Couldn't load the listing form",
                textAlign: TextAlign.center,
                style: fraunces(
                    fontSize: 17, fontWeight: FontWeight.w700, color: kInk)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: inter(fontSize: 13, color: kMuted, height: 1.5)),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text('Try again',
                  style: inter(fontSize: 14, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                foregroundColor: kIndigo,
                side: const BorderSide(color: kIndigo),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One "how far is X" row. Owns its controller, because building a
/// TextEditingController inside build() recreates it on every rebuild and
/// drops the caret to the start mid-typing.
class _NearbyField extends StatefulWidget {
  const _NearbyField({
    required this.label,
    required this.initial,
    required this.onChanged,
  });

  final String label;
  final String initial;
  final ValueChanged<String> onChanged;

  @override
  State<_NearbyField> createState() => _NearbyFieldState();
}

class _NearbyFieldState extends State<_NearbyField> {
  late final TextEditingController _c =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(widget.label,
                style: inter(fontSize: 14, color: kInk)),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 104,
            child: TextField(
              controller: _c,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              onChanged: widget.onChanged,
              style: inter(fontSize: 14, color: kInk),
              decoration: InputDecoration(
                hintText: 'km',
                hintStyle: inter(fontSize: 13.5, color: kMuted),
                isDense: true,
                filled: true,
                fillColor: kSand,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: kLine),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: kIndigo, width: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
