class HostPropertiesResponse {
    HostPropertiesResponse({
        required this.success,
        required this.message,
        required this.data,
    });

    final bool success;
    final String message;
    final Data? data;

    HostPropertiesResponse copyWith({
        bool? success,
        String? message,
        Data? data,
    }) {
        return HostPropertiesResponse(
            success: success ?? this.success,
            message: message ?? this.message,
            data: data ?? this.data,
        );
    }

    factory HostPropertiesResponse.fromJson(Map<String, dynamic> json){ 
        return HostPropertiesResponse(
            success: json["success"] ?? false,
            message: json["message"] ?? "",
            data: json["data"] == null ? null : Data.fromJson(json["data"]),
        );
    }

    Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "data": data?.toJson(),
    };

    @override
    String toString(){
        return "$success, $message, $data, ";
    }
}

class Data {
    Data({
        required this.properties,
        this.totalCount = 0,
        this.page = 1,
        this.limit = 0,
    });

    final List<Property> properties;
    /// How many listings the host owns in total. `properties` is one page of
    /// them — /host/property-search used to return every row, which is 29,230
    /// and 38 MB for the test host, so anything that wants a count must read
    /// this rather than properties.length.
    final int totalCount;
    final int page;
    final int limit;

    bool get hasMore => properties.length < totalCount && limit > 0;

    Data copyWith({
        List<Property>? properties,
        int? totalCount,
        int? page,
        int? limit,
    }) {
        return Data(
            properties: properties ?? this.properties,
            totalCount: totalCount ?? this.totalCount,
            page: page ?? this.page,
            limit: limit ?? this.limit,
        );
    }

    factory Data.fromJson(Map<String, dynamic> json){
        final props = json["Properties"] == null ? <Property>[] : List<Property>.from(json["Properties"]!.map((x) => Property.fromJson(x)));
        return Data(
            properties: props,
            totalCount: _asInt(json["totalcount"]) ?? props.length,
            page: _asInt(json["page"]) ?? 1,
            limit: _asInt(json["limit"]) ?? props.length,
        );
    }

    Map<String, dynamic> toJson() => {
        "Properties": properties.map((x) => x.toJson()).toList(),
        "totalcount": totalCount,
        "page": page,
        "limit": limit,
    };

    @override
    String toString(){
        return "$properties, ";
    }
}

int? _asInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
}

// Renders a numeric JSON value as a clean string ("5000.0" → "5000"); '' for null.
String _numStr(dynamic v) {
  if (v == null) return '';
  if (v is num) {
    return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
  }
  return v.toString();
}

class Property {
    Property({
        required this.propertyId,
        required this.propertyHostId,
        required this.propertyName,
        required this.propertyAddress,
        required this.propertyLongitude,
        required this.propertyLatitude,
        required this.propertyDesc,
        required this.propertyPrice,
        required this.propertyMiniPrice,
        required this.propertyCity,
        required this.propertyZip,
        required this.propertyState,
        required this.propertyContry,
        required this.propertyContact,
        required this.propertyEmail,
        required this.isActive,
        required this.isVerify,
        this.isRejected = false,
        this.verificationStatus = 'unverified',
        this.propertyType = '',
        this.bookingPref = '',
        this.areaLocality = '',
        this.landmark = '',
        this.floorNo = '',
        this.bathrooms = '',
        this.securityDeposit = '',
        this.weekendPrice = '',
        this.extraGuestCharge = '',
        this.cleaningFee = '',
        this.minBookingAmount = '',
        this.videoUrl = '',
        this.quietHours = '',
        this.ownershipType = '',
        this.coupleFriendly = false,
        this.localIdAllowed = false,
        required this.isLuxury,
        required this.propDetailsPropDetailIsPetFriendly,
        required this.propDetailsPropDetailIsSmoke,
        required this.propDetailsPropDetailInTime,
        required this.propDetailsPropDetailOutTime,
        required this.propDetailsPropDetailExtra,
        required this.coverImage,
        required this.images,
    });

