class SinglePropertyResponse {
  final bool? success;
  final String? message;
  final SinglePropertyData? data;

  SinglePropertyResponse({
    this.success,
    this.message,
    this.data,
  });

  factory SinglePropertyResponse.fromJson(Map<String, dynamic> json) {
    return SinglePropertyResponse(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null
          ? SinglePropertyData.fromJson(json['data'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data?.toJson(),
    };
  }
}

class SinglePropertyData {
  final int? propertyId;
  final int? propertyHostId;
  final String? propertyName;
  final String? propertyAddress;
  final String? propertyLongitude;
  final String? propertyLatitude;
  final String? propertyDesc;
  final String? propertyPrice;
  final String? propertyMiniPrice;
  final String? propertyCity;
  final String? propertyZip;
  final int? propertyState;
  final String? propertyCountry;
  final String? propertyContact;
  final String? propertyEmail;
  final bool? isActive;
  /// Whether admin has verified this listing. The detail page shows an "Aajoo
  /// Verified Home" trust card, which was unconditional — every listing, vetted
  /// or not, claimed to be verified for quality, safety and hygiene.
  final bool? isVerify;
  final int? isLuxury;
  final int? bathrooms;
  final SinglePropertyDetails? propDetails;
  final List<String>? images;
  final List<dynamic>? tags;
  final List<dynamic>? categories;
  final List<dynamic>? amenities;

  SinglePropertyData({
    this.propertyId,
    this.propertyHostId,
    this.propertyName,
    this.propertyAddress,
    this.propertyLongitude,
    this.propertyLatitude,
    this.propertyDesc,
    this.propertyPrice,
    this.propertyMiniPrice,
    this.propertyCity,
    this.propertyZip,
    this.propertyState,
    this.propertyCountry,
    this.propertyContact,
    this.propertyEmail,
    this.isActive,
    this.isVerify,
    this.isLuxury,
    this.bathrooms,
    this.propDetails,
    this.images,
    this.tags,
    this.categories,
    this.amenities,
  });

  factory SinglePropertyData.fromJson(Map<String, dynamic> json) {
    // Handle propDetails fields directly in the main JSON
    SinglePropertyDetails? details;
    final hasAnyPropDetail = json.keys
        .any((k) => k.toString().startsWith('propDetails.propDetail_'));
    if (hasAnyPropDetail) {
      details = SinglePropertyDetails(
        propDetailId: _parseIntSafely(json['propDetails.propDetail_id']),
        propDetailPropId:
            _parseIntSafely(json['propDetails.propDetail_propId']),
        isPetFriendly: json['propDetails.propDetail_isPetFriendly'],
        isSmoke: json['propDetails.propDetail_isSmoke'],
        inTime: json['propDetails.propDetail_inTime']?.toString(),
        outTime: json['propDetails.propDetail_outTime']?.toString(),
        extra: json['propDetails.propDetail_extra']?.toString(),
        weeklyMiniPrice:
            json['propDetails.propDetail_weeklyMini_price']?.toString(),
        weeklyMaxPrice:
            json['propDetails.propDetail_weeklyMax_price']?.toString(),
        monthlySecurity:
            json['propDetails.propDetail_monthly_security']?.toString(),
        noOfBeds:
            _parseIntSafely(json['propDetails.propDetail_no_of_beds']),
        noOfGuests:
            _parseIntSafely(json['propDetails.propDetail_no_of_guests']),
      );
    }

    return SinglePropertyData(
      propertyId: _parseIntSafely(json['property_id']),
      propertyHostId: _parseIntSafely(json['property_host_id']),
      propertyName: json['property_name'],
      propertyAddress: json['property_address'],
      propertyLongitude: json['property_longitude'],
      propertyLatitude: json['property_latitude'],
      propertyDesc: json['property_desc'],
      propertyPrice: json['property_price'],
      propertyMiniPrice: json['property_mini_price'],
      propertyCity: json['property_city'],
      propertyZip: json['property_zip'],
      propertyState: _parseIntSafely(json['property_state']),
      propertyCountry: json['property_contry'],
      propertyContact: json['property_contact'],
      propertyEmail: json['property_email'],
      isActive: json['is_active'],
      isVerify: json['is_verify'] == true || json['is_verify'] == 1,
      isLuxury: _parseIntSafely(json['is_luxury']),
      bathrooms: _parseIntSafely(json['bathrooms']),
      propDetails: details,
      images: json['images'] != null ? List<String>.from(json['images']) : [],
      tags: json['tags'] != null ? List<dynamic>.from(json['tags']) : null,
      categories: json['categories'] != null
          ? List<dynamic>.from(json['categories'])
          : null,
      amenities: json['amenities'] != null
          ? List<dynamic>.from(json['amenities'])
          : null,
    );
  }

  // Helper method to safely parse integers from various types
  static int? _parseIntSafely(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        print('Failed to parse "$value" to int: $e');
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'property_id': propertyId,
      'property_host_id': propertyHostId,
      'property_name': propertyName,
      'property_address': propertyAddress,
      'property_longitude': propertyLongitude,
      'property_latitude': propertyLatitude,
      'property_desc': propertyDesc,
      'property_price': propertyPrice,
      'property_mini_price': propertyMiniPrice,
      'property_city': propertyCity,
      'property_zip': propertyZip,
      'property_state': propertyState,
      'property_contry': propertyCountry,
      'property_contact': propertyContact,
      'property_email': propertyEmail,
      'is_active': isActive,
      'is_verify': isVerify,
      'is_luxury': isLuxury,
      'images': images,
    };

    // Add property details directly to the main JSON if available
    if (propDetails != null) {
      data['propDetails.propDetail_id'] = propDetails!.propDetailId;
      data['propDetails.propDetail_propId'] = propDetails!.propDetailPropId;
      data['propDetails.propDetail_isPetFriendly'] = propDetails!.isPetFriendly;
      data['propDetails.propDetail_isSmoke'] = propDetails!.isSmoke;
      data['propDetails.propDetail_inTime'] = propDetails!.inTime;
      data['propDetails.propDetail_outTime'] = propDetails!.outTime;
      data['propDetails.propDetail_extra'] = propDetails!.extra;
    }

    return data;
  }
}

class SinglePropertyDetails {
  final int? propDetailId;
  final int? propDetailPropId;
  final bool? isPetFriendly;
  final bool? isSmoke;
  final String? inTime;
  final String? outTime;
  final String? extra;
  final String? weeklyMiniPrice;
  final String? weeklyMaxPrice;
  final String? monthlySecurity;
  final int? noOfBeds;
  final int? noOfGuests;

