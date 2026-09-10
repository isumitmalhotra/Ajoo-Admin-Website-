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
import '../../../utils/image_rules.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/ui/screens_renter/home/components/lux_theme.dart';
import 'package:rent_home/models/listing_schema.dart';
import 'package:rent_home/ui/responsive.dart';
import 'package:rent_home/ui/screens_host/listing/listing_wizard_controller.dart';
import 'package:rent_home/ui/screens_host/listing/widgets/listing_section.dart';
import 'package:rent_home/ui/screens_host/listing/widgets/schema_field_input.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/utils/input_sanitizers.dart';
import 'package:rent_home/ui/screens_host/listing/components/location_picker_sheet.dart';
import 'package:rent_home/ui/screens_host/listing/components/state_city_fields.dart';
import 'package:rent_home/service/geocode_service.dart';
import 'package:rent_home/ui/screens_host/listing/components/agreement_block.dart';
import 'package:rent_home/utils/safe_bottom.dart';
import 'package:rent_home/ui/screens_renter/property_details/components/property_tabs.dart'
    show nearbyIcon;
import 'package:rent_home/ui/screens_host/listing/widgets/add_nearby_place.dart';

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
    //
    // A HOLD is the other way round. The step saved; what is missing is the
    // photographs, and they are at the BOTTOM of this step — scrolling to a
    // banner at the top would move the host away from the one thing they came
    // back for.
    if (c.heldHere.value.isNotEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(c.heldHere.value, style: inter(fontSize: 13.5)),
          backgroundColor: kClay,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
      return;
    }
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
        // Editing a live listing is an UPDATE, not an application.
        //
        // Both cases showed "we usually verify within 24-48 hours, and you
        // will be notified as soon as it is live" — told to a host whose
        // property has been live for weeks and who corrected a typo. It reads
        // as though they have just taken their own listing off the market.
        //
        // `c.isLive` is the same flag the wizard already uses to word the
        // submit button, and the server behaves accordingly too: an approved
        // listing keeps its tier and stays live while the change is reviewed.
        title: Text(c.isLive ? 'Changes submitted' : 'Sent for review',
            style: fraunces(
                fontSize: 19, fontWeight: FontWeight.w700, color: kInk)),
        content: Text(
          c.isLive
              ? 'Your listing stays live. We have let our team know it changed '
                  'so they can take a look, and your guests see the update now.'
              : 'Your listing is with our team. We usually verify within 24–48 hours, '
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
                          Text(
                              last
                                  ? (c.isLive
                                      ? 'Update listing'
                                      : 'Submit for review')
                                  // Named so the second press is a decision
                                  // rather than a confused re-tap of a button
                                  // that appeared to do nothing.
                                  : (c.step.value == 2 &&
                                          c.photoWarned.value &&
                                          c.photoGapReason != null
                                      ? 'Continue without photos'
                                      : 'Continue'),
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
            // Held to the rule printed directly above this field, which the
            // server enforces anyway -- so a host cannot type something they
            // will only be told about on submit.
            _text('property_name', 'Property name',
                required: true, formatters: AppInputFormatters.propertyName),
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
            // The map comes FIRST, because it is the control that fills every
            // field under it. Until now this wizard had no map at all: it
            // asked hosts to type the whole address and never captured a
            // coordinate, so a listing created on the app had no pin — and a
            // property with no pin is returned by no location search. It
            // existed in the catalogue and was invisible in the one place
            // guests look.
            _locationPin(),
            const SizedBox(height: 16),
            _text('country', 'Country'),
            // Picked from the reference tables, not typed. Free text here is
            // how the catalogue filled with "KURUKSHETRA" and thousands of
            // other junk labels — and a stay typed "hariyana" never appears
            // when a guest searches Haryana. Same source and same behaviour as
            // the website's StateCityFields.
            Obx(() => StateCityFields(
                  state: c.f['state']?.toString(),
                  city: c.f['city']?.toString(),
                  onState: (v) {
                    c.f['state'] = v;
                    c.fieldErrors.remove('state');
                  },
                  onCity: (v) {
                    c.f['city'] = v;
                    c.fieldErrors.remove('city');
                  },
                  stateError: c.fieldErrors['state'],
                  cityError: c.fieldErrors['city'],
                )),
            // C15 — the address and the map are describing two places.
            //
            // Every distance on the listing, every "stays near X" search it
            // answers, and the directions a guest actually follows come from
            // the PIN. The typed address is what they read before they book.
            // When those disagree the guest finds out on the day.
            Obx(() => c.addressMismatch == null
                ? const SizedBox.shrink()
                : _warn(c.addressMismatch!)),
            const SizedBox(height: 14),
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

        // "Do you own this property?" stood here — the same question as "Who
        // is listing this property?" at the top of this step, asked a second
        // time in different words, with nothing reconciling the two: a host
        // could answer Owner up there and No down here and the listing carried
        // both. host_type is the answer that means something, so is_owner is
        // derived from it on save. Removed on web the same day.

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
          sub: "How many people the place sleeps. Infants aren't counted — "
              "a cot isn't a bed.",
          children: [
            _numRow([
              _numField('max_adults', 'Maximum adults'),
              _numField('max_children', 'Children'),
            ]),
            _numRow([
              _numField('max_infants', 'Infants'),
              // Total guests is DERIVED, not asked — matching the website.
              // Adults + children; infants excluded.
              _derivedField('Total guests', c.derivedTotalGuests),
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
              // C14 — the Apartment Type names a bedroom count and step 1 asks
              // for one separately, on another screen. Nothing compared them,
              // so a listing could advertise a 2 BHK and sleep a party in one
              // room.
              if (c.bhkMismatch != null) _warn(c.bhkMismatch!),
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
              // `.toList()`, not `c.views` — do NOT "simplify" this back.
              //
              // Obx only subscribes to observables READ WHILE ITS BUILDER
              // RUNS. Handing the RxList itself to a child widget reads
              // nothing here; the `.contains()` then happens later, inside
              // OptionGroupPicker's own build, where nothing is listening. So
              // tapping a view updated the list and repainted nothing, and the
              // pills looked dead (APP #10). Every other picker on this page
              // reads its selection inline, which is why only this one broke.
              selected: c.views.toList(),
              onToggle: (v) => c.toggleIn(c.views, v),
            ),
          ],
        ),

        // What's around this property — the same picker the website has.
        //
        // The host is the EDITOR here, not the typist. Google is good at
        // "there is a temple 1.5km away" and bad at "which of these forty
        // places matter to someone staying here", so it suggests and the host
        // cuts. That is why unticking is exactly as easy as ticking.
        _NearbyPicker(controller: c),

        // The original distance grid stood here — one bare kilometre box per
        // well-known place type, with no name field, no position, and no
        // connection to the section a guest reads them under. Everything is
        // added inside its own section now: Google suggests, the host ticks,
        // and "Add a place" covers what Google has never heard of. Values
        // saved under the old grid are folded into their section on load, so a
        // host can see and change them rather than finding them frozen on
        // their listing. Client, 2026-09-10; same change on the website.

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
        // Weekend pricing — absent from this wizard until 2026-09-10.
        //
        // The web wizard has asked for a Friday/Saturday/Sunday rate since it
        // shipped and this one never did, so a host who listed from their
        // phone had no way to charge more at the weekend at all — and, once
        // the weekend negotiation ladder was added, no way to set that
        // either. The engine has read these columns all along.
        ListingSection(
          title: 'Weekend pricing',
          sub: 'Charge more on Friday, Saturday and Sunday nights.',
          children: [
            ListingToggle(
              label: 'Different on weekends',
              value: c.p4['weekend_pricing'] == true,
              onChanged: (v) => c.setP4('weekend_pricing', v),
            ),
            if (c.p4['weekend_pricing'] == true) ...[
              const SizedBox(height: 8),
              _p4Text('friday_price', 'Friday (₹)',
                  numeric: true,
                  help: 'Leave a day blank and it falls back to your nightly '
                      'rate.'),
              _p4Text('saturday_price', 'Saturday (₹)', numeric: true),
              _p4Text('sunday_price', 'Sunday (₹)', numeric: true),
              // The weekend's own negotiation ladder. Without it a Saturday
              // was judged against the MIDWEEK floor: the platform accepted
              // at the weekday ideal on a night the host prices higher.
              _p4Text('weekend_minimum_price', 'Weekend minimum (₹)',
                  required: true,
                  numeric: true,
                  help: 'The least you would take for a weekend night. '
                      'Guests never see it.'),
              _p4Text('weekend_ideal_price', 'Weekend ideal (₹)',
                  required: true,
                  numeric: true,
                  help: 'A weekend offer at or above this is accepted for you. '
                      'It must fit under your cheapest weekend rate, since one '
                      'pair covers all three days.'),
            ],
          ],
        ),
        ListingSection(
          title: 'Weekly & monthly price',
          sub: 'What a longer stay costs in total. A 12-night stay is charged '
              'as one week plus 5 nights.',
          children: [
            // The host states the PRICE, not a percentage.
            //
            // These fields replace "Weekly discount (%)" / "Monthly discount
            // (%)" as the thing that sets a long-stay price. A host thinks in
            // "a week costs 30,000", not "14.3% off"; the guest is shown the
            // percentage, worked out from the two totals, so both get the
            // number they care about. The discount fields still exist in the
            // database and are simply not applied — a stay must not get two
            // mechanisms at once.
            _p4Text('weekly_price', 'Weekly price (₹)',
                required: true,
                numeric: true,
                help: 'Total for a 7-night stay. Must be less than 7 nights '
                    'at your nightly rate — the guest is shown how much they '
                    'save.'),
            _p4Text('monthly_price', 'Monthly price (₹)',
                required: true,
                numeric: true,
                help: 'Total for a 28-night stay. A longer stay is charged as '
                    'whole months, then weeks, then the nights left over.'),
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
            // 'extra_guest_price', not 'extra_guest_fee'. Same fault again:
            // the save endpoint reads b.extra_guest_price and the draft
            // loader strips 'ppr_' from ppr_extra_guest_price, so both
            // directions wanted this name and the form used another.
            // ppr_extra_guest_price was NULL on every listing in the
            // database — the charge has never once been saved from the app.
            _p4Text('extra_guest_price', 'Extra guest fee (₹)', numeric: true),
          ],
        ),
        ListingSection(
          title: 'Your price range',
          sub: 'The least you would accept, and the price you are aiming for. '
              'Guests never see either — only the prices above.',
          children: [
            // Min / Ideal per period. All required: the engine CAN derive a
            // missing tier by scaling, but a derived number is a guess about
            // the host's own money, and no stay should be quoted — nor an
            // offer auto-accepted — on an assumption nobody made. Same rule
            // server-side in utils/pricingGrid.
            _p4Text('negotiation_minimum_price', 'Minimum per night (₹)',
                required: true,
                numeric: true,
                help: 'Your floor. Offers under it still reach you, marked as '
                    'below your minimum, so a quiet week stays yours to fill.'),
            _p4Text('negotiation_ideal_price', 'Ideal per night (₹)',
                required: true,
                numeric: true,
                help: 'Offers at or above this are accepted for you '
                    'automatically; anything lower comes to you to decide.'),
            _p4Text('weekly_minimum_price', 'Minimum for a week (₹)',
                required: true,
                numeric: true,
                help: 'The least you would take for a full 7 nights.'),
            _p4Text('weekly_ideal_price', 'Ideal for a week (₹)',
                required: true,
                numeric: true,
                help: 'Week-long offers at or above this are accepted for you.'),
            _p4Text('monthly_minimum_price', 'Minimum for a month (₹)',
                required: true,
                numeric: true,
                help: 'The least you would take for 28 nights.'),
            _p4Text('monthly_ideal_price', 'Ideal for a month (₹)',
                required: true,
                numeric: true,
                help: 'Month-long offers at or above this are accepted for you.'),
            _p4Text('advance_booking_discount', 'Pre-booking discount (%)',
                numeric: true,
                help: 'Optional. Off the total for stays booked well ahead. '
                    'Leave blank for none.'),
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
              Text(
                'Offers are judged against the price range you set above.',
                style: inter(fontSize: 12, color: kMuted),
              ),
            ],
          ],
        ),
        ListingSection(
          title: 'How guests book',
          children: [
            if (b.bookingTypes.isNotEmpty)
              _p4Choice('booking_type', 'Booking type', b.bookingTypes),
            // 'response_time_hours', not 'response_time'.
            //
            // The step-4 payload is a spread of `p4`, and the server reads
            // `response_time_hours` — so under the old key the answer was
            // posted, ignored and dropped, and the draft loader (which maps
            // pbr_response_time_hours → response_time_hours) could never fill
            // the control back in. Every host who listed from the app answered
            // this question into a void.
            if (b.responseTimes.isNotEmpty)
              _p4Choice('response_time_hours',
                  'How quickly do you usually reply?', b.responseTimes,
                  required: true,
                  help: 'Shown to guests waiting on a price offer, and the '
                      'time you have to approve a booking request.'),
            if (b.availability.isNotEmpty)
              _p4Choice('availability', 'Availability', b.availability),
            // Which months — the follow-up question "Seasonal" never had.
            //
            // The host could say their listing is seasonal and was never asked
            // which season, so the server had nothing to enforce and the
            // listing stayed bookable all year. Only shown for seasonal; it
            // means nothing for the other three answers.
            if (c.p4['availability'] == 'seasonal') _monthPicker(),
            if (b.earlyCheckin.isNotEmpty)
              _p4Choice('early_checkin', 'Early check-in', b.earlyCheckin),
            if (b.selfCheckinMethods.isNotEmpty)
              _p4Choice('self_checkin_method', 'Self check-in',
                  b.selfCheckinMethods),
            // 'min_stay_nights' / 'max_stay_nights', not 'min_nights' /
            // 'max_nights' — the THIRD instance of this fault on this one
            // step, after response_time_hours above and the pricing prefix in
            // the controller. The keys are the contract in both directions:
            // the save endpoint reads b.min_stay_nights, and the draft loader
            // strips 'pbr_' from pbr_min_stay_nights to get the same name. So
            // under the old key the host's answer was posted and dropped, the
            // field came back empty every time they reopened the listing —
            // "not updating even after updating multiple times" — and, because
            // nothing was ever stored, booking had no limit to enforce and
            // took a one-night stay on a property with a three-night minimum.
            _p4Text('min_stay_nights', 'Minimum nights', numeric: true),
            // C8 — blank HAS meant "no limit" since the field shipped, and 5
            // of the 6 live listings store NULL. Nothing said so, so a host
            // either typed a number they did not mean or left it blank not
            // knowing what blank did.
            _p4Text('max_stay_nights', 'Maximum nights',
                numeric: true,
                help: 'Leave blank for no limit — guests can book any length '
                    'of stay.'),
            // Neither of the next two existed in this wizard. The website has
            // had both since it shipped, so a host who listed from their phone
            // could not say they need warning before an arrival, nor refuse
            // same-day bookings — the listing simply took whatever the
            // permissive default gave them.
            _p4Text('minimum_notice_hours', 'Minimum notice (hours)',
                numeric: true,
                help: 'How much warning you need before a guest arrives. '
                    'Blank or 0 means none.'),
            // Absent entirely until now. The website has had both since the
            // wizard shipped; the app never asked, so a host who listed from
            // their phone had no way to say when guests may arrive or must
            // leave, and every screen that shows those times — the app's own
            // Property Details among them — displayed a dash for ever.
            // A PICKER, not a text box. These were free text, and a host
            // typing into them put "02:01" on a real listing — two minutes
            // past two in the morning, offered to guests as the hour they may
            // arrive, and measured from by the refund ladder. The website has
            // always used <input type="time">; this widget already exists here
            // for the schema's own `time` fields and was simply never used for
            // the two that matter most.
            _p4Time('checkin_time', 'Check-in time',
                help: 'When guests may arrive.'),
            _p4Time('checkout_time', 'Check-out time',
                help: 'When guests must leave.'),
            ListingToggle(
              label: 'Accept same-day bookings',
              value: c.p4['same_day_booking'] != false,
              onChanged: (v) => c.setP4('same_day_booking', v),
            ),
            // C7 — these two settings can cancel each other out.
            //
            // Saying yes to same-day and then asking for 24 hours' notice
            // means the earliest arrival the engine allows is tomorrow: the
            // notice is measured to the check-in time, so today can never
            // satisfy it. The host has switched same-day on and switched it
            // off again in the box above, and nothing told them.
            //
            // The guest side was never the problem — utils/bookingWindow
            // already sends a reason and both calendars print it. This is for
            // the host, who otherwise waits for bookings that cannot arrive.
            // A warning, not a block: "same-day, but give me a day's warning"
            // is a coherent thing to want, it just is not what these two
            // controls produce.
            if (c.p4['same_day_booking'] != false &&
                (int.tryParse('${c.p4['minimum_notice_hours'] ?? ''}') ?? 0) >= 24)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF6E5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        size: 15, color: kClay),
                    const SizedBox(width: 7),
                    // Expanded, or a 320dp screen breaks the sentence mid-word.
                    Expanded(
                      child: Text(
                        "${c.p4['minimum_notice_hours']} hours' notice means the earliest a "
                        'guest can arrive is tomorrow, so same-day bookings will never '
                        'actually happen. Lower the notice period below 24 hours if you '
                        'want them.',
                        style: inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: kClay,
                            height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
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
            // Moved off step 3 on 2026-09-10, along with the "Pets allowed?"
            // question that used to be asked in BOTH places and written to two
            // different records. Half the listings that answered both had them
            // disagreeing, and only this copy is the one guests and the search
            // filter read. One question, one screen, one answer.
            if (c.houseRules['pets_allowed'] == true)
              for (final f in s.petDetailFields)
                ListingToggle(
                  label: f.label,
                  value: c.houseRules[f.key] == true,
                  onChanged: (v) => c.toggleHouseRule(f.key, v),
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
                // 'identity_doc', not 'id_document'. The server reads
                // b.identity_doc; the old key was silently dropped, so the
                // upload landed in property_media and never reached
                // property_verification — the admin then saw "missing".
                value: c.p5['identity_doc']?.toString(),
                onPick: (file) => c.uploadDocument(file, 'identity_doc'),
                typeLabel: 'Document type',
                typeValue: c.p5['identity_type']?.toString(),
                typeOptions: const {
                  'aadhaar': 'Aadhaar Card',
                  'passport': 'Passport',
                  'driving_licence': 'Driving Licence',
                  'voter_id': 'Voter ID',
                },
                onType: (v) => c.setP5('identity_type', v),
              ),
            ],
          ),
        ListingSection(
          title: 'Property ownership',
          sub: 'One document proving you can list this property.',
          children: [
            _DocumentField(
              label: 'Ownership proof',
              // 'ownership_doc', not 'ownership_document' — same fault as the
              // identity field above, and the cause of APP #18 and the admin's
              // "Ownership document missing" on a listing that had one.
              value: c.p5['ownership_doc']?.toString(),
              onPick: (file) => c.uploadDocument(file, 'ownership_doc'),
              typeLabel: 'Document type',
              typeValue: c.p5['ownership_doc_type']?.toString(),
              // The same seven the website offers, same stored values.
              typeOptions: const {
                'electricity_bill': 'Electricity Bill',
                'property_tax': 'Property Tax',
                'sale_deed': 'Sale Deed',
                'lease_agreement': 'Lease Agreement',
                'rent_agreement': 'Rent Agreement',
                'homestay_registration': 'Homestay Registration',
                'municipal_record': 'Municipal Record',
              },
              onType: (v) => c.setP5('ownership_doc_type', v),
            ),
            // The owner's authorisation, for a listing put up by a MANAGER.
            //
            // Step 1 has asked a manager to CONFIRM they hold one since the
            // wizard shipped and blocked them if they said no, then never
            // asked for the document. The server now REFUSES a manager's
            // submission without it, so without this field a manager listing
            // from their phone would be blocked with no way to comply.
            if (c.f['host_type'] == 'manager')
              _DocumentField(
                label: "Owner's written authorisation",
                value: c.p5['authorization_doc']?.toString(),
                onPick: (file) => c.uploadDocument(file, 'authorization_doc'),
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
          sub: c.isLive
              ? 'Confirm these still hold for the updated listing.'
              : 'All of these are required before we can verify your listing.',
          children: [
            for (final d in kListingDeclarations)
              _DeclarationRow(
                label: d.value,
                value: c.declarations[d.key] == true,
                onChanged: (v) => c.toggleDeclaration(d.key, v),
              ),
          ],
        ),
        // The Host Agreement gets its own section: the text to read, then the
        // one checkbox the agreement itself specifies. It is not a
        // declaration row because a tick beside "I accept the Host Agreement"
        // — with nothing to read — is not acceptance of anything.
        ListingSection(
          title: 'Host Agreement',
          sub: 'Read the agreement, then accept it to publish.',
          children: [HostAgreementBlock(c: c)],
        ),
      ],
    );
  }

  // ── Small builders ────────────────────────────────────────────────────────

  Widget _fieldError(String msg) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(msg, style: inter(fontSize: 11.5, color: kDanger)),
      );

  /// A cross-field contradiction the host should look at, not be stopped by.
  ///
  /// Amber rather than red: nothing here is invalid, two answers simply
  /// disagree and only the host knows which one is wrong.
  Widget _warn(String text) => Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF6E5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 15, color: kClay),
            const SizedBox(width: 8),
            // Expanded, or a 320dp screen breaks the sentence mid-word.
            Expanded(
              child: Text(text,
                  style: inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kClay,
                      height: 1.35)),
            ),
          ],
        ),
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

  /// A read-only companion to [_numField], for a value the form computes.
  Widget _derivedField(String label, int value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: inter(fontSize: 12.5, color: kMuted)),
          const SizedBox(height: 6),
          Container(
            height: 48,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: kLine.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kLine),
            ),
            child: Text(
              value > 0 ? '$value' : '—',
              style: inter(
                  fontSize: 15, fontWeight: FontWeight.w600, color: kInk),
            ),
          ),
        ],
      );

  /// The map row: pick, or adjust a pin already set.
  Widget _locationPin() {
    return Obx(() {
      final lat = double.tryParse((c.f['latitude'] ?? '').toString());
      final lng = double.tryParse((c.f['longitude'] ?? '').toString());
      final hasPin = lat != null && lng != null && (lat != 0 || lng != 0);
      final city = (c.f['city'] ?? '').toString();
      final error = c.fieldErrors['location_pin'];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Location on map',
              style: inter(
                  fontSize: 13, fontWeight: FontWeight.w600, color: kInk)),
          const SizedBox(height: 8),
          if (hasPin)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: kLine),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.place_rounded,
                      size: 17, color: kprimaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      city.isEmpty
                          ? 'Pin set — guests will see this spot.'
                          : 'Pin set near $city — guests will see this spot.',
                      style: inter(fontSize: 12.5, color: kInk2),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _pickLocation(lat, lng),
                    child: Text('Adjust',
                        style: inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: kprimaryColor)),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _pickLocation(null, null),
                icon: const Icon(Icons.map_outlined, size: 18),
                label: Text('Pick the location on the map',
                    style: inter(
                        fontSize: 13.5, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kprimaryColor,
                  side: const BorderSide(color: kprimaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          if (!hasPin) ...[
            const SizedBox(height: 6),
            Text(
                "Drop the pin and we'll fill in the address below. You can "
                'correct anything afterwards.',
                style: inter(fontSize: 11.5, color: kMuted)),
          ],
          if (error != null) ...[
            const SizedBox(height: 6),
            Text(error, style: inter(fontSize: 11.5, color: kDanger)),
          ],
        ],
      );
    });
  }

  Future<void> _pickLocation(double? lat, double? lng) async {
    final picked = await showListingLocationPicker(context,
        initialLat: lat, initialLng: lng);
    if (picked == null || !mounted) return;
    _applyPickedLocation(picked);
  }

  /// Write a chosen pin into the form.
  ///
  /// Nudging the pin inside one town fills only what the lookup found, so a
  /// result with no street cannot wipe a street the host typed. MOVING it
  /// somewhere else replaces the address outright, empty included: merging
  /// across a move leaves the old town's district under the new town's name,
  /// and nothing on screen says which half is stale. Same rule as the website.
  void _applyPickedLocation(PickedAddress a) {
    String norm(String? v) => (v ?? '').trim().toLowerCase();
    final currentCity = (c.f['city'] ?? '').toString();
    final currentState = (c.f['state'] ?? '').toString();
    final moved = (a.city.isNotEmpty && norm(a.city) != norm(currentCity)) ||
        (a.state.isNotEmpty && norm(a.state) != norm(currentState));
    String take(String next, String current) =>
        moved ? next : (next.isNotEmpty ? next : current);

    c.f['latitude'] = a.lat.toString();
    c.f['longitude'] = a.lng.toString();
    // What the pin itself resolves to, kept so the address block can say when
    // the two stop agreeing. Fire-and-forget: a failed lookup costs a warning,
    // never a save.
    c.refreshPinPlace();
    c.f['state'] = take(a.state, currentState);
    c.f['city'] = take(a.city, currentCity);
    c.f['district'] = take(a.district, (c.f['district'] ?? '').toString());
    c.f['village'] = take(a.village, (c.f['village'] ?? '').toString());
    c.f['pincode'] = take(a.pincode, (c.f['pincode'] ?? '').toString());
    c.f['street_address'] =
        take(a.street, (c.f['street_address'] ?? '').toString());
    for (final k in const [
      'location_pin', 'state', 'city', 'district', 'village', 'pincode',
      'street_address'
    ]) {
      c.fieldErrors.remove(k);
    }
    // The address fields are plain text inputs that adopt a changed value on
    // rebuild, so the screen has to rebuild for the pin's answer to appear.
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(a.isEmpty
          ? 'Pin saved. Add the address below.'
          : 'Location set — address filled from the map.'),
    ));
  }

  Widget _text(
    String key,
    String label, {
    bool required = false,
    bool numeric = false,
    int? maxLength,
    int maxLines = 1,
    String? help,
    List<TextInputFormatter>? formatters,
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
      formatters: formatters,
      error: c.fieldErrors[key],
      onChanged: (v) => c.setF(key, v),
    );
  }

  /// The months a seasonal host takes bookings.
  ///
  /// Leaving every month off means no restriction, not "closed all year" —
  /// the same rule the server applies. Said in words under the label, because
  /// an empty picker is otherwise ambiguous in exactly the wrong direction.
  Widget _monthPicker() {
    const labels = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final chosen = <int>{
      ...((c.p4['open_months'] as List?)?.map((e) => int.tryParse('$e')).whereType<int>() ??
          const <int>[]),
    };
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Months you take bookings',
              style: inter(
                  fontSize: 13.5, fontWeight: FontWeight.w700, color: kInk)),
          const SizedBox(height: 2),
          Text(
            'Guests cannot book nights in the months you leave off. '
            'Choose none and your listing stays open all year.',
            style: inter(fontSize: 12, color: kMuted, height: 1.4),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < labels.length; i++)
                Builder(builder: (_) {
                  final month = i + 1;
                  final on = chosen.contains(month);
                  return GestureDetector(
                    onTap: () {
                      final next = {...chosen};
                      if (on) {
                        next.remove(month);
                      } else {
                        next.add(month);
                      }
                      final sorted = next.toList()..sort();
                      c.setP4('open_months', sorted);
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: on ? kIndigo : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: on ? kIndigo : kLine),
                      ),
                      child: Text(
                        labels[i],
                        style: inter(
                          fontSize: 13,
                          fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                          color: on ? Colors.white : kInk,
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ],
      ),
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

  /// A time of day, picked rather than typed. Stores 24-hour HH:mm, which is
  /// what the server keeps and what the website's <input type="time"> submits.
  Widget _p4Time(String key, String label, {String? help}) => SchemaFieldInput(
        field: SchemaField(
            key: key, label: label, type: FieldType.time, help: help),
        value: c.p4[key],
        onChanged: (k, v) => c.setP4(k, v),
        error: c.fieldErrors[key],
      );

  Widget _p4Choice(String key, String label, List<Option> options,
          {bool required = false, String? help}) =>
      SchemaFieldInput(
        field: SchemaField(
            key: key,
            label: label,
            type: FieldType.select,
            options: options,
            required: required,
            help: help),
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
                  colors: [Lux.surface, Lux.bg],
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
                          color: on ? Lux.ink : kInk)),
                  const SizedBox(height: 2),
                  Text(
                    on
                        ? 'This listing will appear in the LUXE collection.'
                        : 'Only for premium finishes, exceptional amenities '
                            'and prime locations.',
                    style: inter(
                        fontSize: 12,
                        color: on ? Lux.muted : kMuted,
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
      // Photographs, not verification documents — those come back in the same
      // list and used to be counted here AND drawn in the grid, so a host's
      // Aadhaar card sat among the bedrooms and stood in for one of them.
      final photos = controller.photos;
      final count = photos.length;
      // What THIS listing is held to: tiered by what is being let, then the
      // admin's per-category floor on top for a whole property. Read inside
      // the Obx so changing either re-evaluates it live.
      final rule = rules.ruleFor(
        controller.f['accommodation_type']?.toString(),
        controller.f['property_category']?.toString(),
      );
      final minimum = rule.minimum;
      String labelFor(String v) => rules.categories
          .firstWhere((c) => c.value == v,
              orElse: () => Option(value: v, label: v))
          .label;
      final tagged = photos
          .map((m) => m['category']?.toString() ?? '')
          .where((c) => c.isNotEmpty)
          .toSet();
      final missing = rule.required.where((r) => !tagged.contains(r)).toList();
      // Ready means PUBLISHABLE, which is the count and the tags together. It
      // used to mean the count alone, so twelve untagged photographs showed a
      // green tick over a listing the server would refuse.
      final ready = count >= minimum && missing.isEmpty;
      final needed = rule.required.map(labelFor).join(', ');
      return ListingSection(
        title: 'Photos',
        sub: 'At least $minimum, ${rules.recommended} recommended. '
            'The first one becomes your cover.'
            '${needed.isEmpty ? '' : ' Tag at least one as $needed.'}',
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$count of $minimum required photos added',
                        style: inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: ready ? kSuccess : kClay),
                      ),
                      if (missing.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          'Still to tag: ${missing.map(labelFor).join(', ')}',
                          style: inter(fontSize: 12, color: kClay),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (photos.isNotEmpty)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final m in photos)
                  _Thumb(
                    url: m['url']?.toString(),
                    // The tag, on the picture. Blank until the host says what
                    // the room is — and the required ones cannot be satisfied
                    // any other way from a phone.
                    category: m['category']?.toString(),
                    categoryLabel: (m['category']?.toString() ?? '').isEmpty
                        ? null
                        : labelFor(m['category'].toString()),
                    onRemove: () {
                      final id = m['id'];
                      if (id is num) controller.removePhoto(id.toInt());
                    },
                    onTag: () {
                      final id = m['id'];
                      if (id is num) {
                        _tag(context, id.toInt(), m['category']?.toString());
                      }
                    },
                  ),
              ],
            ),
          if (photos.isNotEmpty) const SizedBox(height: 12),
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

  /// Say what a photograph is OF.
  ///
  /// The app never had this. Every picture it uploaded went up untagged (the
  /// first one as the cover), and the code that did it said the rest stay
  /// "uncategorised until the host says otherwise on the website" — fine while
  /// tags were advisory, and impossible once publishing requires an exterior,
  /// a bedroom, a bathroom and an entrance. A host listing from their phone
  /// could add thirty photographs and never be allowed to publish, with
  /// nothing on the screen able to tell them why.
  Future<void> _tag(BuildContext context, int mediaId, String? current) async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What is this a photo of?',
                  style: inter(
                      fontSize: 15, fontWeight: FontWeight.w700, color: kInk)),
              const SizedBox(height: 4),
              Text(
                'Tagging one of each required kind is what lets the listing '
                'go live.',
                style: inter(fontSize: 12.5, color: kMuted, height: 1.35),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final option in rules.categories)
                        ChoiceChip(
                          label: Text(option.label,
                              style: inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: option.value == current
                                      ? Colors.white
                                      : kInk)),
                          selected: option.value == current,
                          selectedColor: kIndigo,
                          backgroundColor: kIndigo50,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)),
                          side: BorderSide.none,
                          onSelected: (_) =>
                              Navigator.pop(sheetContext, option.value),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
    if (chosen == null || chosen == current || !context.mounted) return;
    final problem = await controller.setPhotoCategory(mediaId, chosen);
    if (problem != null && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(problem)));
    }
  }

  Future<void> _pick(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 82);
    if (picked.isEmpty || !context.mounted) return;

    // Portrait photographs are refused before anything else happens — before
    // the host is asked to describe them, and long before an upload over
    // mobile data. The gallery lays out wide frames, and a tall picture in one
    // is letterboxed to a strip between two blank panels. The server enforces
    // the same rule against what Cloudinary reports; this is here so the host
    // finds out while they are still looking at the photograph.
    final verdicts = await Future.wait(
      picked.map((x) => checkLandscape(File(x.path))),
    );
    final rejected = verdicts.where((v) => !v.ok).toList();
    final keep = <XFile>[
      for (var i = 0; i < picked.length; i++)
        if (verdicts[i].ok) picked[i],
    ];
    if (!context.mounted) return;
    if (rejected.isNotEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(landscapeMessage(rejected))));
    }
    if (keep.isEmpty) return;

    // Asked BEFORE the upload, on purpose. A photo that is already saved is a
    // photo nobody comes back to describe — that is exactly why the library has
    // 54 images and no descriptions. The one moment a host is looking at the
    // picture is the only moment this question gets a real answer.
    final descriptions = await _describePhotos(context, keep);
    if (descriptions == null) return; // backed out

    final problem = await controller.uploadPhotos(
      keep.map((x) => File(x.path)).toList(),
      // The first photo of an empty listing is its cover; the rest are
      // uncategorised until the host says otherwise on the website.
      controller.media.isEmpty ? 'cover_photo' : '',
      alts: descriptions,
    );
    if (problem != null && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(problem)));
    }
  }

  /// One line per picture, with the picture on screen while it is written.
  ///
  /// Returns null when the host backs out, which abandons the upload — the
  /// alternative is uploading without descriptions, and a sheet that can be
  /// dismissed into the outcome it exists to prevent is decoration.
  Future<List<String>?> _describePhotos(
    BuildContext context,
    List<XFile> picked,
  ) {
    final controllers =
        List.generate(picked.length, (_) => TextEditingController());

    return showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final media = MediaQuery.of(sheetContext);
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final ready = controllers.every((c) => c.text.trim().isNotEmpty);
            return Padding(
              // Ride above the keyboard: this sheet is nothing but text fields,
              // and one covered by the keyboard cannot be filled in.
              padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: media.size.height -
                      media.viewInsets.bottom -
                      media.padding.top -
                      12,
                ),
                decoration: const BoxDecoration(
                  color: kSurface,
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                ),
                // Same as the map picker: the Upload button is the last thing
                // in this sheet, so it needs the navigation bar's room or it
                // sits behind it.
                padding: safeBottomInsets(sheetContext,
                    left: 18, top: 14, right: 18, bottom: 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: kLine,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      picked.length == 1
                          ? 'Describe this photo'
                          : 'Describe these ${picked.length} photos',
                      style: fraunces(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: kInk),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'One line each, saying what is actually in the picture. '
                      'It is read aloud to guests using a screen reader, and it '
                      'is how your photo is found in image search.',
                      style: inter(fontSize: 12.5, color: kMuted, height: 1.45),
                    ),
                    const SizedBox(height: 14),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: picked.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) => Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(picked[i].path),
                                width: 84,
                                height: 64,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: controllers[i],
                                onChanged: (_) => setSheetState(() {}),
                                maxLength: 125,
                                minLines: 1,
                                maxLines: 2,
                                style: inter(fontSize: 14, color: kInk),
                                decoration: InputDecoration(
                                  hintText:
                                      'Stone cottage with a pine forest behind it',
                                  hintStyle:
                                      inter(fontSize: 13, color: kMuted),
                                  isDense: true,
                                  counterText: '',
                                  filled: true,
                                  fillColor: kSand,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 11),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide:
                                        const BorderSide(color: kLine),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                        color: kIndigo, width: 1.5),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kMuted,
                              side: const BorderSide(color: kLine),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('Cancel',
                                style: inter(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            // Disabled until every one has something. The server
                            // decides whether it is any GOOD and names the photo
                            // if it is not.
                            onPressed: ready
                                ? () => Navigator.pop(
                                      sheetContext,
                                      controllers
                                          .map((c) => c.text.trim())
                                          .toList(),
                                    )
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kIndigo,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: kMuted,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              'Upload ${picked.length} photo${picked.length == 1 ? '' : 's'}',
                              style: inter(
                                  fontSize: 14.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      for (final c in controllers) {
        c.dispose();
      }
    });
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.url,
    required this.onRemove,
    this.category,
    this.categoryLabel,
    this.onTag,
  });

  final String? url;
  final VoidCallback onRemove;

  /// What this photograph is of, and the word for it. Null means untagged,
  /// which is what every photograph the app uploaded used to be.
  final String? category;
  final String? categoryLabel;
  final VoidCallback? onTag;

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
          // The tag, written on the picture and tappable. An untagged photo
          // says so rather than saying nothing: a blank strip reads as
          // decoration, and this is the control that unblocks publishing.
          if (onTag != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: onTag,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.58),
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          categoryLabel ?? 'Tag this',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: inter(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: categoryLabel == null
                                ? const Color(0xFFFFD9A0)
                                : Colors.white,
                          ),
                        ),
                      ),
                      const Icon(Icons.edit_outlined,
                          size: 11, color: Colors.white70),
                    ],
                  ),
                ),
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
///
/// A DOCUMENT picker, not a photo picker. This used ImagePicker, so a host
/// could only hand over a photo of their sale deed; the PDF the registrar
/// gave them was unselectable. The server has accepted PDFs for verification
/// documents all along (kind=document, resource_type auto) — the app was the
/// only thing refusing. Reported as APP #18, together with the missing
/// document-type choice the website has; both are here now.
class _DocumentField extends StatelessWidget {
  const _DocumentField({
    required this.label,
    required this.value,
    required this.onPick,
    this.typeLabel,
    this.typeValue,
    this.typeOptions,
    this.onType,
  });

