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
    });

    final List<Property> properties;

    Data copyWith({
        List<Property>? properties,
    }) {
        return Data(
            properties: properties ?? this.properties,
        );
    }

    factory Data.fromJson(Map<String, dynamic> json){ 
        return Data(
            properties: json["Properties"] == null ? [] : List<Property>.from(json["Properties"]!.map((x) => Property.fromJson(x))),
        );
    }

    Map<String, dynamic> toJson() => {
        "Properties": properties.map((x) => x?.toJson()).toList(),
    };

    @override
    String toString(){
        return "$properties, ";
    }
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
    final int isLuxury;
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
        dynamic? propertyZip,
        String? propertyState,
        String? propertyContry,
        String? propertyContact,
        String? propertyEmail,
        bool? isActive,
        bool? isVerify,
        int? isLuxury,
        dynamic? propDetailsPropDetailIsPetFriendly,
        dynamic? propDetailsPropDetailIsSmoke,
        dynamic? propDetailsPropDetailInTime,
        dynamic? propDetailsPropDetailOutTime,
        dynamic? propDetailsPropDetailExtra,
        dynamic? coverImage,
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
            isLuxury: isLuxury ?? this.isLuxury,
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
            isVerify: json["is_verify"] ?? false,
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
