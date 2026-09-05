import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:rent_home/constants.dart';
import 'package:rent_home/service/growth_service.dart';
import 'package:rent_home/ui/widgets/load_failed.dart';
import 'package:rent_home/utils/service_log.dart';
import 'package:rent_home/utils/fonts.dart';
import 'package:rent_home/ui/screens_host/support/host_support_screen.dart';
import 'package:rent_home/ui/screens_host/negotiations/host_negotiations_screen.dart';
import 'package:rent_home/ui/screens_host/earnings/host_earnings_screen.dart';
import 'package:rent_home/ui/screens_host/calendar/host_calendar_screen.dart';

/// The host's notification list — the mobile counterpart of the web's
/// /host/notifications.
///
/// Guests have had one for a while; hosts had none, even though
/// /host/notifications/search has been filling with real rows the whole time
/// (booking requests, support replies, payout events). A host's only sign that
/// something had happened was a push they might have swiped away.
///
/// Note this is a GET with page/limit as query parameters and rows prefixed
/// `ntf_` — a different endpoint and a different shape from the guest list,
/// which is why one reader cannot serve both.
class HostNotificationsScreen extends StatefulWidget {
  const HostNotificationsScreen({super.key});

  @override
  State<HostNotificationsScreen> createState() =>
      _HostNotificationsScreenState();
}

class _HostNotificationsScreenState extends State<HostNotificationsScreen> {
  List<HostNotification> _items = const [];
  int _unread = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final page = await GrowthService.instance.hostNotifications();
    if (!mounted) return;
    setState(() {
      _items = page.items;
      _unread = page.unread;
      _loading = false;
    });
  }

  /// Mark read, then go where the row is about.
  ///
  /// `ntf_link_path` is a WEBSITE path, so it is mapped to the app's own
  /// screens rather than opened — sending a host to the website from inside
  /// the app is the bug we fixed on the guest home.
  Future<void> _open(HostNotification n) async {
    if (!n.isRead) {
      await GrowthService.instance.markHostNotificationRead(n.id);
      if (mounted) {
        setState(() {
          _items = _items
              .map((e) => e.id == n.id
                  ? HostNotification(
                      id: e.id,
                      title: e.title,
                      body: e.body,
                      category: e.category,
                      isRead: true,
                      linkPath: e.linkPath,
                      createdAt: e.createdAt,
                    )
                  : e)
              .toList();
          if (_unread > 0) _unread -= 1;
        });
      }
    }

    final path = (n.linkPath ?? '').toLowerCase();
    if (path.isEmpty) return;
    // Pushed directly rather than by name: this app has no named host routes,
    // so Get.toNamed('/host/support') would quietly do nothing — the exact
    // shape of dead button this screen exists to replace.
    if (path.contains('support')) {
      Get.to(() => const HostSupportScreen());
    } else if (path.contains('negotiation')) {
      Get.to(() => const HostNegotiationsScreen());
    } else if (path.contains('payout') || path.contains('earning')) {
      Get.to(() => const HostEarningsScreen());
    } else if (path.contains('calendar')) {
      Get.to(() => const HostCalendarScreen());
    }
    // Anything we have no screen for stays put rather than guessing.
  }

  String _when(DateTime? d) {
    if (d == null) return '';
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${d.day}/${d.month}';
  }

  IconData _icon(String category) {
    switch (category.toUpperCase()) {
      case 'BOOKING':
        return Icons.event_available_outlined;
      case 'PAYMENT':
      case 'PAYOUT':
        return Icons.account_balance_wallet_outlined;
      case 'NEGOTIATION':
        return Icons.handshake_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSand,
      appBar: AppBar(
        backgroundColor: kSand,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: kInk,
        titleSpacing: 0,
        title: Row(
          children: [
            Text('Notifications',
                style: fraunces(
                    fontSize: 20, fontWeight: FontWeight.w700, color: kInk)),
            if (_unread > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: kIndigo, borderRadius: BorderRadius.circular(999)),
                child: Text('$_unread',
                    style: inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
            ],
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          // An empty list after a FAILED request is not "no notifications" —
          // it is a screen that could not find out. Say so, and offer a retry.
          : (_items.isEmpty &&
                  ServiceErrors.lastFor('hostNotifications') != null)
              ? LoadFailed(
                  title: "Couldn't load your notifications",
                  message: ServiceErrors.lastFor('hostNotifications')!,
                  onRetry: () async {
                    setState(() => _loading = true);
                    await _load();
                  },
                )
              : _items.isEmpty
                  ? _empty()
                  : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _row(_items[i]),
                  ),
                ),
    );
  }

  Widget _empty() => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.notifications_none_rounded,
                  size: 48, color: kMuted),
              const SizedBox(height: 12),
              Text('Nothing yet',
                  style: fraunces(
                      fontSize: 17, fontWeight: FontWeight.w600, color: kInk)),
              const SizedBox(height: 6),
              Text(
                'Booking requests, guest messages and payout updates will '
                'appear here.',
                textAlign: TextAlign.center,
                style: inter(fontSize: 13.5, color: kMuted, height: 1.5),
              ),
            ],
          ),
        ),
      );

  Widget _row(HostNotification n) => Material(
        color: n.isRead ? Colors.white : kIndigo50.withOpacity(0.55),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _open(n),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kLine),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                      color: kIndigo50, shape: BoxShape.circle),
                  child: Icon(_icon(n.category), size: 18, color: kIndigo),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(n.title,
                                style: inter(
                                    fontSize: 14,
                                    fontWeight: n.isRead
                                        ? FontWeight.w600
                                        : FontWeight.w700,
                                    color: kInk)),
                          ),
                          const SizedBox(width: 8),
                          Text(_when(n.createdAt),
                              style:
                                  inter(fontSize: 11.5, color: kMuted)),
                        ],
                      ),
                      if (n.body.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(n.body,
                            style: inter(
                                fontSize: 13, color: kMuted, height: 1.4)),
                      ],
                    ],
                  ),
                ),
                if (!n.isRead) ...[
                  const SizedBox(width: 8),
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                        color: kClay, shape: BoxShape.circle),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
}
