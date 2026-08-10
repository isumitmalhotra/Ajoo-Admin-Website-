class SignupResponse {
  final bool success;
  final String message;
  final SignupData data;

  /// Set when the address is already registered but was never verified. The
  /// backend answers success:false — but it has just emailed a fresh code and
  /// returned the id to verify against, so this is a resume, not a dead end.
  bool get needsVerification => data.needsVerification && data.userId > 0;

  SignupResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory SignupResponse.fromJson(Map<String, dynamic> json) {
    return SignupResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: SignupData.fromJson(json['data'] ?? {}),
    );
  }
}

class SignupData {
  final int userId;
  final bool needsVerification;

  SignupData({required this.userId, this.needsVerification = false});

  factory SignupData.fromJson(Map<String, dynamic> json) {
    return SignupData(
      userId: json['userId'] ?? 0,
      needsVerification: json['needsVerification'] == true,
    );
  }
}

class BaseResponse {
  final bool success;
  final String message;

  BaseResponse({
    required this.success,
    required this.message,
  });

  factory BaseResponse.fromJson(Map<String, dynamic> json) {
    return BaseResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }
}

class LoginResponse extends BaseResponse {
  final LoginData data;
  // Set when login fails because the account exists but isn't verified — the
  // client uses these to route the user to the OTP screen instead of erroring.
  final int? userId;
  final bool needsVerification;

  LoginResponse({
    required super.success,
    required super.message,
    required this.data,
    this.userId,
    this.needsVerification = false,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    // On failure the API returns `data: []` (a List), not a Map. Coerce any
    // non-map value to an empty map so parsing never throws — the caller
    // checks `success` and surfaces `message` instead.
    final rawData = json['data'];
    final dataMap =
        rawData is Map<String, dynamic> ? rawData : <String, dynamic>{};
    final rawUserId = dataMap['userId'];
    final parsedUserId = rawUserId is int
        ? rawUserId
        : int.tryParse(rawUserId?.toString() ?? '');
    return LoginResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: LoginData.fromJson(dataMap),
      userId: parsedUserId,
      // The server sends `needsVerification: true` on this branch — the same
      // flag the signup path already uses. `isVerified` was the older shape and
      // is kept as a fallback so an app build in the wild keeps working.
      needsVerification: dataMap['needsVerification'] == true ||
          dataMap['isVerified'] == false,
    );
  }
}

class LoginData {
  final UserDetail user;
  final String token;

  LoginData({
    required this.user,
    required this.token,
  });

  factory LoginData.fromJson(Map<String, dynamic> json) {
    return LoginData(
      user: UserDetail.fromJson(json['user'] ?? {}),
      token: json['token'] ?? '',
    );
  }
}

class UserDetail {
  final int credId;
  final int credUserId;
  final String username;
  final String email;
  final bool isHost;
  final bool isUser;
  final dynamic attachment;
  final int userId;
  final String fullName;
  final String phoneNumber;
  final String dob;
  final bool isVerified;
  final String address;
  final String city;
  final String zipcode;
  final KycDocs? kycDocs;
  // DIDIT identity status: 'verified' | 'pending' | 'in_review' | 'declined' |
  // 'unverified'. Drives the profile "Verified" badge + the booking KYC gate.
  final String verificationStatus;

  UserDetail({
    required this.credId,
    required this.credUserId,
    required this.username,
    required this.email,
    required this.isHost,
    required this.isUser,
    this.attachment,
    required this.userId,
    required this.fullName,
    required this.phoneNumber,
    required this.dob,
    required this.isVerified,
    required this.address,
    required this.city,
    required this.zipcode,
    this.kycDocs,
    this.verificationStatus = 'unverified',
  });

