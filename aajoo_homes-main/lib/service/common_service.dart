import 'dart:math';

import 'package:flutter/material.dart';
import 'package:rent_home/data/source/remote/api_client/api_client.dart';
import 'package:rent_home/data/models/amenities_model.dart';
import 'package:rent_home/data/models/category_response_model.dart';
import 'package:rent_home/data/models/doc_type_response_model.dart';
import 'package:rent_home/data/models/tags_model.dart';

class CommonService {
  final ApiClient apiClient = ApiClient();

  CommonService() {}

  Future<AmenitiesResponse> getAmenities() async {
    try {
      final response = await apiClient.get('/common/amenties');
      // print(response.data);
      return AmenitiesResponse.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load amenities: $e');
    }
  }

  Future<CategoryResponse> getCategories() async {
    try {
      final response = await apiClient.get('/common/categories');
      return CategoryResponse.fromJson(response);
    } catch (err) {
      throw Exception('Failed to load categories: $err');
    }
  }

  Future<TagsResponse> getTags() async {
    try {
      final response = await apiClient.get('/common/tags');
      return TagsResponse.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load tags: $e');
    }
  }

  Future<DocTypeResponse> getDocTypes() async {
    try {
      final response = await apiClient.get('/common/documents/list');
      return DocTypeResponse.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load document types: $e');
    }
  }

  Color generateRandomColorWithOpacity() {
    final random = Random();
    return Color.fromRGBO(
      random.nextInt(256), // Random red (0-255)
      random.nextInt(256), // Random green (0-255)
      random.nextInt(256), // Random blue (0-255)
      0.2, // Fixed opacity
    );
  }
}
