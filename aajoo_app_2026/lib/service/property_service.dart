import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:rent_home/models/property_review_response_model.dart';
import 'package:rent_home/models/single_property_response.dart';
import 'package:rent_home/models/host_profile.dart';
import 'package:rent_home/models/destination_model.dart';

class PropertyService {
  /// Why the last addProperties call failed, straight from the server.
  ///
  /// It used to be printed to the console and dropped, so every failure
  /// surfaced as the same "Failed to add property" with no reason — a host
  /// could not tell a missing field from a rate limit from a server fault,
  /// and neither could we.
  String? lastAddError;

  final Dio dio = Dio();
  final String baseUrl = "https://aajaodev.onrender.com/";
  PropertyService() {
    dio.options.baseUrl = baseUrl;
    // Dio defaults every timeout to null, which means WAIT FOREVER. Submitting
    // a listing posts several megabytes of photos and documents in one
    // multipart request, and when that stalls — Render's free tier sleeping,
    // a slow upload, a dropped connection — the host sat on a spinning Submit
    // button with no error, no timeout and no way back. Verified on device:
    // ten minutes of spinner, nothing created, nothing said. Same class as
    // the negotiation loader that only a socket event could clear.
    //
    // Generous, because the upload is genuinely large — but finite, so the
    // failure path can actually run and tell the host what happened.
    dio.options.connectTimeout = const Duration(seconds: 30);
    dio.options.sendTimeout = const Duration(minutes: 3);
    dio.options.receiveTimeout = const Duration(minutes: 3);
    dio.interceptors.add(PrettyDioLogger(
      requestHeader: kDebugMode,
      requestBody: kDebugMode,
      responseBody: kDebugMode,
      responseHeader: false,
      error: true,
      compact: true,
      maxWidth: 90,
      enabled: kDebugMode,
    ));
  }
  final _secureStorage = const FlutterSecureStorage();
  final String TOKEN_KEY = "user_token";
  Future<bool> addProperties(
      List<File>? imageFile, Map<String, dynamic> otherData,
      {List<File>? propertyDocs}) async {
    final token = await _secureStorage.read(key: TOKEN_KEY);
    dio.options.headers["Authorization"] = "Bearer $token";
    try {
      // Create FormData object
      FormData formData = FormData.fromMap({
        ...otherData,
        "property_img": imageFile != null
            ? await Future.wait(imageFile
                .map((file) async => await MultipartFile.fromFile(
                      file.path,
                      filename: file.path.split('/').last,
                    ))
                .toList())
            : null,
        // Add property documents if provided
        if (propertyDocs != null && propertyDocs.isNotEmpty)
          "property_doc": await Future.wait(propertyDocs
              .map((file) async => await MultipartFile.fromFile(
                    file.path,
                    filename: file.path.split('/').last,
                  ))
              .toList()),
      });

      // Send POST request with form data
      final response = await dio.post("properties/add", data: formData);
      print(response.data);

      if (response.statusCode == 200) {
        if (response.data['success'] == true) {
          lastAddError = null;
          return true;
        }
        lastAddError = _messageFrom(response.data);
        print("Failed to add property: ${response.data}");
        return false;
      }
      lastAddError = _messageFrom(response.data);
      print("Failed to add property: ${response.data}");
      return false;
    } on DioException catch (e) {
      final timedOut = e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionTimeout;
      lastAddError = _messageFrom(e.response?.data) ??
          (e.response?.statusCode == 429
              ? 'Too many upload attempts. Wait a minute and try again.'
              // A timeout is not "check your connection" — the connection is
              // usually fine and the photos are simply large. Say what would
              // actually help.
              : timedOut
                  ? 'Upload timed out. Your photos may be too large — try '
                      'fewer or smaller images, then submit again.'
                  : 'Could not reach the server. Check your connection.');
      print("Error: ${e.response?.data} ${e.message}");
      return false;
    }
  }

  Future<bool> likeReview(int id) async {
    final token = await const FlutterSecureStorage().read(key: "user_token");
    dio.options.headers['Authorization'] = 'Bearer $token';

    final response = await dio.post("review/like", data: {
      "reviewId": id,
    });
    print(response.data);
    if (response.statusCode == 200) {
      if (response.data["success"]) {
        return true;
      }
      return false;
    }
    return false;
  }

  Future<bool> dislikeReview(int id) async {
    final token = await const FlutterSecureStorage().read(key: "user_token");
    dio.options.headers['Authorization'] = 'Bearer $token';
    final response = await dio.post("review/dislike", data: {
      "reviewId": id,
    });
    print(response.data);
    if (response.statusCode == 200) {
      if (response.data["success"]) {
        return true;
      }
      return false;
    }
    return false;
  }