  factory UserDetail.fromJson(Map<String, dynamic> json) {
    print(json.map((key, value) {
      return MapEntry(key, value is String ? value.trim() : value);
    }));
    return UserDetail(
      credId: json['cred_id'] ?? 0,
      credUserId: json['cred_user_id'] ?? 0,
      username: json['cred_username'] ?? '',
      email: json['cred_user_email'] ?? '',
      isHost:
          (json['user_isHost'] ?? false) || (json['cred_user_isHost'] ?? false),
      isUser:
          (json['user_isUser'] ?? false) || (json['cred_user_isUser'] ?? false),
      attachment: json['attachment'] ?? {},
      userId: json['userId'] ?? 0,
      fullName: json['user_fullName'] ?? '',
      phoneNumber: json['user_pnumber'] ?? '',
      dob: json['user_dob'] ?? '',
      isVerified: json['user_isVerified'] ?? false,
      address: json['user_address'] ?? '',
      city: json['user_city'] ?? '',
      zipcode: json['user_zipcode'] ?? '',
      kycDocs:
          json['kycDocs'] != null ? KycDocs.fromJson(json['kycDocs']) : null,
      verificationStatus:
          (json['verification_status'] ?? 'unverified').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cred_id': credId,
      'cred_user_id': credUserId,
      'cred_username': username,
      'cred_user_email': email,
      'cred_user_isHost': isHost,
      'cred_user_isUser': isUser,
      'attachment': attachment,
      'user_id': userId,
      'user_fullName': fullName,
      'user_pnumber': phoneNumber,
      'user_dob': dob,
      'user_isVerified': isVerified,
      'user_address': address,
      'user_city': city,
      'user_zipcode': zipcode,
      'kycDocs': kycDocs?.toJson(),
      'verification_status': verificationStatus,
    };
  }

  UserDetail copyWith({
    int? credId,
    int? credUserId,
    String? username,
    String? email,
    bool? isHost,
    bool? isUser,
    dynamic attachment,
    int? userId,
    String? fullName,
    String? phoneNumber,
    String? dob,
    bool? isVerified,
    String? address,
    String? city,
    String? zipcode,
    KycDocs? kycDocs,
    String? verificationStatus,
  }) {
    return UserDetail(
      credId: credId ?? this.credId,
      credUserId: credUserId ?? this.credUserId,
      username: username ?? this.username,
      email: email ?? this.email,
      isHost: isHost ?? this.isHost,
      isUser: isUser ?? this.isUser,
      attachment: attachment ?? this.attachment,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dob: dob ?? this.dob,
      isVerified: isVerified ?? this.isVerified,
      address: address ?? this.address,
      city: city ?? this.city,
      zipcode: zipcode ?? this.zipcode,
      kycDocs: kycDocs ?? this.kycDocs,
      verificationStatus: verificationStatus ?? this.verificationStatus,
    );
  }

  /// True once DIDIT has confirmed identity (drives badge + booking gate).
  bool get isKycVerified =>
      verificationStatus.toLowerCase() == 'verified' ||
      verificationStatus.toLowerCase() == 'approved';
}

class KycDocs {
  String udNumber;
  int udAfileId;
  String docTypeDTitle;
  String docImageAfileCldId;
  String imgeUrl;

  String get imageUrl => imgeUrl;

  KycDocs({
    required this.udNumber,
    required this.udAfileId,
    required this.docTypeDTitle,
    required this.docImageAfileCldId,
    required this.imgeUrl,
  });

  factory KycDocs.fromJson(Map<String, dynamic> json) => KycDocs(
        udNumber: (json["ud_number"] ?? '').toString(),
        udAfileId: json["ud_afile_id"] ?? 0,
        docTypeDTitle:
            (json["docType.d_title"] ?? json["docTypeDTitle"] ?? '').toString(),
        docImageAfileCldId:
            (json["docImage.afile_cldId"] ?? json["docImageAfileCldId"] ?? '')
                .toString(),
        // API returns "ImageUrl"; toJson/storage uses "ImgeUrl" — accept both.
        imgeUrl: (json["ImageUrl"] ?? json["ImgeUrl"] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {
        "ud_number": udNumber,
        "ud_afile_id": udAfileId,
        "docType.d_title": docTypeDTitle,
        "docImage.afile_cldId": docImageAfileCldId,
        "ImgeUrl": imgeUrl,
      };
}

class ResendOtpResponse {
  final bool success;
  final String message;

  ResendOtpResponse({
    required this.success,
    required this.message,
  });

  factory ResendOtpResponse.fromJson(Map<String, dynamic> json) {
    return ResendOtpResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
    );
  }
}
