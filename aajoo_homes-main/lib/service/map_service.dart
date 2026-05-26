
import 'package:rent_home/data/source/remote/api_client/api_client.dart';
import 'package:rent_home/data/models/properties_response_model.dart';

class MapService {
  final ApiClient apiClient = ApiClient();
  MapService();

  Future<PropertiesResponse?> getProperties(double lat, double long,
      {int category = 0, String radius = ""}) async {
    final Map<String, dynamic> data = {
      "latitude": lat,
      "longitude": long,
      // Always include radius; default is empty string
      "radius": radius, // "" by default
    };
    // Add category filter if provided (>0)
    if (category > 0) {
      data["category"] = category.toString();
    }
    try {
      final response = await apiClient.post("/properties/search", data: data);
      if (response["success"] == true) {
        final msg = (response["message"] ?? "").toString().toLowerCase();
        if (msg.contains("no record")) {
          return PropertiesResponse(
            success: true,
            message: "No properties found",
            data: Data(property: []),
          );
        }
        final propertiesResponse = PropertiesResponse.fromJson(response);
        return propertiesResponse;
      }
        return null;
    } on Exception catch (e) {
      return PropertiesResponse(
        success: false,
        message: "Failed to fetch properties",
        data: Data(property: []),
      );
    }
  }
  Future<PropertiesResponse?> getLuxuryProperties() async {
    final data = {
      "query": "",
      "longitude": "",
      "latitude": "",
      "sort_by": "property_id",
      "order": "desc",
      "limit": 10,
      "offset": 0,
      "radius": 10,
      "isLuxury": true
    };
    try {
      final response = await apiClient.post("/properties/list", data: data);
      if (response["success"]) {
        final json = response;
        final success = json["success"];
        final message = json["message"];
        final data = json["data"] as List;
        final propertyResponseModel = PropertiesResponse(
          success: success,
          message: message,
          data: Data(
              property:
                  List<Property>.from(data.map((x) => Property.fromJson(x)))),
        );
        return propertyResponseModel;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
