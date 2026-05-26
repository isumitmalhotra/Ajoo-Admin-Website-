import 'package:dio/dio.dart';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:rent_home/data/source/remote/api_client/api_client.dart';
import 'package:rent_home/data/models/property_review_response_model.dart';
import 'package:rent_home/data/models/single_property_response.dart';

class PropertyService {
  final ApiClient apiClient = ApiClient();

  Future<bool> addProperties(
      List<File>? imageFile, Map<String, dynamic> otherData,
      {List<File>? propertyDocs}) async {
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
      final response = await apiClient.post("/properties/add", data: formData);
      if (response['success']) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> likeReview(int id) async {
    try {
      final response = await apiClient.post("/review/like", data: {
        "reviewId": id,
      });
      if (response["success"]) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> dislikeReview(int id) async {
    try {
      final response = await apiClient.post("/review/dislike", data: {
        "reviewId": id,
      });
      if (response["success"]) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<ReviewResponse> getPropertyReview(int id) async {
    try {
      final response = await apiClient
          .post("/properties/reviews/list", data: {"propertyId": id});
      final responseModel = ReviewResponse.fromJson(response);
      return responseModel;
    } catch (e) {
      throw e;
    }
  }

  Future<bool> updatePropertyCoverImage(int propertyId, File imageFile) async {
    try {
      FormData formData = FormData.fromMap({
        "property_id": propertyId,
        "property_img": await MultipartFile.fromFile(
          imageFile.path,
          filename: imageFile.path.split('/').last,
        ),
      });

      final response =
          await apiClient.post("/properties/add/cover-pic", data: formData);
      if (response["success"]) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<SinglePropertyResponse> getSingleProperty(int id) async {
    try {
      final response = await apiClient.get("/properties/$id");
      final propertyResponse = SinglePropertyResponse.fromJson(response);
      return propertyResponse;
    } on DioException catch (e) {
      _handleError(e);
      return SinglePropertyResponse(
          success: false,
          message: "Failed to get property",
          data: SinglePropertyData());
    } on Exception catch (e) {
      return SinglePropertyResponse(
          success: false,
          message: "Failed to get property",
          data: SinglePropertyData());
    }
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
    try {
      final response = await apiClient.post("/host/delete-property", data: {
        "propertyId": id,
      });
      if (response["success"]) {
        return true;
      }
      return false;
    } on Exception catch (e) {
      return false;
    }
  }
}
