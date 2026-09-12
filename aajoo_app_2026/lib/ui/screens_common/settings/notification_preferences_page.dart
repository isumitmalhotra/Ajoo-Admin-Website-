import 'package:flutter/material.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/service/notification_service.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/utils/safe_bottom.dart';

/// What you want to be interrupted about.
///
/// There were no preferences at all. Every notification went to every channel
/// the platform had, and the only way to stop a push was to silence the whole
/// app in the phone's settings — which also silences the one telling you a
/// guest has arrived.
///
/// Only the interrupting channels are here. The in-app list is the record of
/// what we told you and stays complete; every email the platform sends is a
/// receipt, a confirmation or a password reset. Both are said in words rather
/// than shown as a switch that does nothing — a dead control is worse than an
/// honest sentence.
class NotificationPreferencesPage extends StatefulWidget {
  const NotificationPreferencesPage({super.key});

  @override
  State<NotificationPreferencesPage> createState() =>
      _NotificationPreferencesPageState();
}

/// Written the way a person would describe the thing, not the way the database
/// names it. Kept in step with the website's list on purpose: one account read
/// from two apps must not offer two different sets of switches.
const List<({String key, String label, String hint})> _categories = [
  (
    key: 'booking',
    label: 'Bookings and stays',
    hint: 'Confirmations, check-in, changes and cancellations'
  ),
  (
    key: 'payment',
    label: 'Payments and refunds',
    hint: 'Money received, refunds and payouts'
  ),
  (
    key: 'offer',
    label: 'Offers and negotiations',
    hint: 'Offers made, countered and accepted'
  ),
  (
    key: 'support',
    label: 'Support replies',
    hint: 'When someone answers your ticket'
  ),
  (
    key: 'promotions',
    label: 'Deals and news',
    hint: 'Occasional offers from Aajoo'
  ),
];

class _NotificationPreferencesPageState
    extends State<NotificationPreferencesPage> {
  final NotificationService _service = NotificationService();

  Map<String, dynamic> _push = {};
  Map<String, dynamic> _whatsapp = {};
  String? _emailNote;
  String? _inAppNote;
  bool _loading = true;
  bool _failed = false;
  String? _saving;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _service.getPreferences();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (data == null) {
        _failed = true;
        return;
      }
      final prefs = data['preferences'];
      _push = prefs is Map ? Map<String, dynamic>.from(prefs['push'] ?? {}) : {};
      _whatsapp =
          prefs is Map ? Map<String, dynamic>.from(prefs['whatsapp'] ?? {}) : {};
      final always = data['alwaysOn'];
      _emailNote = always is Map ? always['email']?.toString() : null;
      _inAppNote = always is Map ? always['inApp']?.toString() : null;
      _failed = false;
    });
  }

  /// Saved on the switch, not behind a Save button — a preferences screen with
  /// one is a screen people leave without pressing it. The switch moves at once
  /// and goes back if the server refuses, so what is on screen is always what
  /// the server holds.
  Future<void> _set(String channel, String key, bool value) async {
    final target = channel == 'push' ? _push : _whatsapp;
    final before = target[key];
    setState(() {
      target[key] = value;
      _saving = '$channel.$key';
    });
    final saved = await _service.setPreference(channel, key, value);
    if (!mounted) return;
    setState(() {
      _saving = null;
      if (saved == null) {
        target[key] = before;
        return;
      }
      _push = Map<String, dynamic>.from(saved['push'] ?? _push);
      _whatsapp = Map<String, dynamic>.from(saved['whatsapp'] ?? _whatsapp);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kscaffoldColor,
      appBar: AppBar(
        title: Text('Notifications',
            style: inter(fontSize: 17, fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _failed
              // A LIST, not a Padding, and with a button.
              //
              // This said "pull down to try again" inside a widget that does
              // not scroll, so there was nothing to pull: the retry it offered
              // could not be performed, and the screen sat on a stale error
              // until you left and came back. Seen on build 50.
              ? RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(
                        "We couldn't load your preferences just now. Nothing "
                        'has changed.',
                        style: inter(fontSize: 13.5, color: kMuted, height: 1.5),
                      ),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _loading = true;
                              _failed = false;
                            });
                            _load();
                          },
                          child: Text('Try again',
                              style: inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: kprimaryColor)),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: safeBottomInsets(context,
                        left: 16, top: 12, right: 16, bottom: 16),
                    children: [
                      Text(
                        'Choose what interrupts you \u2014 on your phone and by email. '
                        '${_inAppNote ?? 'Your notifications list always keeps a record.'}',
                        style: inter(fontSize: 13, color: kMuted, height: 1.5),
                      ),
                      const SizedBox(height: 14),
                      for (final c in _categories)
                        _row(
                          label: c.label,
                          hint: c.hint,
                          value: _push[c.key] != false,
                          busy: _saving == 'push.${c.key}',
                          onChanged: (v) => _set('push', c.key, v),
                        ),
                      const SizedBox(height: 8),
                      _row(
                        label: 'Deals and news on WhatsApp',
                        hint: 'Marketing messages only — booking updates are '
                            'sent whatever this says',
                        value: _whatsapp['promotions'] != false,
                        busy: _saving == 'whatsapp.promotions',
                        onChanged: (v) => _set('whatsapp', 'promotions', v),
                      ),
                      const SizedBox(height: 16),
                      // Said in words, because there is no honest switch for it.
                      Text(
                        _emailNote ??
                            "We'll always email booking confirmations, receipts "
                                'and security changes.',
                        style:
                            inter(fontSize: 12.5, color: kMuted, height: 1.5),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _row({
    required String label,
    required String hint,
    required bool value,
    required bool busy,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kLine),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kInk)),
                const SizedBox(height: 2),
                Text(hint,
                    style: inter(fontSize: 12, color: kMuted, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch.adaptive(
            value: value,
            onChanged: busy ? null : onChanged,
            activeColor: kprimaryColor,
          ),
        ],
      ),
    );
  }
}