  SinglePropertyDetails({
    this.propDetailId,
    this.propDetailPropId,
    this.isPetFriendly,
    this.isSmoke,
    this.inTime,
    this.outTime,
    this.extra,
    this.weeklyMiniPrice,
    this.weeklyMaxPrice,
    this.monthlySecurity,
    this.noOfBeds,
    this.noOfGuests,
  });

  factory SinglePropertyDetails.fromJson(Map<String, dynamic> json) {
    return SinglePropertyDetails(
      propDetailId: SinglePropertyData._parseIntSafely(json['propDetail_id']),
      propDetailPropId:
          SinglePropertyData._parseIntSafely(json['propDetail_propId']),
      isPetFriendly: json['propDetail_isPetFriendly'],
      isSmoke: json['propDetail_isSmoke'],
      inTime: json['propDetail_inTime'],
      outTime: json['propDetail_outTime'],
      extra: json['propDetail_extra'],
      weeklyMiniPrice: json['propDetail_weeklyMini_price']?.toString(),
      weeklyMaxPrice: json['propDetail_weeklyMax_price']?.toString(),
      monthlySecurity: json['propDetail_monthly_security']?.toString(),
      noOfBeds: SinglePropertyData._parseIntSafely(json['propDetail_no_of_beds']),
      noOfGuests:
          SinglePropertyData._parseIntSafely(json['propDetail_no_of_guests']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'propDetail_id': propDetailId,
      'propDetail_propId': propDetailPropId,
      'propDetail_isPetFriendly': isPetFriendly,
      'propDetail_isSmoke': isSmoke,
      'propDetail_inTime': inTime,
      'propDetail_outTime': outTime,
      'propDetail_extra': extra,
      'propDetail_weeklyMini_price': weeklyMiniPrice,
      'propDetail_weeklyMax_price': weeklyMaxPrice,
      'propDetail_monthly_security': monthlySecurity,
    };
  }
}
