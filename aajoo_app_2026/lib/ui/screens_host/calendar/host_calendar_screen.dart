import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ionicons/ionicons.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/models/host_calendar_model.dart';
import 'package:rent_home/models/host_properties_reponse.dart';
import 'package:rent_home/service/device_service.dart';
import 'package:rent_home/ui/motion/aajoo_motion.dart';
import 'package:rent_home/ui/screens_host/calendar/host_calendar_controller.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/utils/stay_clock.dart';
import 'package:rent_home/widgets/app_ui.dart';

/// Host calendar — who is staying, what the host has closed off, what is open.
///
/// The app had no calendar at all: a host could see a flat list of bookings but
/// never a month, could not tell which guest sat on which date, and had no way
/// to take dates off the market for a booking made outside Aajoo. This reads
/// /host/calendar (stays + manual blocks in one call) and writes back through
/// /host/calendar/block and /unblock.
///
/// Wash colours: teal for a booking, amber for a host block. Amber never
/// carries white text — kInk on kClay is 6.77:1 where white is 2.17:1.
class HostCalendarScreen extends StatefulWidget {
  const HostCalendarScreen({super.key});

  @override
  State<HostCalendarScreen> createState() => _HostCalendarScreenState();
}

class _HostCalendarScreenState extends State<HostCalendarScreen> {
  late final HostCalendarController c;
  final TextEditingController _reason = TextEditingController();

  /// Amber at a wash strength — a block must read as "not on sale" without
  /// shouting like an error.
  static const Color _blockWash = Color(0xFFFDF3E0);

  @override
  void initState() {
    super.initState();
    c = Get.put(HostCalendarController());
  }

