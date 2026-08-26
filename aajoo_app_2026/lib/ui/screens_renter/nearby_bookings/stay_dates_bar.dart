import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/ui/screens_renter/home/components/lux_theme.dart';
import 'package:rent_home/utils/fonts.dart';

/// Check-in / check-out on the pre-booking screen.
///
/// Pre-booking had no date input at all: you browsed, opened a property, and
/// only then discovered you had to pick dates. Choosing them up here carries
/// them into the property page, so the stay is already priced when you arrive.
///
/// Dates are nights, so check-out is always at least the day after check-in —
/// picking the same day for both is not a zero-night stay, it is a mistake.
class StayDatesBar extends StatelessWidget {
  final DateTime? checkIn;
  final DateTime? checkOut;
  final bool isLuxury;
  final void Function(DateTime checkIn, DateTime checkOut) onChanged;
  final VoidCallback? onClear;

  const StayDatesBar({
    super.key,
    required this.onChanged,
    this.checkIn,
    this.checkOut,
    this.isLuxury = false,
    this.onClear,
  });

  static String fmt(DateTime d) => DateFormat('d MMM').format(d);

  /// DD-MM-YYYY, the format the booking API takes.
  static String api(DateTime d) => DateFormat('dd-MM-yyyy').format(d);

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial = (checkIn != null && checkOut != null)
        ? DateTimeRange(start: checkIn!, end: checkOut!)
        : null;

    final range = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      initialDateRange: initial,
      helpText: 'Select your stay',
      saveText: 'Done',
      builder: (context, child) {
        final base = Theme.of(context);
        return Theme(
          data: base.copyWith(
            colorScheme: isLuxury
                ? const ColorScheme.dark(
                    primary: Lux.gold,
                    onPrimary: Lux.onGold,
                    surface: Lux.surface,
                    onSurface: Lux.ink,
                  )
                : const ColorScheme.light(primary: kIndigo),
          ),
          child: child!,
        );
      },
    );
    if (range == null) return;

    // A same-day range is zero nights. Push check-out out by one rather than
    // handing the booking flow a range it will reject later.
    final end = range.end.isAfter(range.start)
        ? range.end
        : range.start.add(const Duration(days: 1));
    onChanged(range.start, end);
  }

  @override
  Widget build(BuildContext context) {
    final has = checkIn != null && checkOut != null;
    final nights = has ? checkOut!.difference(checkIn!).inDays : 0;

    return InkWell(
      onTap: () => _pick(context),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isLuxury ? Lux.surface : kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isLuxury ? Lux.line : kLine),
        ),
        child: Row(
          children: [
            Icon(
              isLuxury ? Lux.icon(Icons.calendar_today_outlined) : Icons.calendar_today_outlined,
              size: 18,
              color: isLuxury ? Lux.gold : kIndigo,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    has ? '${fmt(checkIn!)}  →  ${fmt(checkOut!)}' : 'Add dates',
                    style: inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isLuxury ? Lux.ink : kInk,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    has
                        ? '$nights night${nights == 1 ? '' : 's'}'
                        : 'Check-in and check-out',
                    style: inter(
                        fontSize: 11.5,
                        color: isLuxury ? Lux.muted : kMuted),
                  ),
                ],
              ),
            ),
            if (has && onClear != null)
              IconButton(
                onPressed: onClear,
                visualDensity: VisualDensity.compact,
                tooltip: 'Clear dates',
                icon: Icon(Icons.close,
                    size: 16, color: isLuxury ? Lux.muted : kMuted),
              )
            else
              Icon(Icons.chevron_right,
                  size: 18, color: isLuxury ? Lux.muted : kMuted),
          ],
        ),
      ),
    );
  }
}
