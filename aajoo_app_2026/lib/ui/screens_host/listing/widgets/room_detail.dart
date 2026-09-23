import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/models/listing_schema.dart';
import 'package:rent_home/ui/screens_host/listing/listing_icons.dart';
import 'package:rent_home/ui/screens_host/listing/widgets/schema_field_input.dart';
import 'package:rent_home/utils/fonts.dart';

// Per-room detail on step 1 — which bedroom, what bed, whose bathroom.
//
// The app's half of the website's components/RoomDetail.tsx. Same rule, same
// vocabulary off the same endpoint, same optionality.
//
// THE COUNT DRIVES THE LIST. There is no Add and no Remove here, and that is
// the point rather than an omission: the host types 3 in Bedrooms and gets
// three cards. A list they can grow independently is a listing whose number
// says 3 while its detail describes 4, with nothing deciding which is true —
// search filters on the number and the guest page prints the list. The server
// enforces the same rule, because a rule enforced in one client is a rule the
// other client breaks.
//
// Everything here is OPTIONAL and nothing here can block a step. A host who
// wants to type three numbers and move on still can.

/// A pill row. Re-tapping the chosen pill clears it — none of this is
/// required, so a host who tapped by accident needs a way back to unanswered.
class _RoomPills extends StatelessWidget {
  const _RoomPills({
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<Option> options;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final o in options)
          ListingPill(
            label: o.label,
            selected: value == o.value,
            icon: iconForAmenity(o.label, 'bedroom'),
            onTap: () => onChanged(value == o.value ? null : o.value),
          ),
      ],
    );
  }
}

/// The beds in one room: tap a type to add one, tap again to add another.
///
/// A stepper per bed type would be eight rows of controls for a question most
/// rooms answer with one tap. Tapping accumulates and the count rides on the
/// pill, so "Queen ×2" is two taps and reads back at a glance.
///
/// Taking one back needs a control you can SEE. Removing used to be long-press
/// only, which is no affordance at all: the tester reported "I can only
/// increase counts of beds like king, queen ... I cannot go back and close it
/// like the web". So a chosen type now carries a visible − that takes one off
/// and removes the type at zero — the same control, in the same place, as the
/// website's RoomDetail.
class _Beds extends StatelessWidget {
  const _Beds({
    required this.types,
    required this.beds,
    required this.maxCount,
    required this.onChanged,
  });

  final List<Option> types;
  final List<BedEntry> beds;
  final int maxCount;
  final ValueChanged<List<BedEntry>> onChanged;

  int _countOf(String type) {
    for (final b in beds) {
      if (b.type == type) return b.count;
    }
    return 0;
  }

  void _add(String type) {
    final current = _countOf(type);
    if (current >= maxCount) return;
    if (current == 0) {
      onChanged([...beds, BedEntry(type: type, count: 1)]);
      return;
    }
    onChanged([
      for (final b in beds)
        if (b.type == type) b.copyWith(count: b.count + 1) else b,
    ]);
  }