  /// Places the platform can actually put someone, busiest first.
  ///
  /// Same endpoint the website's "Featured Destinations" rail reads, so the two
  /// can never advertise different places or different counts. Returns an empty
  /// list rather than throwing — a rail with nothing in it hides itself, which
  /// is better than a home screen that fails to build.
  Future<List<Destination>> getDestinations({int limit = 8}) async {
    try {
      final response = await dio.get("properties/destinations?limit=$limit");
      final data = response.data is Map ? response.data['data'] : null;
      final rows = data is Map ? data['destinations'] : null;
      if (rows is! List) return const [];
      return rows
          .whereType<Map>()
          .map((r) => Destination.fromJson(Map<String, dynamic>.from(r)))
          .where((d) => d.name.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('getDestinations failed: $e');
      return const [];
    }
  }

  Future<ReviewResponse> getPropertyReview(int id) async {
    final token = await const FlutterSecureStorage().read(key: "user_token");
    dio.options.headers['Authorization'] = 'Bearer $token';
    final response = await dio.post("properties/reviews/list", data: {
      "propertyId": id,
    });
    print(id);
    print(response.data);
    final responseModel = ReviewResponse.fromJson(response.data);
    return responseModel;
  }

  Future<bool> updatePropertyCoverImage(int propertyId, File imageFile) async {
    final url = '${baseUrl}properties/add/cover-pic';
    final token = await const FlutterSecureStorage().read(key: "user_token");
    dio.options.headers['Authorization'] = 'Bearer $token';
    try {
      FormData formData = FormData.fromMap({
        "property_id": propertyId,
        "property_img": await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      final response = await dio.post(url, data: formData);
      print(response.data);
      if (response.statusCode == 200) {
        if (response.data["success"]) {
          return true;
        }
        return false;
      }
      return false;
    } on DioException catch (e) {
      print(e);
      print(e.response);
      return false;
    }
  }

  Future<SinglePropertyResponse> getSingleProperty(int id) async {
    final token = await _secureStorage.read(key: TOKEN_KEY);
    print(token);
    dio.options.headers["Authorization"] = "Bearer $token";
    try {
      final response = await dio.get("properties/$id");

      // Remove this line that's causing the error
      // print("history ->>>" + response.data); // response.data is a Map, not a String

      // Instead, print like this if needed:
      print("history ->>> ${response.data}");

      if (response.statusCode == 200) {
        final propertyResponse = SinglePropertyResponse.fromJson(response.data);
        return propertyResponse;
      }
      return SinglePropertyResponse(
          success: false,
          message: "Failed to get property",
          data: SinglePropertyData());
    } on DioException catch (e) {
      print(e);
      _handleError(e);
      return SinglePropertyResponse(
          success: false,
          message: "Failed to get property",
          data: SinglePropertyData());
    } on Exception catch (e) {
      print(e);
      return SinglePropertyResponse(
          success: false,
          message: "Failed to get property",
          data: SinglePropertyData());
    }
  }

  /// The public host profile behind the property-detail host block.
  ///
  /// Returns null rather than throwing: the host block is decoration on a page
  /// whose main job is the listing, so a failure here must not take the page
  /// down. Callers fall back to a generic label.
  Future<HostProfile?> getHostProfile(int hostId) async {
    try {
      final response = await dio.get("properties/host/$hostId");
      final data = response.data;
      if (data is! Map || data['success'] != true) return null;
      // A host the endpoint will not vouch for answers success:true with
      // "no record found" and data: [] — a LIST, not a map. Check the shape
      // rather than casting, or an owner who is not a registered host throws.
      final payload = data['data'];
      if (payload is! Map) return null;
      final host = payload['host'];
      if (host is! Map) return null;
      return HostProfile.fromJson(Map<String, dynamic>.from(host));
    } catch (e) {
      print('getHostProfile failed: $e');
      return null;
    }
  }

  /// Pull a readable reason out of whatever the API returned. The validation
  /// layer answers with a LIST of messages, the controllers with a string.
  String? _messageFrom(dynamic data) {
    if (data is! Map) return null;
    final m = data['message'];
    if (m is List && m.isNotEmpty) {
      return m.map((e) => e.toString()).join(r'\n').replaceAll(r'\n', '\n');
    }
    if (m is String && m.trim().isNotEmpty) return m;
    return null;
  }

  Exception _handleError(dynamic error) {
    if (error is DioException) {
      final response = error.response?.data;
      final message = response?['message'] ?? error.message;
      return Exception(message);
    }
    return Exception(error.toString());
  }

  Future<bool> deleteProperty(int id) async {
    final token = await _secureStorage.read(key: TOKEN_KEY);
    if (token == null) {
      return false;
    }
    dio.options.headers["Authorization"] = "Bearer $token";

    try {
      final response = await dio.post("host/delete-property", data: {
        "propertyId": id,
      });
      print(response.data);
      if (response.statusCode == 200) {
        if (response.data["success"]) {
          return true;
        }
        return false;
      }

      return false;
    } on DioException catch (e) {
      print(e.message);
      print(e.response!.data);
      return false;
    }
  }
}
