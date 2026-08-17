import 'package:get/get.dart';
import 'package:rent_home/controller/alert_dialog.dart';
import 'package:rent_home/models/host_calendar_model.dart';
import 'package:rent_home/models/host_properties_reponse.dart';
import 'package:rent_home/service/host_calendar_service.dart';
import 'package:rent_home/service/host_service.dart';

/// State for the host calendar screen. Screen-scoped (`Get.put` in initState,
/// `Get.delete` in dispose) the way HostBookingHistoryController is, rather than
/// bolted onto the shared HostController.
///
/// The listing picker keeps its OWN page of properties instead of reusing
/// HostController's. That list is what the profile page renders as "Managed
/// Properties", and searching for a listing here would otherwise rewrite the
/// list behind that screen — the host would come back from the calendar to find
/// their property list filtered by a query they typed somewhere else.
class HostCalendarController extends GetxController {
  final HostCalendarService _service = HostCalendarService();
  final HostService _hostService = HostService();

  // ── Listing picker (R2) ────────────────────────────────────────────────────
  final RxList<Property> properties = <Property>[].obs;
  final RxBool propertiesLoading = false.obs;
  final RxBool propertiesLoadingMore = false.obs;
  final RxString propertiesError = ''.obs;
  final RxString query = ''.obs;
  final Rx<Property?> property = Rx<Property?>(null);

  /// How many listings the host owns in total. `properties.length` is one page
  /// — 20 where this is 29,230 for the test host, which is why the picker is a
  /// searchable sheet and not a dropdown.
  final RxInt propertyTotal = 0.obs;
  static const int _pageSize = 20;
  int _propertyPage = 1;

  bool get hasMoreProperties => properties.length < propertyTotal.value;

  // ── Calendar (R1) ──────────────────────────────────────────────────────────
  final RxList<HostCalendarStay> stays = <HostCalendarStay>[].obs;
  final RxList<HostCalendarBlock> blocks = <HostCalendarBlock>[].obs;
  final RxBool loading = false.obs;
  final RxString error = ''.obs;

  /// The month on screen, held as the 1st of it.
  final Rx<DateTime> cursor =
      DateTime(DateTime.now().year, DateTime.now().month).obs;

  // ── Blocking (R4) ──────────────────────────────────────────────────────────
  final RxBool saving = false.obs;

  /// The server's refusal, kept beside the Block button rather than in a toast
  /// that scrolls away.
  final RxString blockError = ''.obs;

  /// The pending range, as YYYY-MM-DD. `selTo` empty means only the start has
  /// been chosen and the calendar is waiting for the second tap.
  final RxString selFrom = ''.obs;
  final RxString selTo = ''.obs;

  /// Switching listings fires a second fetch before the first resolves; without
  /// this the slower response can land last and paint listing A's bookings onto
  /// listing B.
  int _req = 0;

  /// Same guard for the picker. Two searches in quick succession is the normal
  /// way to use a search box, and without this the slower one can land last and
  /// leave the sheet showing results for a query the host has already replaced
  /// — or, worse, auto-adopt the wrong listing out of that stale page.
  int _propReq = 0;

  @override
  void onInit() {
    super.onInit();
    loadProperties();
  }

  // ── Listings ───────────────────────────────────────────────────────────────

  Future<void> loadProperties({String? q}) async {
    final mine = ++_propReq;
    propertiesLoading.value = true;
    propertiesError.value = '';
    query.value = (q ?? '').trim();
    try {
      final res = await _hostService.getHostProperties(
        page: 1,
        limit: _pageSize,
        q: query.value.isEmpty ? null : query.value,
      );
      if (_propReq != mine) return;
      final rows = res.data?.properties ?? const <Property>[];
      _propertyPage = 1;
      properties.value = [...rows];
      propertyTotal.value = res.data?.totalCount ?? rows.length;
      // Adopt the first listing only while nothing is chosen, so a search does
      // not yank the host off the calendar they were reading. A host with a
      // single listing therefore never faces an empty picker.
      if (property.value == null && rows.isNotEmpty) {
        selectProperty(rows.first);
      }
    } catch (e) {
      if (_propReq != mine) return;
      properties.clear();
      propertiesError.value = _clean(e);
    } finally {
      if (_propReq == mine) propertiesLoading.value = false;
    }
  }

  /// Append the next page. No-op while one is in flight or the list is whole.
  Future<void> loadMoreProperties() async {
    if (propertiesLoadingMore.value || !hasMoreProperties) return;
    propertiesLoadingMore.value = true;
    try {
      final res = await _hostService.getHostProperties(
        page: _propertyPage + 1,
        limit: _pageSize,
        q: query.value.isEmpty ? null : query.value,
      );
      final rows = res.data?.properties ?? const <Property>[];
      if (rows.isEmpty) return;
      _propertyPage += 1;
      properties.addAll(rows);
    } catch (e) {
      // Not propertiesError: that field means "there is nothing to choose
      // from", and the sheet swaps the whole list out for an error box when it
      // is set. A failed SECOND page must not take the first one off screen.
      showAlert('Calendar', _clean(e), true);
    } finally {
      propertiesLoadingMore.value = false;
    }
  }

