// Aajoo LUXE — the app's luxury mode, as one preference.
//
// WHY THIS EXISTS
//
// LUX was per-screen local state. The home screen held `bool isLuxury = false`
// and so did the pre-booking screen, each its own copy, neither persisted. So
// turning LUX on did three things and no more: it swapped the pill's own
// label, it re-fetched the listings, and it was forgotten the moment you left
// the screen. The page around the listings stayed Warm Ivory and teal, which
// is why the mode reads as "nothing happened" — the only visible difference
// was that there were fewer stays.
//
// The website has had this right the whole time (redesign/lib/luxMode.ts): ONE
// preference, stored once, worn everywhere public. This is that, for the app —
// same storage semantics, same "public surfaces only" scoping, so a guest who
// browses in LUX on the phone sees what they see on the site.
//
// Stored through secure_store rather than SharedPreferences only because that
// is what this app already ships; the value is a UI preference, not a secret.
import 'package:flutter/foundation.dart';

import 'package:rent_home/utils/secure_store.dart';

/// The single source of truth for whether LUXE is on.
///
/// A [ValueNotifier] rather than a GetX `Rx` so that non-GetX widgets — the
/// design-system components in ui/design, which have no controller — can
/// rebuild on it with a plain [ValueListenableBuilder].
class LuxMode {
  LuxMode._();

  static final LuxMode instance = LuxMode._();

  static const String _key = 'aajoo_lux';

  /// Whether the guest has chosen LUXE. Public browse surfaces skin themselves
  /// from this; the portals deliberately do not (see the note in luxMode.ts —
  /// re-skinning a payout table in gold helps nobody).
  final ValueNotifier<bool> on = ValueNotifier<bool>(false);

  bool get isOn => on.value;

  bool _loaded = false;

  /// Read the stored preference once, at startup.
  ///
  /// Defaults to off and stays off if the read fails or times out, so a wedged
  /// Keystore costs the preference and nothing else. Never awaited by the UI:
  /// the screen builds classic and re-skins if the answer comes back true,
  /// which is the same order the website resolves it in.
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final v = await secureRead(_key);
    if (v == '1' && !on.value) on.value = true;
  }

  /// Flip the mode and remember it.
  Future<void> set(bool value) async {
    if (on.value == value) return;
    on.value = value;
    await secureWrite(_key, value ? '1' : '0');
  }
}