  /// One fewer of this type; the type itself goes when the last one does.
  void _removeOne(String type) {
    final current = _countOf(type);
    if (current <= 1) {
      onChanged([for (final b in beds) if (b.type != type) b]);
      return;
    }
    onChanged([
      for (final b in beds)
        if (b.type == type) b.copyWith(count: b.count - 1) else b,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Beds in this room',
            style: inter(fontSize: 12.5, color: kMuted)),
        const SizedBox(height: 7),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in types)
              Builder(builder: (_) {
                final n = _countOf(o.value);
                // The remove control is drawn only for a type that HAS beds, so
                // an untouched row is exactly as wide as it always was.
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListingPill(
                      label: n > 0 ? '${o.label}  ×$n' : o.label,
                      selected: n > 0,
                      icon: iconForAmenity(o.label, 'bedroom'),
                      onTap: () => _add(o.value),
                    ),
                    if (n > 0) ...[
                      const SizedBox(width: 4),
                      Semantics(
                        button: true,
                        label: 'Remove one ${o.label} bed',
                        child: InkWell(
                          onTap: () => _removeOne(o.value),
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            // 36 square: a comfortable touch target rather than
                            // the size of the glyph inside it.
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: kIndigo.withOpacity(0.12),
                              shape: BoxShape.circle,
                              border: Border.all(color: kIndigo, width: 1.6),
                            ),
                            child: Icon(Icons.remove_rounded,
                                size: 17, color: kIndigo),
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              }),
          ],
        ),
        if (beds.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('Long-press a bed to remove it.',
              style: inter(fontSize: 11.5, color: kMuted)),
        ],
      ],
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.title,
    required this.room,
    required this.vocab,
    required this.isBedroom,
    required this.onChanged,
  });

  final String title;
  final RoomEntry room;
  final RoomDetailVocab vocab;
  final bool isBedroom;
  final ValueChanged<RoomEntry> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: kLine),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isBedroom ? Icons.bed_outlined : Icons.bathtub_outlined,
                  size: 16, color: kInk),
              const SizedBox(width: 8),
              Flexible(
                child: Text(title,
                    style: inter(
                        fontSize: 14, fontWeight: FontWeight.w700, color: kInk)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _RoomPills(
            options: isBedroom ? vocab.bedroomTypes : vocab.bathroomTypes,
            value: room.type,
            onChanged: (v) => onChanged(room.copyWith(type: v)),
          ),
          if (isBedroom) ...[
            const SizedBox(height: 14),
            _Beds(
              types: vocab.bedTypes,
              beds: room.beds,
              maxCount: vocab.limits.maxBedCount,
              onChanged: (beds) => onChanged(room.copyWith(beds: beds)),
            ),
            const SizedBox(height: 14),
            Text('Bathroom', style: inter(fontSize: 12.5, color: kMuted)),
            const SizedBox(height: 7),
            _RoomPills(
              options: vocab.bedroomBathroom,
              value: room.bathroom,
              onChanged: (v) => onChanged(room.copyWith(bathroom: v)),
            ),
          ],
          const SizedBox(height: 14),
          Text('Name (optional)', style: inter(fontSize: 12.5, color: kMuted)),
          const SizedBox(height: 7),
          TextFormField(
            // `initialValue` with a key, not a controller: these cards are
            // rebuilt whenever the count above changes, and a controller
            // created per build would lose the cursor on every keystroke.
            key: ValueKey('room-name-${isBedroom ? 'bed' : 'bath'}-${room.index}'),
            initialValue: room.name ?? '',
            maxLength: vocab.limits.maxNameLength,
            style: inter(fontSize: 15, color: kInk),
            decoration: InputDecoration(
              counterText: '',
              isDense: true,
              hintText: isBedroom ? 'e.g. Garden Room' : 'e.g. Ground floor',
              hintStyle: inter(fontSize: 14, color: kMuted),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              filled: true,
              fillColor: kSand,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kLine),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kLine),
              ),
            ),
            onChanged: (v) => onChanged(room.copyWith(name: v)),
          ),
        ],
      ),
    );
  }
}

/// The whole block, under the three counts.
///
/// Draws nothing when the backend sent no vocabulary — an older API — rather
/// than guessing a list of bed types. A wizard quietly missing a section is
/// recoverable; two clients disagreeing about what a "Double" is, after hosts
/// have answered, is not.
class RoomDetailSection extends StatelessWidget {
  const RoomDetailSection({
    super.key,
    required this.vocab,
    required this.bedroomCount,
    required this.bathroomCount,
    required this.bedrooms,
    required this.bathrooms,
    required this.onBedroom,
    required this.onBathroom,
  });

  final RoomDetailVocab? vocab;
  final int bedroomCount;
  final int bathroomCount;

  /// Already sized to the counts by the controller's `sizedRooms`.
  final List<RoomEntry> bedrooms;
  final List<RoomEntry> bathrooms;
  final void Function(int index, RoomEntry room) onBedroom;
  final void Function(int index, RoomEntry room) onBathroom;

  @override
  Widget build(BuildContext context) {
    final v = vocab;
    if (v == null) return const SizedBox.shrink();
    if (bedrooms.isEmpty && bathrooms.isEmpty) return const SizedBox.shrink();

    String title(String noun, RoomEntry r, int i) {
      final name = (r.name ?? '').trim();
      return name.isEmpty ? '$noun ${i + 1}' : '$noun ${i + 1} — $name';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 18),
        Text('Tell guests about each room',
            style:
                inter(fontSize: 14, fontWeight: FontWeight.w700, color: kInk)),
        const SizedBox(height: 4),
        Text(
          'Optional, and it is the first thing guests ask — which room they '
          'get, what they will sleep in, and whether the bathroom is theirs. '
          'Change the numbers above to add or remove a room.',
          style: inter(fontSize: 12, color: kMuted),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < bedrooms.length; i++)
          _RoomCard(
            title: title('Bedroom', bedrooms[i], i),
            room: bedrooms[i],
            vocab: v,
            isBedroom: true,
            onChanged: (next) => onBedroom(i, next),
          ),
        for (var i = 0; i < bathrooms.length; i++)
          _RoomCard(
            title: title('Bathroom', bathrooms[i], i),
            room: bathrooms[i],
            vocab: v,
            isBedroom: false,
            onChanged: (next) => onBathroom(i, next),
          ),
      ],
    );
  }
}
