import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rent_home/models/properties_response_model.dart';

class MapService {
  final String baseUrl = "https://aajaodev.onrender.com";
  final Dio _dio = Dio();

  MapService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.contentType = 'application/json';
  }

  // ...existing code...
  /// Search stays.
  ///
  /// [guests], [from] and [to] narrow the results the same way the web does —
  /// the API has accepted all three for a while (see schema/properties.schema
  /// .js) and the app never sent any of them, so the search sheet's "When" and
  /// "Who" were collected from the guest and thrown away: a stay already booked
  /// for those nights still appeared, and a party of six was shown places that
  /// sleep two.
  ///
  /// Dates are DD-MM-YYYY, which is the shape the whole platform uses.
  Future<PropertiesResponse?> getProperties(double lat, double long,
      {int category = 0,
      String radius = "",
      int? guests,
      String? from,
      String? to,
      bool? isLuxury}) async {
    final Map<String, dynamic> data = {
      "latitude": lat,
      "longitude": long,
    };

    // Every one of these must be named in the yup schema to survive
    // stripUnknown, and each is omitted rather than sent empty — a null would
    // be stripped anyway, and an empty string trips the number coercion.
    if (guests != null && guests > 0) data["guests"] = guests;
    if (from != null && from.isNotEmpty) data["from"] = from;
    if (to != null && to.isNotEmpty) data["to"] = to;
    if (isLuxury == true) data["isLuxury"] = 1;

    // Radius goes over the wire as a NUMBER, and is omitted when blank.
    // Sending the empty string made the API answer "no record found" for
    // every search, and sending "20000" as a string failed the request
    // outright — which is why the wide-radius retry never produced anything
    // and the home screen stayed on "No stays available yet".
    final parsedRadius = num.tryParse(radius.trim());
    if (parsedRadius != null) {
      data["radius"] = parsedRadius;
    }

    // Add category filter if provided (>0)
    if (category > 0) {
      data["category"] = category.toString();
    }

    print("Search payload: $data");
    try {
      print("Fetch Property !!!");
      final response = await _dio.post("/properties/search", data: data);
      print("Response for Fetch Property : ${response.data}");

      if (response.statusCode == 200 && response.data["success"] == true) {
        final msg = (response.data["message"] ?? "").toString().toLowerCase();
        if (msg.contains("no record")) {
          return PropertiesResponse(
            success: true,
            message: "No properties found",
            data: Data(property: []),
          );
        }
        final propertiesResponse = PropertiesResponse.fromJson(response.data);
        print("Properties: ${propertiesResponse.data.property.length}");
        return propertiesResponse;
      }
      if (response.statusCode == 400) {
        return PropertiesResponse(
          success: false,
          message: "Failed to fetch properties",
          data: Data(property: []),
        );
      } else {
        return null;
      }
    } on DioException catch (e) {
      print(e.response);
      print(e.message);
      return PropertiesResponse(
        success: false,
        message: "Failed to fetch properties",
        data: Data(property: []),
      );
    } on Exception catch (e) {
      print(e);
      return PropertiesResponse(
        success: false,
        message: "Failed to fetch properties",
        data: Data(property: []),
      );
    }
  }
// ...existing code...

  Future<PropertiesResponse?> getLuxuryProperties() async {
    final token = await const FlutterSecureStorage().read(key: "user_token");
    _dio.options.headers['Authorization'] = 'Bearer $token';
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
      final response = await _dio.post("/properties/list", data: data);
      if (response.statusCode == 200 && response.data["success"]) {
        final json = response.data;
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

        print("Properties: ${propertyResponseModel.data.property.length}");
        return propertyResponseModel;
      } else {
        return null;
      }
    } catch (e) {
      print(e);
      return null;
    }
  }
}
