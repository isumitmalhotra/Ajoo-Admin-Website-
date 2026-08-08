import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:rent_home/models/amenities_model.dart';
import 'package:rent_home/models/category_response_model.dart';
import 'package:rent_home/models/doc_type_response_model.dart';
import 'package:rent_home/models/tags_model.dart';

class CommonService {
  final Dio _dio = Dio();
  final String baseUrl = 'https://aajaodev.onrender.com/';

  CommonService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.contentType = 'application/json';
  }

  Future<AmenitiesResponse> getAmenities() async {
    try {
      final response = await _dio.get('common/amenties');
      // print(response.data);
      return AmenitiesResponse.fromJson(response.data);
    } catch (e) {
      print(e);
      throw Exception('Failed to load amenities: $e');
    }
  }

  Future<CategoryResponse> getCategories() async {
    try {
      final response = await _dio.get('common/categories');
      // print(response.data);
      return CategoryResponse.fromJson(response.data);
    } catch (err) {
      print(err);
      throw Exception('Failed to load categories: $err');
    }
  }

  Future<TagsResponse> getTags() async {
    try {
      final response = await _dio.get('common/tags');
      // print(response.data);
      return TagsResponse.fromJson(response.data);
    } catch (e) {
      print(e);
      throw Exception('Failed to load tags: $e');
    }
  }

  Future<DocTypeResponse> getDocTypes() async {
    try {
      final response = await _dio.get('common/documents/list');
      // print(response.data);
      return DocTypeResponse.fromJson(response.data);
    } catch (e) {
      print(e);
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