    final int propertyId;
    final int propertyHostId;
    final String propertyName;
    final String propertyAddress;
    final String propertyLongitude;
    final String propertyLatitude;
    final String propertyDesc;
    final String propertyPrice;
    final String propertyMiniPrice;
    final String propertyCity;
    final dynamic propertyZip;
    final String propertyState;
    final String propertyContry;
    final String propertyContact;
    final String propertyEmail;
    final bool isActive;
    final bool isVerify;
    /// True when the admin turned this listing down, so the host is told to
    /// re-apply instead of being left on "Pending review" forever.
    final bool isRejected;
    final String verificationStatus;
    final int isLuxury;
    // Host-onboarding (H1) fields — returned by /host/property-search so the
    // edit form can prefill them.
    final String propertyType;
    final String bookingPref;
    final String areaLocality;
    final String landmark;
    final String floorNo;
    final String bathrooms;
    final String securityDeposit;
    final String weekendPrice;
    final String extraGuestCharge;
    final String cleaningFee;
    final String minBookingAmount;
    final String videoUrl;
    final String quietHours;
    final String ownershipType;
    final bool coupleFriendly;
    final bool localIdAllowed;
    final dynamic propDetailsPropDetailIsPetFriendly;
    final dynamic propDetailsPropDetailIsSmoke;
    final dynamic propDetailsPropDetailInTime;
    final dynamic propDetailsPropDetailOutTime;
    final dynamic propDetailsPropDetailExtra;
    final dynamic coverImage;
    final List<dynamic> images;

    Property copyWith({
        int? propertyId,
        int? propertyHostId,
        String? propertyName,
        String? propertyAddress,
        String? propertyLongitude,
        String? propertyLatitude,
        String? propertyDesc,
        String? propertyPrice,
        String? propertyMiniPrice,
        String? propertyCity,
        dynamic propertyZip,
        String? propertyState,
        String? propertyContry,
        String? propertyContact,
        String? propertyEmail,
        bool? isActive,
        bool? isVerify,
        bool? isRejected,
        String? verificationStatus,
        int? isLuxury,
        // Carried through explicitly — a copyWith that forgot these reset the
        // whole H1 block to its defaults, so patching one field (is_active,
        // say) silently blanked the property type, charges and house rules on
        // the row it was meant to leave alone.
        String? propertyType,
        String? bookingPref,
        String? areaLocality,
        String? landmark,
        String? floorNo,
        String? bathrooms,
        String? securityDeposit,
        String? weekendPrice,
        String? extraGuestCharge,
        String? cleaningFee,
        String? minBookingAmount,
        String? videoUrl,
        String? quietHours,
        String? ownershipType,
        bool? coupleFriendly,
        bool? localIdAllowed,
        dynamic propDetailsPropDetailIsPetFriendly,
        dynamic propDetailsPropDetailIsSmoke,
        dynamic propDetailsPropDetailInTime,
        dynamic propDetailsPropDetailOutTime,
        dynamic propDetailsPropDetailExtra,
        dynamic coverImage,
        List<dynamic>? images,
    }) {
        return Property(
            propertyId: propertyId ?? this.propertyId,
            propertyHostId: propertyHostId ?? this.propertyHostId,
            propertyName: propertyName ?? this.propertyName,
            propertyAddress: propertyAddress ?? this.propertyAddress,
            propertyLongitude: propertyLongitude ?? this.propertyLongitude,
            propertyLatitude: propertyLatitude ?? this.propertyLatitude,
            propertyDesc: propertyDesc ?? this.propertyDesc,
            propertyPrice: propertyPrice ?? this.propertyPrice,
            propertyMiniPrice: propertyMiniPrice ?? this.propertyMiniPrice,
            propertyCity: propertyCity ?? this.propertyCity,
            propertyZip: propertyZip ?? this.propertyZip,
            propertyState: propertyState ?? this.propertyState,
            propertyContry: propertyContry ?? this.propertyContry,
            propertyContact: propertyContact ?? this.propertyContact,
            propertyEmail: propertyEmail ?? this.propertyEmail,
            isActive: isActive ?? this.isActive,
            isVerify: isVerify ?? this.isVerify,
            isRejected: isRejected ?? this.isRejected,
            verificationStatus: verificationStatus ?? this.verificationStatus,
            isLuxury: isLuxury ?? this.isLuxury,
            propertyType: propertyType ?? this.propertyType,
            bookingPref: bookingPref ?? this.bookingPref,
            areaLocality: areaLocality ?? this.areaLocality,
            landmark: landmark ?? this.landmark,
            floorNo: floorNo ?? this.floorNo,
            bathrooms: bathrooms ?? this.bathrooms,
            securityDeposit: securityDeposit ?? this.securityDeposit,
            weekendPrice: weekendPrice ?? this.weekendPrice,
            extraGuestCharge: extraGuestCharge ?? this.extraGuestCharge,
            cleaningFee: cleaningFee ?? this.cleaningFee,
            minBookingAmount: minBookingAmount ?? this.minBookingAmount,
            videoUrl: videoUrl ?? this.videoUrl,
            quietHours: quietHours ?? this.quietHours,
            ownershipType: ownershipType ?? this.ownershipType,
            coupleFriendly: coupleFriendly ?? this.coupleFriendly,
            localIdAllowed: localIdAllowed ?? this.localIdAllowed,
            propDetailsPropDetailIsPetFriendly: propDetailsPropDetailIsPetFriendly ?? this.propDetailsPropDetailIsPetFriendly,
            propDetailsPropDetailIsSmoke: propDetailsPropDetailIsSmoke ?? this.propDetailsPropDetailIsSmoke,
            propDetailsPropDetailInTime: propDetailsPropDetailInTime ?? this.propDetailsPropDetailInTime,
            propDetailsPropDetailOutTime: propDetailsPropDetailOutTime ?? this.propDetailsPropDetailOutTime,
            propDetailsPropDetailExtra: propDetailsPropDetailExtra ?? this.propDetailsPropDetailExtra,
            coverImage: coverImage ?? this.coverImage,
            images: images ?? this.images,
        );
    }

