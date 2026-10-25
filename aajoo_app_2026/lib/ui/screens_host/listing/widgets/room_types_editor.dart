/// The rooms a by-room property sells.
///
/// Client, 2026-10-20: a guesthouse with twelve rooms at four different prices
/// cannot be listed today, because a listing is one bookable thing. This is
/// where the host says what the rooms are and what each costs.
///
/// ── Why this is its own widget, saved by its own endpoint ──────────────────
///
/// It renders inside the pricing step and saves through POST
/// /listing/room-types rather than with the step. A host reopens this screen
/// long after the wizard is finished — to add a room, change a price, take one
/// off sale — and folding it into a step would reopen a flow they have already
/// completed.
///
/// ── Why the nine price values sit on the room card ─────────────────────────
///
/// A host naming a room is already thinking about what it costs. Sending them
/// back to the property's own pricing section once per room type would mean
/// finishing a job they believed was done, four times over.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/ui/screens_host/listing/listing_wizard_controller.dart';

class RoomTypesEditor extends StatelessWidget {
  const RoomTypesEditor({super.key, required this.controller, this.photoMinimum = 0});

  final ListingWizardController controller;

  /// Photographs asked of each room type — three, not the listing's ten.
  /// Zero when the server did not say, and then simply not mentioned.
  final int photoMinimum;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    return Obx(() {
      final rooms = c.roomTypes;
      final totalRooms = rooms.fold<int>(
          0, (n, r) => n + (int.tryParse('${r['quantity'] ?? ''}'.trim()) ?? 0));

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < rooms.length; i++)
            _RoomCard(
              key: ValueKey(rooms[i]['id'] ?? 'new-$i'),
              index: i,
              room: rooms[i],
              canRemove: rooms.length > 1,
              onChanged: (key, value) => c.setRoomTypeField(i, key, value),
              onRemove: () => c.removeRoomType(i),
            ),

          const SizedBox(height: 4),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: c.addRoomType,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add another room type'),
              ),
              ElevatedButton(
                onPressed: c.roomTypesSaving.value
                    ? null
                    : () async {
                        final refusal = await c.saveRoomTypes();
                        if (refusal == null) {
                          Get.snackbar('Saved',
                              '${c.roomTypes.length} room type${c.roomTypes.length == 1 ? '' : 's'} saved',
                              snackPosition: SnackPosition.BOTTOM);
                        }
                      },
                child: Text(c.roomTypesSaving.value ? 'Saving…' : 'Save rooms'),
              ),
              Text(
                '${rooms.length} room type${rooms.length == 1 ? '' : 's'}, '
                '$totalRooms room${totalRooms == 1 ? '' : 's'} in total',
                style: inter(fontSize: 12.5, color: kMuted),
              ),
            ],
          ),

          // The server's refusal, shown as written. It validates the nine
          // values with the same validator a property's prices go through and
          // returns the FIRST problem — "Deluxe Room: Weekly price is
          // required" — a sentence already composed for the host. Rewording
          // it here would be a second copy of a rule that lives in one place.
          if (c.roomTypesError.value.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 16, color: Color(0xFF92400E)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(c.roomTypesError.value,
                        style: inter(
                            fontSize: 12.5,
                            color: const Color(0xFF92400E),
                            height: 1.4)),
                  ),
                ],
              ),
            ),
          ],

          if (photoMinimum > 0) ...[
            const SizedBox(height: 10),
            Text(
              'Each room type also needs $photoMinimum photograph'
              '${photoMinimum == 1 ? '' : 's'} of its own, on top of the '
              'photographs of the property.',
              style: inter(fontSize: 12, color: kMuted, height: 1.4),
            ),
          ],
        ],
      );
    });
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({
    super.key,
    required this.index,
    required this.room,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final Map<String, dynamic> room;
  final bool canRemove;
  final void Function(String key, dynamic value) onChanged;
  final VoidCallback onRemove;

  String _v(String key) => '${room[key] ?? ''}';

  @override
  Widget build(BuildContext context) {
    final name = _v('name').trim();
    final qty = int.tryParse(_v('quantity').trim()) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: kLine),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name.isEmpty ? 'Room type ${index + 1}' : name,
                  style: inter(
                      fontSize: 14, fontWeight: FontWeight.w700, color: kInk),
                ),
              ),
              if (qty > 1)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text('× $qty',
                      style: inter(fontSize: 13, color: kMuted)),
                ),
              if (canRemove)
                TextButton.icon(
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline, size: 17),
                  label: const Text('Remove'),
                ),
            ],
          ),
          const SizedBox(height: 6),

          _field('name', 'Room name',
              hint: 'e.g. Deluxe Room',
              help: 'What a guest will see in the room list.'),

          // The sentence that prevents the commonest mistake in this form.
          // The migration tool groups rooms BY NAME, so four cards all called
          // "Deluxe Room" read as four room types — and the quantity is the
          // number availability counts against.
          _field('quantity', 'How many rooms of this kind',
              numeric: true,
              hint: 'e.g. 4',
              help: 'Four identical Deluxe rooms is ONE room type with a '
                  'quantity of 4 — not four room types.'),

          _pair(
            _field('totalGuests', 'Sleeps', numeric: true, hint: 'e.g. 2'),
            _field('guestsIncluded', 'Guests included', numeric: true),
          ),
          _pair(
            _field('extraGuestPrice', 'Extra guest / night (₹)', money: true),
            _field('maxExtraGuests', 'Max extra guests', numeric: true),
          ),

          // The nine values, in the three groups a host thinks in. Every one
          // is required — the same rule a property's prices follow, enforced
          // by the same validator on the server, so this form cannot quietly
          // ask for less than the save will.
          for (final row in const [
            ['Per night', 'nightlyPrice', 'nightlyMin', 'nightlyIdeal'],
            ['Per week', 'weeklyPrice', 'weeklyMin', 'weeklyIdeal'],
            ['Per month', 'monthlyPrice', 'monthlyMin', 'monthlyIdeal'],
          ]) ...[
            const SizedBox(height: 10),
            Text(row[0],
                style: inter(
                    fontSize: 12.5, fontWeight: FontWeight.w600, color: kInk)),
            const SizedBox(height: 6),
            _pair(
              _field(row[1], 'Price (₹)', money: true),
              _field(row[2], 'Minimum (₹)', money: true),
            ),
            _field(row[3], 'Ideal (₹)', money: true),
          ],

          const SizedBox(height: 8),
          Text(
            'A guest’s offer at or above your ideal is accepted straight '
            'away. Anything below still reaches you to decide — nothing is '
            'refused on your behalf.',
            style: inter(fontSize: 12, color: kMuted, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _pair(Widget a, Widget b) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: a),
          const SizedBox(width: 12),
          Expanded(child: b),
        ],
      );

  Widget _field(
    String key,
    String label, {
    bool numeric = false,
    bool money = false,
    String? hint,
    String? help,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: inter(fontSize: 12.5, color: kMuted)),
          const SizedBox(height: 6),
          TextFormField(
            // Keyed on the row's identity so a rebuild does not throw away
            // what the host is typing — the same lesson the review form
            // learnt when a StatelessWidget held its own controller.
            initialValue: _v(key),
            keyboardType: (numeric || money)
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            inputFormatters: [
              if (numeric) FilteringTextInputFormatter.digitsOnly,
              if (money)
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: InputDecoration(
              hintText: hint,
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: kLine),
              ),
            ),
            style: inter(fontSize: 14, color: kInk),
            onChanged: (v) => onChanged(key, v),
          ),
          if (help != null) ...[
            const SizedBox(height: 4),
            Text(help, style: inter(fontSize: 11.5, color: kMuted, height: 1.35)),
          ],
        ],
      ),
    );
  }
}
