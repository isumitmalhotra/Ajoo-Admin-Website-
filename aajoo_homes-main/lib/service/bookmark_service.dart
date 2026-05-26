import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rent_home/data/models/properties_response_model.dart';

class BookmarkService {
  final _storage = const FlutterSecureStorage();
  static const _bookmarkKey = 'bookmarked_properties';
  List<Property> _bookmarkedProperties = [];

  /// Adds a property to the bookmark list.
  /// If the property is already bookmarked, it won't be added again.
  Future<void> addBookmark(Property property) async {
    try {
      // Retrieve existing bookmarks
      await _loadBookmarks();

      // Check if property is already bookmarked
      if (_bookmarkedProperties
          .any((p) => p.propertyId == property.propertyId)) {
        return; // Property already bookmarked, no action needed
      }

      // Add new property to the list
      _bookmarkedProperties.add(property);

      // Convert the list to JSON
      final data = Data(property: _bookmarkedProperties);
      final response = PropertiesResponse(
        success: true,
        message: 'Bookmarked properties',
        data: data,
      );
      final jsonString = propertiesResponseToJson(response);

      // Store in secure storage
      await _storage.write(key: _bookmarkKey, value: jsonString);
    } catch (e) {
      print('Error adding bookmark: $e');
      throw Exception('Failed to add bookmark');
    }
  }

  /// Removes a property from the bookmark list by its propertyId.
  Future<void> removeBookmark(int propertyId) async {
    try {
      // Retrieve existing bookmarks
      await _loadBookmarks();

      // Remove the property with the given ID
      _bookmarkedProperties.removeWhere((p) => p.propertyId == propertyId);

      // Convert the updated list to JSON
      final data = Data(property: _bookmarkedProperties);
      final response = PropertiesResponse(
        success: true,
        message: 'Bookmarked properties',
        data: data,
      );
      final jsonString = propertiesResponseToJson(response);

      // Store the updated list in secure storage
      await _storage.write(key: _bookmarkKey, value: jsonString);
    } catch (e) {
      print('Error removing bookmark: $e');
      throw Exception('Failed to remove bookmark');
    }
  }

  /// Retrieves the list of bookmarked properties.
  Future<List<Property>> getBookmarks() async {
    try {
      await _loadBookmarks();
      return _bookmarkedProperties;
    } catch (e) {
      print('Error retrieving bookmarks: $e');
      return [];
    }
  }

  /// Checks if a property is bookmarked by its propertyId.
  Future<bool> isBookmarked(int propertyId) async {
    try {
      await _loadBookmarks();
      return _bookmarkedProperties.any((p) => p.propertyId == propertyId);
    } catch (e) {
      print('Error checking bookmark: $e');
      return false;
    }
  }

  /// Clears all bookmarked properties.
  Future<void> clearBookmarks() async {
    try {
      _bookmarkedProperties.clear();
      await _storage.delete(key: _bookmarkKey);
    } catch (e) {
      print('Error clearing bookmarks: $e');
      throw Exception('Failed to clear bookmarks');
    }
  }

  /// Loads bookmarks from secure storage into _bookmarkedProperties.
  Future<void> _loadBookmarks() async {
    try {
      final jsonString = await _storage.read(key: _bookmarkKey);
      if (jsonString == null) {
        _bookmarkedProperties = [];
        return;
      }
      final response = propertiesResponseFromJson(jsonString);
      _bookmarkedProperties = response.data.property;
    } catch (e) {
      print('Error loading bookmarks: $e');
      _bookmarkedProperties = [];
    }
  }

  List<Property> get bookmarkedProperties => _bookmarkedProperties;
}
