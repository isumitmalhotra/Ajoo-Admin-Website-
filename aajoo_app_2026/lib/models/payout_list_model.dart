/// What the host has earned and what has been paid out.
///
/// The SHAPE here is the app's own — it predates the payout engine and the
/// screens are built on it — but the DATA behind it changed. It used to be
/// filled from `/payout/request/list`, which sums `tbl_host_earnings` and lists
/// `tbl_payout_req`: the old "ask us for your money" flow. The platform stopped
/// working that way when the payout engine shipped. Earnings are written to
/// `tbl_financial_ledger` and payouts are raised automatically into
/// `tbl_payouts`, which is what the website reads.
///
/// The consequence was not subtle. On 2026-08-31, for the same host at the same
/// moment, the website showed ₹30,333.16 pending across ten payouts and the app
/// showed ₹0, "No Payout History", and no way to tell that anything was owed.
/// Two tables answering one question, and the phone was reading the empty one.
///
/// [HostPayoutService.getPayoutList] now builds this from the same two
/// endpoints the website uses, so both platforms answer from one ledger.
class PayoutListResponse {
  bool success;
  String message;
  Data data;

  PayoutListResponse({
    required this.success,
    required this.message,
    required this.data,
  });
}

class Data {
  /// Everything the host has earned, ever. From the financial ledger.
  num hostTotalEarning;

  /// Queued and on its way — NOT including payouts an admin has put on hold.
  num earningLeft;

  /// What has ACTUALLY been paid: the sum of completed payouts, as the server
  /// counts them.
  ///
  /// This used to be derived on screen as `earned - pending`, which is a
  /// different claim entirely. For the test host that read "Settled to date
  /// ₹74,481" while the website said ₹0 — and the website was right: not one
  /// payout had completed. The arithmetic quietly treated every rupee that was
  /// not queued as money already in the host's bank.
  num settled;

  List<PayoutRequest> payoutRequests;

  Data({
    required this.hostTotalEarning,
    required this.earningLeft,
    required this.settled,
    required this.payoutRequests,
  });
}

/// One payout. Named for the old payout-request row it replaced, because the
/// screens read these field names; it now carries a `tbl_payouts` row.
class PayoutRequest {
  int payReqId;
  num payReqAmount;
  int payReqIsActive;
  DateTime createdAt;
  String payoutStatusBsTitle;
  dynamic payoutStatusBsCode;

  /// Why a payout failed. Written by the payout engine all along and shown to
  /// nobody: a host saw "FAILED" with no reason and no way to tell whether to
  /// fix their bank details or wait. The website surfaces this; so does the app.
  final String? failureReason;

  /// What the host quotes to support when they query a payout. The server's
  /// own reference where there is one, else the booking it is against — the
  /// same order the website's table uses.
  final String? bookingId;

  PayoutRequest({
    required this.payReqId,
    required this.payReqAmount,
    required this.payReqIsActive,
    required this.createdAt,
    required this.payoutStatusBsTitle,
    required this.payoutStatusBsCode,
    this.failureReason,
    this.bookingId,
  });

  /// Straight from a `tbl_payouts` row as `/host/payout/history` returns it.
  factory PayoutRequest.fromPayoutRow(Map<String, dynamic> j) {
    num n(Object? v) => v is num ? v : num.tryParse('${v ?? ''}') ?? 0;
    // Prefer when the money actually moved; fall back to when it was queued.
    final when = j['po_completed_at'] ?? j['po_initiated_at'] ?? j['po_created_at'];
    return PayoutRequest(
      payReqId: n(j['po_id']).toInt(),
      payReqAmount: n(j['po_amount']),
      payReqIsActive: 1,
      createdAt: DateTime.tryParse('${when ?? ''}') ?? DateTime.now(),
      payoutStatusBsTitle: '${j['po_status'] ?? 'PENDING'}',
      payoutStatusBsCode: j['po_status'],
      failureReason: (j['po_failure_reason'] ?? j['po_notes'])?.toString(),
      bookingId: (j['po_reference_id'] ?? j['po_booking_id'])?.toString(),
    );
  }
}