    factory Property.fromJson(Map<String, dynamic> json){ 
        return Property(
            propertyId: json["property_id"] ?? 0,
            propertyHostId: json["property_host_id"] ?? 0,
            propertyName: json["property_name"] ?? "",
            propertyAddress: json["property_address"] ?? "",
            propertyLongitude: json["property_longitude"] ?? "",
            propertyLatitude: json["property_latitude"] ?? "",
            propertyDesc: json["property_desc"] ?? "",
            propertyPrice: json["property_price"] ?? "",
            propertyMiniPrice: json["property_mini_price"] ?? "",
            propertyCity: json["property_city"] ?? "",
            propertyZip: json["property_zip"],
            propertyState: json["property_state"] ?? "",
            propertyContry: json["property_contry"] ?? "",
            propertyContact: json["property_contact"] ?? "",
            propertyEmail: json["property_email"] ?? "",
            isActive: json["is_active"] ?? false,
            isVerify: verifyIsApproved(json["is_verify"]),
            isRejected: verifyIsRejected(json["is_verify"]),
            verificationStatus: json["verification_status"] ?? "unverified",
            propertyType: (json["property_type"] ?? '').toString(),
            bookingPref: (json["booking_pref"] ?? '').toString(),
            areaLocality: (json["area_locality"] ?? '').toString(),
            landmark: (json["landmark"] ?? '').toString(),
            floorNo: (json["floor_no"] ?? '').toString(),
            bathrooms: _numStr(json["bathrooms"]),
            securityDeposit: _numStr(json["security_deposit"]),
            weekendPrice: _numStr(json["weekend_price"]),
            extraGuestCharge: _numStr(json["extra_guest_charge"]),
            cleaningFee: _numStr(json["cleaning_fee"]),
            minBookingAmount: _numStr(json["min_booking_amount"]),
            videoUrl: (json["video_url"] ?? '').toString(),
            quietHours: (json["quiet_hours"] ?? '').toString(),
            ownershipType: (json["ownership_type"] ?? '').toString(),
            coupleFriendly:
                json["couple_friendly"] == 1 || json["couple_friendly"] == true,
            localIdAllowed:
                json["local_id_allowed"] == 1 || json["local_id_allowed"] == true,
            isLuxury: json["is_luxury"] ?? 0,
            propDetailsPropDetailIsPetFriendly: json["propDetails.propDetail_isPetFriendly"],
            propDetailsPropDetailIsSmoke: json["propDetails.propDetail_isSmoke"],
            propDetailsPropDetailInTime: json["propDetails.propDetail_inTime"],
            propDetailsPropDetailOutTime: json["propDetails.propDetail_outTime"],
            propDetailsPropDetailExtra: json["propDetails.propDetail_extra"],
            coverImage: json["coverImage"],
            images: json["images"] == null ? [] : List<dynamic>.from(json["images"]!.map((x) => x)),
        );
    }