  void selectProperty(Property p) {
    if (property.value?.propertyId == p.propertyId) return;
    property.value = p;
    // A half-made selection belongs to the listing it was made on, so it goes
    // when the listing changes.
    clearSelection();
    loadCalendar();
  }

  // ── Calendar ───────────────────────────────────────────────────────────────

  Future<void> loadCalendar() async {
    final id = property.value?.propertyId;
    if (id == null) return;
    final mine = ++_req;
    loading.value = true;
    error.value = '';
    try {
      final cal = await _service.getCalendar(id);
      if (_req != mine) return;
      stays.value = cal.stays;
      blocks.value = cal.blocks;
    } catch (e) {
      if (_req != mine) return;
      // Drop whatever was on screen and say so. Leaving the last listing's
      // stays up would attribute them to this one; drawing an empty month would
      // claim every date is free.
      stays.clear();
      blocks.clear();
      error.value = _clean(e);
    } finally {
      if (_req == mine) loading.value = false;
    }
  }

  void stepMonth(int direction) {
    final c = cursor.value;
    cursor.value = DateTime(c.year, c.month + direction);
  }

  // ── Selecting a range to block ─────────────────────────────────────────────

  /// The end of the pending range — the start itself while only one day is
  /// chosen, so a single-day block needs no special case.
  String get selectionEnd => selTo.value.isEmpty ? selFrom.value : selTo.value;

  bool get hasSelection => selFrom.value.isNotEmpty;

  bool isInSelection(String iso) {
    if (selFrom.value.isEmpty) return false;
    final end = selectionEnd;
    return iso.compareTo(selFrom.value) >= 0 && iso.compareTo(end) <= 0;
  }

  /// Tapping a free day: the first tap opens a range, the second closes it.
  void tapFreeDay(String iso) {
    blockError.value = '';
    if (selFrom.value.isEmpty || selTo.value.isNotEmpty) {
      selFrom.value = iso;
      selTo.value = '';
      return;
    }
    if (iso.compareTo(selFrom.value) < 0) {
      selTo.value = selFrom.value;
      selFrom.value = iso;
    } else {
      selTo.value = iso;
    }
  }

  void clearSelection() {
    selFrom.value = '';
    selTo.value = '';
    blockError.value = '';
  }

  /// Close the pending range. False when the server refused — [blockError] then
  /// carries its reason, verbatim.
  Future<bool> blockSelectedDates(String reason) async {
    final id = property.value?.propertyId;
    if (id == null || selFrom.value.isEmpty) return false;
    final from = selFrom.value;
    final to = selectionEnd;
    saving.value = true;
    blockError.value = '';
    try {
      final created = await _service.blockDates(
          propertyId: id, from: from, to: to, reason: reason);
      // Patch rather than refetch — the host stays on the month they were
      // working in. The reload is only for the case where the API saved the
      // block but told us no id, which Unblock would later need.
      if (created != null) {
        blocks.add(created);
      } else {
        await loadCalendar();
      }
      clearSelection();
      final days = isoDayCount(from, to);
      showAlert(
          'Calendar',
          days == 1
              ? 'That date is blocked — guests can no longer book it.'
              : 'Those $days days are blocked — guests can no longer book them.',
          false);
      return true;
    } catch (e) {
      // Verbatim. The server names the booking standing in the way and a
      // generic failure line would hide the only fact the host can act on.
      blockError.value = _clean(e);
      return false;
    } finally {
      saving.value = false;
    }
  }

  /// Reopen a blocked range. Optimistic in the same shape as
  /// HostController.setPropertyActive: the range leaves the grid at once and a
  /// failed call puts it back exactly where the host left it.
  Future<bool> unblock(HostCalendarBlock block) async {
    final index = blocks.indexWhere((b) => b.blockId == block.blockId);
    if (index >= 0) blocks.removeAt(index);
    saving.value = true;
    try {
      await _service.unblockDates(block.blockId);
      showAlert('Calendar', 'Those dates are open again.', false);
      return true;
    } catch (e) {
      if (index >= 0) blocks.insert(index, block);
      showAlert('Calendar', _clean(e), true);
      return false;
    } finally {
      saving.value = false;
    }
  }

  /// Dart stamps "Exception: " on the front of everything; the host should read
  /// the server's sentence, not Dart's.
  String _clean(Object e) =>
      e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '').trim();
}