  final String label;
  final String? value;
  final Future<String?> Function(File file) onPick;
  final String? typeLabel;
  final String? typeValue;
  final Map<String, String>? typeOptions;
  final void Function(String value)? onType;

  static const _extensions = ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'];

  @override
  Widget build(BuildContext context) {
    final has = value != null && value!.isNotEmpty;
    final options = typeOptions;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (options != null && options.isNotEmpty) ...[
            Text(typeLabel ?? 'Document type',
                style: inter(
                    fontSize: 13.5, fontWeight: FontWeight.w600, color: kInk)),
            const SizedBox(height: 7),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in options.entries)
                  ChoiceChip(
                    label: Text(e.value, style: inter(fontSize: 12.5)),
                    selected: typeValue == e.key,
                    selectedColor: kIndigo.withOpacity(0.14),
                    onSelected: (_) => onType?.call(e.key),
                  ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          Text(label,
              style: inter(
                  fontSize: 13.5, fontWeight: FontWeight.w600, color: kInk)),
          const SizedBox(height: 7),
          InkWell(
            onTap: () async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: _extensions,
              );
              final path = result?.files.single.path;
              if (path == null) return;
              final problem = await onPick(File(path));
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
            // Photographs BLOCK a first publication and only WARN on an
            // update: a listing that is already live stays live whether or not
            // its host is allowed to fix a typo today, so refusing the edit
            // would cost the correction and save nothing. Said anyway — a
            // listing with no photographs is still a listing with no
            // photographs.
            if (controller.readiness['photoWarning'] is String) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, size: 15, color: kClay),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      '${controller.readiness['photoWarning']} '
                      'Your listing stays live in the meantime.',
                      style: inter(fontSize: 12, color: kClay, height: 1.45),
                    ),
                  ),
                ],
              ),
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

