import 'package:get/get.dart';
import 'package:rent_home/service/growth_service.dart';

/// The host's unread count, for the surfaces that show a badge but no list.
///
/// The host notifications SCREEN has always counted unread and shown it at the
/// top. The two ways IN to that screen — the bell on the host home and the
/// Notifications row in the host menu — showed nothing at all, so a host had no
/// reason to open it and no way to know the platform had told them anything.
/// Hosts are pushed to their phones now, which makes a silent bell worse: the
/// push arrives, and the app it opens looks like there is nothing there.
///
/// One owner for the number, so the bell and the menu row agree and both fall
/// together when the screen is read.
class HostNotificationCount extends GetxController {
  final RxInt unread = 0.obs;
  final GrowthService _service = GrowthService.instance;

  /// Ask the server. Never throws — a badge that cannot be counted stays at
  /// its last value rather than flashing a zero that claims all-clear.
  /// Named reload, not refresh: GetxController.refresh() is its own thing,
  /// used internally to rebuild, and shadowing it is asking for trouble.
  Future<void> reload() async {
    try {
      // One row is enough: the count comes from the server, not the page.
      final page = await _service.hostNotifications(page: 1, limit: 1);
      unread.value = page.unread;
    } catch (_) {
      // Signed out, offline, or the endpoint is unwell. Keep the last figure.
    }
  }

  /// One was opened. Applied straight away so the badge moves with the tap
  /// rather than a network round trip later.
  void decrement([int by = 1]) {
    final next = unread.value - by;
    unread.value = next < 0 ? 0 : next;
  }

  void set(int n) => unread.value = n < 0 ? 0 : n;
}