  @override
  void dispose() {
    _reason.dispose();
    Get.delete<HostCalendarController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kscaffoldColor,
      appBar: AppBar(
        backgroundColor: kCream,
        foregroundColor: kInk,
        elevation: 0,
        centerTitle: true,
        title: Text('Calendar',
            style:
                fraunces(fontSize: 18, fontWeight: FontWeight.w600, color: kInk)),
      ),
      body: RefreshIndicator(
        color: kIndigo,
        // With no listing chosen there is no calendar to refresh, and that is
        // exactly the state a failed listings call leaves behind — so the pull
        // has to retry the thing that actually failed.
        onRefresh: () => c.property.value == null
            ? c.loadProperties(q: c.query.value)
            : c.loadCalendar(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
          children: [
            // R2 — the listing picker sits at the top, above everything it
            // decides the contents of.
            Obx(() => _pickerBar()),
            const SizedBox(height: 14),
            Obx(() => _monthCard()),
            const SizedBox(height: 14),
            Obx(() => _agenda()),
          ],
        ),
      ),
    );
  }

  // ── Listing picker ─────────────────────────────────────────────────────────

  Widget _pickerBar() {
    final p = c.property.value;
    final total = c.propertyTotal.value;

    String title;
    if (p != null) {
      title = p.propertyName.trim().isEmpty
          ? 'Property ${p.propertyId}'
          : p.propertyName;
    } else if (c.propertiesLoading.value) {
      title = 'Loading your listings…';
    } else if (c.propertiesError.value.isNotEmpty) {
      title = "Couldn't load your listings";
    } else {
      title = 'No listings yet';
    }

    final subtitle = p != null
        ? [p.propertyCity, if (total > 1) '$total listings']
            .where((s) => s.trim().isNotEmpty)
            .join(' · ')
        : c.propertiesError.value.isNotEmpty
            ? c.propertiesError.value
            : 'Tap to choose a listing';

    return Material(
      color: kSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _openPropertySheet,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: kLine),
          ),
          child: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                    color: kIndigo50, borderRadius: BorderRadius.circular(11)),
                child: const Icon(Ionicons.home_outline,
                    size: 19, color: kIndigo600),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Listing',
                        style: inter(fontSize: 11.5, color: kMuted)),
                    const SizedBox(height: 2),
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: kInk)),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: inter(fontSize: 12, color: kMuted)),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.unfold_more, size: 18, color: kMuted),
            ],
          ),
        ),
      ),
    );
  }

  /// A searchable sheet, not a dropdown: /host/property-search is paginated at
  /// 20 a page and the test host owns 29,230 listings, so a dropdown could only
  /// ever show an arbitrary first slice with no way to reach the rest.
  void _openPropertySheet() {
    final search = TextEditingController(text: c.query.value);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
          child: ConstrainedBox(
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetContext).size.height * 0.8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                  child: Row(
                    children: [
                      Text('Choose a listing',
                          style: fraunces(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: kInk)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: kInk2),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: TextField(
                    controller: search,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (v) => c.loadProperties(q: v),
                    inputFormatters: [LengthLimitingTextInputFormatter(60)],
                    style: inter(fontSize: 14, color: kInk),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: kSurface,
                      hintText: 'Search your listings by name',
                      hintStyle: inter(fontSize: 13, color: kMuted),
                      prefixIcon: const Icon(Icons.search, size: 19, color: kMuted),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.arrow_forward, size: 18, color: kIndigo600),
                        onPressed: () => c.loadProperties(q: search.text),
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: kLine)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: kLine)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: kIndigo, width: 1.5)),
                    ),
                  ),
                ),
                const Divider(color: kLine, height: 1),
                Flexible(child: Obx(() => _propertyList(sheetContext))),
              ],
            ),
          ),
        ),
      ),
    ).whenComplete(search.dispose);
  }

  Widget _propertyList(BuildContext sheetContext) {
    if (c.propertiesLoading.value) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: kIndigo)),
      );
    }
    if (c.propertiesError.value.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: _errorBox(
          c.propertiesError.value,
          'Your listings could not be loaded, so there is nothing to choose from.',
          () => c.loadProperties(q: c.query.value),
        ),
      );
    }

    final selected = c.property.value;
    // Read here rather than only inside itemBuilder: a lazily-built list item
    // runs during layout, outside the Obx that is watching, so the button would
    // never redraw as "Loading…".
    final loadingMore = c.propertiesLoadingMore.value;
    // The current selection stays reachable even when a search has scrolled it
    // out of the result set — losing it would strand the host on a calendar
    // they can no longer name.
    final rows = <Property>[
      if (selected != null &&
          !c.properties.any((p) => p.propertyId == selected.propertyId))
        selected,
      ...c.properties,
    ];

    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: EmptyState(
          icon: Ionicons.home_outline,
          title: c.query.value.isEmpty
              ? 'No listings yet'
              : 'No listing matches “${c.query.value}”',
          subtitle: c.query.value.isEmpty
              ? 'Add a property and its calendar appears here.'
              : 'Try a different name.',
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      itemCount: rows.length + (c.hasMoreProperties ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, index) {
        if (index == rows.length) {
          return Center(
            child: TextButton(
              onPressed: loadingMore ? null : c.loadMoreProperties,
              child: Text(
                  loadingMore
                      ? 'Loading…'
                      : 'Load more (${c.properties.length} of ${c.propertyTotal.value})',
                  style: inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kIndigo600)),
            ),
          );
        }

        final p = rows[index];
        final isSelected = selected?.propertyId == p.propertyId;
        return Material(
          color: isSelected ? kIndigo50 : kSurface,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              // The reason belongs to the range it was typed for, and
              // selectProperty drops that range. Leaving the text behind would
              // file "Renovation" against a listing that is not being
              // renovated — the controller cannot reach this field, so it is
              // cleared at the one place the listing changes.
              if (c.property.value?.propertyId != p.propertyId) _reason.clear();
              c.selectProperty(p);
              Navigator.of(sheetContext).pop();
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? kIndigo : kLine),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            p.propertyName.trim().isEmpty
                                ? 'Property ${p.propertyId}'
                                : p.propertyName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: kInk)),
                        const SizedBox(height: 2),
                        Text(
                            [p.propertyCity, p.propertyState]
                                .where((s) => s.trim().isNotEmpty)
                                .join(', '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: inter(fontSize: 12, color: kMuted)),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_circle, size: 19, color: kIndigo600),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Month card ─────────────────────────────────────────────────────────────

  Widget _monthCard() {
    final cursor = c.cursor.value;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(DateFormat('MMMM y').format(cursor),
                    style: fraunces(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        color: kInk)),
              ),
              _monthStep(Icons.chevron_left, 'Previous month', () => c.stepMonth(-1)),
              const SizedBox(width: 8),
              _monthStep(Icons.chevron_right, 'Next month', () => c.stepMonth(1)),
            ],
          ),
          const SizedBox(height: 14),
          _monthBody(),
        ],
      ),
    );
  }

  Widget _monthStep(IconData icon, String tooltip, VoidCallback onTap) {
    return Material(
      color: kSurface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          height: 34,
          width: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kLine),
          ),
          child: Tooltip(
              message: tooltip, child: Icon(icon, size: 20, color: kInk2)),
        ),
      ),
    );
  }

  Widget _monthBody() {
    if (c.property.value == null) {
      return _notice(c.propertiesLoading.value
          ? 'Loading your listings…'
          : c.propertiesError.value.isNotEmpty
              ? c.propertiesError.value
              : 'Pick a listing to see its calendar.');
    }
    if (c.loading.value) {
      return _notice('Loading calendar…');
    }
    if (c.error.value.isNotEmpty) {
      // An empty grid would claim the whole month is free, so the month is not
      // drawn at all until this succeeds.
      return _errorBox(
        c.error.value,
        "Nothing below is trustworthy until this loads, so the month isn't shown.",
        c.loadCalendar,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _selectionBar(),
        const SizedBox(height: 14),
        _grid(),
        const SizedBox(height: 16),
        _legend(),
      ],
    );
  }

  Widget _notice(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(text,
              textAlign: TextAlign.center,
              style: inter(fontSize: 13.5, color: kMuted)),
        ),
      );

  Widget _errorBox(String message, String detail, VoidCallback onRetry) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kDanger.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kDanger.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline, size: 17, color: kDanger),
              const SizedBox(width: 8),
              Expanded(
                child: Text(message,
                    style: inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: kDanger)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(detail, style: inter(fontSize: 12.5, color: kMuted)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            style: OutlinedButton.styleFrom(
              foregroundColor: kInk,
              side: const BorderSide(color: kLine),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            label: Text('Retry',
                style: inter(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ── The pending block ──────────────────────────────────────────────────────

  Widget _selectionBar() {
    if (!c.hasSelection) {
      return Row(
        children: [
          const Icon(Icons.info_outline, size: 15, color: kMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
                'Tap a free day to start a block, then a second day to close the range.',
                style: inter(fontSize: 12.5, color: kMuted)),
          ),
        ],
      );
    }

    final from = c.selFrom.value;
    final to = c.selectionEnd;
    final open = c.selTo.value.isEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kIndigo50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kIndigo),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              open
                  ? '${_dayLabel(from)} — tap another day to extend the range'
                  : '${_dayLabel(from)} → ${_dayLabel(to)} · ${isoDayCount(from, to)} days',
              style: inter(
                  fontSize: 13, fontWeight: FontWeight.w700, color: kInk)),
          const SizedBox(height: 10),
          TextField(
            controller: _reason,
            // Capped so a long note is prevented rather than rejected after the
            // host has finished typing it; the column takes 255.
            inputFormatters: [LengthLimitingTextInputFormatter(120)],
            style: inter(fontSize: 13.5, color: kInk),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: kSurface,
              labelText: 'Reason (optional)',
              labelStyle: inter(fontSize: 12.5, color: kMuted),
              hintText: 'Maintenance, personal use…',
              hintStyle: inter(fontSize: 12.5, color: kMuted),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: kLine)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: kLine)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: kIndigo, width: 1.5)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              TextButton(
                onPressed: c.saving.value
                    ? null
                    : () {
                        c.clearSelection();
                        _reason.clear();
                      },
                child: Text('Clear',
                    style: inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: kInk2)),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: c.saving.value
                      ? null
                      : () async {
                          final ok = await c.blockSelectedDates(_reason.text);
                          if (ok) _reason.clear();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kIndigo,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.lock_outline, size: 16),
                  label: Text(c.saving.value ? 'Blocking…' : 'Block these dates',
                      style:
                          inter(fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          if (c.blockError.value.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 16, color: kDanger),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(c.blockError.value,
                      style: inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: kDanger)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── The month grid ─────────────────────────────────────────────────────────

  Widget _grid() {
    // One entry per occupied day, so a cell is a map lookup rather than a scan
    // of every stay on the listing.
    final stayByDay = <String, HostCalendarStay>{};
    for (final s in c.stays) {
      // Nights, not days: the checkout day is on sale again and must stay free
      // to tap, both so the host can read the month truthfully and so they can
      // close that day themselves. Back-to-back stays therefore hand the day
      // to whoever checks in, which is who is actually in the property.
      eachStayNight(s.from, s.to, (k) => stayByDay[k] = s);
    }
    final blockByDay = <String, HostCalendarBlock>{};
    for (final b in c.blocks) {
      eachIsoDay(b.from, b.to, (k) => blockByDay[k] = b);
    }

    final cursor = c.cursor.value;
    final daysInMonth = DateTime(cursor.year, cursor.month + 1, 0).day;
    // Dart weekdays run Mon=1…Sun=7; the grid starts on Sunday.
    final lead = DateTime(cursor.year, cursor.month, 1).weekday % 7;
    final todayKey = toIsoDate(DateTime.now());

    return Column(
      children: [
        Row(
          children: [
            for (final d in const ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'])
              Expanded(
                child: Center(
                  child: Text(d,
                      style: inter(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: kMuted)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 5,
            crossAxisSpacing: 5,
            childAspectRatio: 0.82,
          ),
          itemCount: lead + daysInMonth,
          itemBuilder: (_, index) {
            if (index < lead) return const SizedBox.shrink();
            final day = index - lead + 1;
            final key = toIsoDate(DateTime(cursor.year, cursor.month, day));
            final stay = stayByDay[key];
            // A booking wins the cell if a block somehow overlaps it — the stay
            // is the thing the host must not miss.
            final block = stay == null ? blockByDay[key] : null;
            return _dayCell(
              day: day,
              iso: key,
              stay: stay,
              block: block,
              isToday: key == todayKey,
              picked: c.isInSelection(key),
            );
          },
        ),
      ],
    );
  }

  Widget _dayCell({
    required int day,
    required String iso,
    required HostCalendarStay? stay,
    required HostCalendarBlock? block,
    required bool isToday,
    required bool picked,
  }) {
    final Color background = stay != null
        ? kIndigo50
        : block != null
            ? _blockWash
            : kSurface;
    final Color edge = stay != null
        ? kIndigo.withOpacity(0.4)
        : block != null
            ? kClay.withOpacity(0.55)
            : kLine;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          // A booked or blocked day explains itself; only free days feed the
          // range picker.
          if (stay != null) {
            _showStaySheet(stay);
          } else if (block != null) {
            _showBlockSheet(block);
          } else {
            c.tapFreeDay(iso);
          }
        },
        child: Container(
          // The selection ring eats a pixel of padding so a picked cell keeps
          // the same footprint as its neighbours.
          padding: EdgeInsets.all(picked ? 3 : 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: picked
                ? Border.all(color: kIndigo600, width: 2)
                : Border.all(color: edge),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$day',
                  style: inter(
                      fontSize: 12,
                      fontWeight:
                          isToday ? FontWeight.w800 : FontWeight.w600,
                      color: isToday ? kIndigo600 : kInk)),
              const Spacer(),
              if (stay != null)
                _dayBar(kIndigo)
              else if (block != null)
                _dayBar(kClay),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dayBar(Color color) => Container(
        height: 5,
        width: double.infinity,
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(99)),
      );

  Widget _legend() {
    Widget swatch(Color fill, Color edge, Color? bar, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: edge),
              ),
              child: bar == null
                  ? null
                  : Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                          height: 4,
                          margin: const EdgeInsets.all(1.5),
                          decoration: BoxDecoration(
                              color: bar,
                              borderRadius: BorderRadius.circular(99))),
                    ),
            ),
            const SizedBox(width: 6),
            Text(label, style: inter(fontSize: 12, color: kInk2)),
          ],
        );

    return Wrap(
      spacing: 18,
      runSpacing: 8,
      children: [
        swatch(kIndigo50, kIndigo.withOpacity(0.4), kIndigo, 'Booked'),
        swatch(_blockWash, kClay.withOpacity(0.55), kClay, 'Blocked'),
        swatch(kSurface, kLine, null, 'Available'),
      ],
    );
  }

  // ── This month, as a list ──────────────────────────────────────────────────

  /// The grid can only afford a coloured bar per day on a phone, so the guest
  /// on a date would otherwise be a tap away with nothing to say it is there.
  Widget _agenda() {
    if (c.property.value == null ||
        c.loading.value ||
        c.error.value.isNotEmpty) {
      return const SizedBox.shrink();
    }

    final cursor = c.cursor.value;
    final monthStart = toIsoDate(DateTime(cursor.year, cursor.month, 1));
    final monthEnd =
        toIsoDate(DateTime(cursor.year, cursor.month + 1, 0));
    // A block covers whole days inclusively; a stay covers nights, so one
    // checking out on the 1st occupies nothing this month and paints no cell —
    // listing it here would put a row in the agenda with no day to point at.
    bool blockInMonth(String from, String to) =>
        from.compareTo(monthEnd) <= 0 && to.compareTo(monthStart) >= 0;
    bool stayInMonth(String from, String to) =>
        from.compareTo(monthEnd) <= 0 && to.compareTo(monthStart) > 0;

    final stays = c.stays.where((s) => stayInMonth(s.from, s.to)).toList()
      ..sort((a, b) => a.from.compareTo(b.from));
    final blocks = c.blocks.where((b) => blockInMonth(b.from, b.to)).toList()
      ..sort((a, b) => a.from.compareTo(b.from));

    if (stays.isEmpty && blocks.isEmpty) {
      return AppCard(
        child: Row(
          children: [
            const Icon(Icons.event_available_outlined, size: 19, color: kMuted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                  'Nothing booked or blocked in ${DateFormat('MMMM').format(cursor)} — every date is open.',
                  style: inter(fontSize: 13, color: kMuted)),
            ),
          ],
        ),
      );
    }

    var i = 0;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle('${DateFormat('MMMM').format(cursor)} at a glance'),
          const SizedBox(height: 12),
          ...withDividers([
            for (final s in stays)
              Reveal(
                delay: Reveal.staggerDelay(i++),
                child: _agendaRow(
                  icon: Ionicons.person_outline,
                  tint: kIndigo,
                  title: s.guestName.trim().isEmpty ? 'Guest' : s.guestName,
                  subtitle:
                      '${_dayLabel(s.from)} → ${_dayLabel(s.to)}${s.bookingId.isEmpty ? '' : ' · ${s.bookingId}'}',
                  onTap: () => _showStaySheet(s),
                ),
              ),
            for (final b in blocks)
              Reveal(
                delay: Reveal.staggerDelay(i++),
                child: _agendaRow(
                  icon: Icons.lock_outline,
                  tint: kClay,
                  title: b.reason.trim().isEmpty ? 'Blocked' : b.reason,
                  subtitle: '${_dayLabel(b.from)} → ${_dayLabel(b.to)}',
                  onTap: () => _showBlockSheet(b),
                ),
              ),
          ]),
        ],
      ),
    );
  }

  Widget _agendaRow({
    required IconData icon,
    required Color tint,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: tint.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: tint),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: kInk)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: inter(fontSize: 12, color: kMuted)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 13, color: kMuted),
          ],
        ),
      ),
    );
  }

  // ── Detail sheets ──────────────────────────────────────────────────────────

  void _sheet({
    required String title,
    required List<Widget> Function(BuildContext sheetContext) children,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: kCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.8),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(title,
                          style: fraunces(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: kInk)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: kInk2),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ...children(sheetContext),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showStaySheet(HostCalendarStay stay) {
    final phone = stay.guestPhone.trim();
    _sheet(
      title: stay.guestName.trim().isEmpty ? 'Guest' : stay.guestName,
      children: (_) => [
        AppPill(
          stay.status.trim().isEmpty
              ? (stay.paid ? 'Paid' : 'Unpaid')
              : stay.status.trim(),
          stay.paid ? kSuccess : kClay600,
        ),
        const SizedBox(height: 14),
        KvRow('Booking', stay.bookingId.isEmpty ? '—' : stay.bookingId),
        KvRow('Dates', '${_dayLabel(stay.from)} → ${_dayLabel(stay.to)}'),
        KvRow('Nights', '${stayNights(stay.from, stay.to)}'),
        KvRow('Amount', stay.amount.isEmpty ? '—' : '₹ ${stay.amount}'),
        KvRow('Payment', stay.paid ? 'Paid' : 'Not paid yet',
            valueColor: stay.paid ? kSuccess : kClay600),
        const SizedBox(height: 14),
        if (phone.isEmpty)
          const KvRow('Phone', '—')
        else
          OutlinedButton.icon(
            onPressed: () => DeviceService.launchDialPad(phone),
            icon: const Icon(Icons.call_outlined, size: 17),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 46),
              foregroundColor: kIndigo600,
              side: const BorderSide(color: kIndigo),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            label: Text('Call $phone',
                style: inter(fontSize: 14, fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }

  void _showBlockSheet(HostCalendarBlock block) {
    _sheet(
      title: 'Blocked dates',
      children: (sheetContext) => [
        Text('Guests cannot book these dates.',
            style: inter(fontSize: 13, color: kMuted)),
        const SizedBox(height: 12),
        KvRow('Dates', '${_dayLabel(block.from)} → ${_dayLabel(block.to)}'),
        KvRow('Length', '${isoDayCount(block.from, block.to)} days'),
        KvRow('Reason', block.reason.trim().isEmpty ? '—' : block.reason),
        const SizedBox(height: 16),
        Obx(() => OutlinedButton.icon(
              onPressed: c.saving.value
                  ? null
                  : () async {
                      Navigator.of(sheetContext).pop();
                      await c.unblock(block);
                    },
              icon: const Icon(Icons.lock_open_outlined, size: 17),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                foregroundColor: kInk,
                side: const BorderSide(color: kLine),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              label: Text(c.saving.value ? 'Working…' : 'Unblock these dates',
                  style: inter(fontSize: 14, fontWeight: FontWeight.w700)),
            )),
      ],
    );
  }

  String _dayLabel(String iso) {
    final d = parseIsoDate(iso);
    return d == null ? iso : DateFormat('dd MMM yyyy').format(d);
  }
}