/// The host's "what's around this property" picker.
///
/// Loads its suggestions when the host actually reaches the step — seven
/// sections is seven billed Google requests, and a host who only edits their
/// price should not pay for a lookup they never see.
class _NearbyPicker extends StatefulWidget {
  final ListingWizardController controller;
  const _NearbyPicker({required this.controller});

  @override
  State<_NearbyPicker> createState() => _NearbyPickerState();
}

class _NearbyPickerState extends State<_NearbyPicker> {
  @override
  void initState() {
    super.initState();
    // After the first frame: this runs during a build of the step, and
    // touching an Rx synchronously here would rebuild the tree mid-build.
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => widget.controller.loadNearbySuggestions());
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Obx(() {
      final state = c.nearbyState.value;
      final sections = c.nearbySuggestions;

      return ListingSection(
        title: "What's around this property",
        sub: 'Pick the places worth showing a guest. Tap to add or remove — '
            'only the sections you fill in appear on your listing.',
        children: [
          if (state == 'loading')
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text('Looking up places around your property…',
                  style: inter(fontSize: 13, color: kMuted)),
            ),
          if (state == 'off')
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                  "We couldn't find anything nearby right now — you can still "
                  'add places yourself below.',
                  style: inter(fontSize: 13, color: kMuted)),
            ),
          for (final sec in sections) ..._section(c, sec),
        ],
      );
    });
  }

  List<Widget> _section(ListingWizardController c, Map<String, dynamic> sec) {
    final key = '${sec['key']}';
    final places = (sec['places'] is List)
        ? List<Map<String, dynamic>>.from(
            (sec['places'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)))
        : <Map<String, dynamic>>[];

    // A place the host ticked that this refresh no longer returns still
    // belongs in the list and stays ticked. They chose it; a search result
    // changing is not a reason to drop their answer.
    final extras = c.nearbyPicked
        .where((p) =>
            p['section'] == key &&
            !places.any((o) =>
                '${o['name']}'.trim().toLowerCase() ==
                '${p['name']}'.trim().toLowerCase()))
        .toList();
    // Sorted by distance, suggestions and carried-over picks together.
    // Appending the extras left a 4.6km place sitting after the 12.8km ones,
    // which reads as a bug even though the list is right — the host has no way
    // to know one of those chips came from a previous session.
    final rows = [...places, ...extras]
      ..sort((a, b) => (double.tryParse('${a['km']}') ?? 0)
          .compareTo(double.tryParse('${b['km']}') ?? 0));
    // EVERY section renders, including the empty ones.
    //
    // It returned nothing when Google found nothing, so a host had no idea
    // "Getting There" or "Adventure & Activities" existed — the section that
    // most needs a human answer was the one most likely to be missing, and
    // the only way in was a separate grid of kilometre boxes further down.
    final chosen = c.nearbyPicked.where((p) => p['section'] == key).length;

    return [
      Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 2),
        child: Row(
          children: [
            Icon(nearbyIcon('${sec['icon']}'), size: 16, color: kIndigo600),
            const SizedBox(width: 6),
            Expanded(
              child: Text('${sec['label']}',
                  style: inter(fontSize: 13.5, fontWeight: FontWeight.w700, color: kInk)),
            ),
            Text(chosen > 0 ? '$chosen selected' : 'none selected',
                style: inter(fontSize: 11.5, color: kMuted)),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: rows.map((o) {
            final name = '${o['name']}';
            final on = c.isNearbyPicked(key, name);
            final km = double.tryParse('${o['km']}') ?? 0;
            return InkWell(
              onTap: () => c.toggleNearbyPlace({
                'section': key,
                'name': name,
                'km': km,
                'lat': o['lat'],
                'lng': o['lng'],
                'placeId': o['placeId'],
              }),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                decoration: BoxDecoration(
                  color: on ? kIndigo600 : Colors.transparent,
                  border: Border.all(color: on ? kIndigo600 : kLine),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(on ? Icons.check_rounded : Icons.add_rounded,
                        size: 14, color: on ? Colors.white : kMuted),
                    const SizedBox(width: 5),
                    // Constrained, or a long place name pushes the distance
                    // off the chip and the chip off the screen.
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 165),
                      child: Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: inter(
                              fontSize: 12.5,
                              color: on ? Colors.white : kInk)),
                    ),
                    const SizedBox(width: 6),
                    Text(km < 1 ? '${(km * 1000).round()} m' : '$km km',
                        style: inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: on ? Colors.white70 : kMuted)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
      if (rows.isEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            'Nothing found here. Add one yourself if there is something worth '
            'showing.',
            style: inter(fontSize: 12.5, color: kMuted),
          ),
        ),
      // The one thing Google cannot do: the family temple two villages over,
      // the viewpoint everyone local knows and nobody has added to Maps. Per
      // section, because a place belongs under a heading — the grid of bare
      // kilometre boxes this replaces sat further down the step with nowhere
      // to put the name.
      AddNearbyPlace(
        propertyLat: double.tryParse('${c.f['latitude'] ?? ''}'),
        propertyLng: double.tryParse('${c.f['longitude'] ?? ''}'),
        onAdd: (place) => c.addNearbyPlace(key, place),
      ),
      const SizedBox(height: 6),
    ];
  }
}
