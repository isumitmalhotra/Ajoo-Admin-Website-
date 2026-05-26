class SignupResponse {
  final bool success;
  final String message;
  final SignupData data;

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

  SignupData({required this.userId});

  factory SignupData.fromJson(Map<String, dynamic> json) {
    return SignupData(
      userId: json['userId'] ?? 0,
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

  LoginResponse({
    required bool success,
    required String message,
    required this.data,
  }) : super(success: success, message: message);

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: LoginData.fromJson(json['data'] ?? {}),
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
      'userId': userId,
      'user_fullName': fullName,
      'user_pnumber': phoneNumber,
      'user_dob': dob,
      'user_isVerified': isVerified,
      'user_address': address,
      'user_city': city,
      'user_zipcode': zipcode,
      'kycDocs': kycDocs?.toJson(),
    };
  }
}

class KycDocs {
  String udNumber;
  int udAfileId;
  String docTypeDTitle;
  String docImageAfileCldId;
  String imageUrl;

  KycDocs({
    required this.udNumber,
    required this.udAfileId,
    required this.docTypeDTitle,
    required this.docImageAfileCldId,
    required this.imageUrl,
  });

  factory KycDocs.fromJson(Map<String, dynamic> json) => KycDocs(
        udNumber: json["ud_number"],
        udAfileId: json["ud_afile_id"],
        docTypeDTitle: json["docType.d_title"],
        docImageAfileCldId: json["docImage.afile_cldId"],
        imageUrl: json["ImageUrl"],
      );

  Map<String, dynamic> toJson() => {
        "ud_number": udNumber,
        "ud_afile_id": udAfileId,
        "docType.d_title": docTypeDTitle,
        "docImage.afile_cldId": docImageAfileCldId,
        "ImageUrl": imageUrl,
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
