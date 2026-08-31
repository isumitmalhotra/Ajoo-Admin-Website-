/// The host's payout account, as the server is willing to describe it.
///
/// The account number here is ALREADY MASKED by the server ("XXXX1234") and
/// there is no way to ask for the real one — it is encrypted at rest and the
/// host is confirming which account is on file, not reading it back.
///
/// The verification fields matter more than they look. A payout to an
/// unverified account is refused server-side, so an account can sit here
/// looking complete while no money will ever move; [verifyStatus] is the only
/// thing that says why. It mirrors what the website's Payouts page shows.
class HostAccountDetails {
  final int? hadId;

  /// Masked, e.g. `XXXX1234`. Never a full account number.
  final String accountNumber;
  final String accountIfsc;
  final String? accountHolderName;
  final String? bankName;
  final int? status;

  final bool isVerified;

  /// `pending` · `mismatch` · `failed` · `unconfigured` · null.
  final String? verifyStatus;

  /// The name the bank holds against the account, when it disagreed with ours.
  final String? registeredName;
  final String? verifyNote;

  HostAccountDetails({
    this.hadId,
    required this.accountNumber,
    required this.accountIfsc,
    this.accountHolderName,
    this.bankName,
    this.status,
    this.isVerified = false,
    this.verifyStatus,
    this.registeredName,
    this.verifyNote,
  });

  factory HostAccountDetails.fromJson(Map<String, dynamic> json) {
    // Two shapes reach this. The current server sends the same public shape
    // the website reads (`accountNumber`, `ifsc`, `verifyStatus`, …) and
    // repeats the safe values under the old column names for builds already on
    // phones. Older servers send only the columns. Read either.
    String pick(List<String> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v != null && "$v".isNotEmpty) return "$v";
      }
      return '';
    }

    String? pickOrNull(List<String> keys) {
      final v = pick(keys);
      return v.isEmpty ? null : v;
    }

    return HostAccountDetails(
      hadId: json["had_id"] is int
          ? json["had_id"] as int
          : int.tryParse("${json["had_id"]}"),
      accountNumber: pick(["accountNumber", "had_acc_no"]),
      accountIfsc: pick(["ifsc", "had_ifsc"]),
      accountHolderName: pickOrNull(["accountHolderName", "had_acc_holder_name"]),
      bankName: pickOrNull(["bankName", "had_bank_name"]),
      status: json["had_status"] is int
          ? json["had_status"] as int
          : int.tryParse("${json["had_status"]}"),
      isVerified: json["isVerified"] == true ||
          (json["had_isVerified"] ?? 0).toString() == "1",
      verifyStatus: pickOrNull(["verifyStatus", "had_verify_status"]),
      registeredName: pickOrNull(["registeredName", "had_registered_name"]),
      verifyNote: pickOrNull(["verifyNote", "had_verify_note"]),
    );
  }

  /// What to call this state on screen. Same words as the website.
  String get verifyLabel {
    if (isVerified) return 'Verified';
    switch (verifyStatus) {
      case 'pending':
        return 'Verifying…';
      case 'mismatch':
        return 'Name mismatch';
      case 'failed':
        return 'Verification failed';
      default:
        return 'Not verified';
    }
  }

  /// The sentence explaining the state, or null when there is nothing to add.
  String? get verifyExplanation {
    if (isVerified) return null;
    switch (verifyStatus) {
      case 'pending':
        return "We've sent ₹1 to confirm the account is yours. "
            'This usually clears within a few hours.';
      case 'mismatch':
        return 'Your bank holds this account as '
            '${registeredName ?? 'a different name'}. Payouts stay blocked '
            'until the names match — correct the details or contact support.';
      case 'failed':
        return verifyNote ??
            "We couldn't confirm this account. Check the number and IFSC, "
                'or contact support.';
      default:
        return 'Payouts are held until this account is confirmed.';
    }
  }
}
