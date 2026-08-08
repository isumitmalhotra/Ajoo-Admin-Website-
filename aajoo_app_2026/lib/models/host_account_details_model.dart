class HostAccountDetails {
  final int? hadId;
  final String accountNumber;
  final String accountIfsc;
  final int? status;
  final bool isVerified;

  HostAccountDetails({
    this.hadId,
    required this.accountNumber,
    required this.accountIfsc,
    this.status,
    this.isVerified = false,
  });

  factory HostAccountDetails.fromJson(Map<String, dynamic> json) {
    return HostAccountDetails(
      hadId: json["had_id"] is int
          ? json["had_id"] as int
          : int.tryParse("${json["had_id"]}"),
      accountNumber: "${json["had_acc_no"] ?? ''}",
      accountIfsc: "${json["had_ifsc"] ?? ''}",
      status: json["had_status"] is int
          ? json["had_status"] as int
          : int.tryParse("${json["had_status"]}"),
      isVerified: (json["had_isVerified"] ?? 0).toString() == "1",
    );
  }
}