    Map<String, dynamic> toJson() => {
        "property_id": propertyId,
        "property_host_id": propertyHostId,
        "property_name": propertyName,
        "property_address": propertyAddress,
        "property_longitude": propertyLongitude,
        "property_latitude": propertyLatitude,
        "property_desc": propertyDesc,
        "property_price": propertyPrice,
        "property_mini_price": propertyMiniPrice,
        "property_city": propertyCity,
        "property_zip": propertyZip,
        "property_state": propertyState,
        "property_contry": propertyContry,
        "property_contact": propertyContact,
        "property_email": propertyEmail,
        "is_active": isActive,
        "is_verify": isVerify,
        "is_luxury": isLuxury,
        "propDetails.propDetail_isPetFriendly": propDetailsPropDetailIsPetFriendly,
        "propDetails.propDetail_isSmoke": propDetailsPropDetailIsSmoke,
        "propDetails.propDetail_inTime": propDetailsPropDetailInTime,
        "propDetails.propDetail_outTime": propDetailsPropDetailOutTime,
        "propDetails.propDetail_extra": propDetailsPropDetailExtra,
        "coverImage": coverImage,
        "images": images.map((x) => x).toList(),
    };

    @override
    String toString(){
        return "$propertyId, $propertyHostId, $propertyName, $propertyAddress, $propertyLongitude, $propertyLatitude, $propertyDesc, $propertyPrice, $propertyMiniPrice, $propertyCity, $propertyZip, $propertyState, $propertyContry, $propertyContact, $propertyEmail, $isActive, $isVerify, $isLuxury, $propDetailsPropDetailIsPetFriendly, $propDetailsPropDetailIsSmoke, $propDetailsPropDetailInTime, $propDetailsPropDetailOutTime, $propDetailsPropDetailExtra, $coverImage, $images, ";
    }
}

/// Read `is_verify` whatever shape it arrives in.
///
/// tbl_properties has a Sequelize afterFind hook that rewrites this field on
/// LIST responses: 1 becomes `true`, 2 becomes the STRING "Rejected", 3
/// becomes `false`, 0 stays 0. The model declared `final bool isVerify` and
/// assigned the raw value, so the first rejected listing a host owned threw
/// "type 'String' is not a subtype of type 'bool'" and took their ENTIRE
/// property list down with it — not one bad row, the whole screen.
///
/// The web has the same normaliser in redesign/lib/verifyStatus.ts; keep the
/// two in step.
bool verifyIsApproved(dynamic v) {
  if (v is bool) return v;
  if (v is num) return v == 1;
  final s = v?.toString().trim().toLowerCase();
  return s == 'verified' || s == 'true' || s == '1';
}

bool verifyIsRejected(dynamic v) {
  if (v is num) return v == 2;
  final s = v?.toString().trim().toLowerCase();
  return s == 'rejected' || s == '2';
}
