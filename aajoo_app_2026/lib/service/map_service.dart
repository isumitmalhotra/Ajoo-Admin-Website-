import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rent_home/models/properties_response_model.dart';
import 'package:rent_home/data/ApiConstants.dart';

class MapService {
  final String baseUrl = Apiconstants.baseUrl;
  final Dio _dio = Dio();

  MapService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.contentType = 'application/json';
    // Without these, a stalled request never returns and every caller waits
    // forever. Search is the one that showed it: the sheet's Search button sat
    // on "Searching…" indefinitely because the await underneath it had no way
    // to give up. Every other service in the app already sets them; this one,
    // behind the main search, was the only Dio left bare.
    _dio.options.connectTimeout = const Duration(seconds: 20);
    _dio.options.sendTimeout = const Duration(seconds: 20);
    _dio.options.receiveTimeout = const Duration(seconds: 45);
  }

  /// A transport failure, as opposed to a search that genuinely found nothing.
  ///
  /// Both used to come back as "no properties", so a dead network was shown to
  /// the guest as "No stays here yet" — and the wide-radius retry ran anyway,
  /// doubling the wait before that wrong answer appeared.
  static const String networkFailure = "__network_failure__";

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
      // Only stays whose host takes pets. Sent as true or omitted — sending
      // false would read as a filter for stays that REFUSE pets.
      bool petsAllowed = false,
      String? from,
      String? to,
      bool? isLuxury,
      // What the guest typed. Matched server-side against name, address, city
      // and state, and OR-ed against the radius rather than narrowed by it, so
      // a stay is found by its own name however badly that name geocodes.
      String? q,
      // Price band per night. Each bound is independent — send either, both or
      // neither.
      double? minPrice,
      double? maxPrice,
      Duration? receiveTimeout}) async {
    final Map<String, dynamic> data = {
      "latitude": lat,
      "longitude": long,
    };

    // Every one of these must be named in the yup schema to survive
    // stripUnknown, and each is omitted rather than sent empty — a null would
    // be stripped anyway, and an empty string trips the number coercion.
    if (guests != null && guests > 0) data["guests"] = guests;
    if (petsAllowed) data["petsAllowed"] = true;
    // The typed text.
    //
    // This search only ever sent a POINT. Whatever the guest typed went to the
    // geocoder and no further, so a property NAME was resolved as if it were a
    // place and the search ran wherever that landed — the website had exactly
    // the same fault and the client reported it. The server matches the term
    // itself now, and returns name matches first.
    if (q != null && q.trim().isNotEmpty) data["q"] = q.trim();
    // Price, narrowed by the DATABASE.
    //
    // This was done in Dart over the properties already fetched, so a band
    // searched the page in hand rather than the catalogue and could report
    // nothing while the platform held plenty just outside it.
    if (minPrice != null && minPrice > 0) data["minPrice"] = minPrice;
    if (maxPrice != null && maxPrice > 0) data["maxPrice"] = maxPrice;
    if (from != null && from.isNotEmpty) data["from"] = from;
    if (to != null && to.isNotEmpty) data["to"] = to;
    // 0, not omitted, when LUX is off.
    //
    // LUX and normal are mutually exclusive views of the catalogue (client
    // decision, 2026-09-01): LUX shows only what a host or admin marked
    // luxury, normal shows only what they did not. Omitting the key asked the
    // server for everything, so LUX stays appeared in normal browsing — the
    // same fault the website had, reported by a tester (#17).
    //
    // Left absent only when the caller passes null, which still means "no
    // opinion" for any internal caller that has none.
    if (isLuxury != null) data["isLuxury"] = isLuxury == true ? 1 : 0;

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
      final response = await _dio.post(
        "/properties/search",
        data: data,
        options: receiveTimeout == null
            ? null
            : Options(receiveTimeout: receiveTimeout),
      );
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
        message: networkFailure,
        data: Data(property: []),
      );
    } on Exception catch (e) {
      print(e);
      return PropertiesResponse(
        success: false,
        message: networkFailure,
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
