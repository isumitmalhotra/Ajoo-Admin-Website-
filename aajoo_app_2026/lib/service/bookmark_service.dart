import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rent_home/models/properties_response_model.dart';
import 'package:flutter/foundation.dart';
import 'package:rent_home/data/ApiConstants.dart';

/// Backend-synced bookmark store.
///
/// Bookmarks live on the server (`tbl_saved_liked_prop`), keyed to the
/// logged-in user. This service:
///   - calls `POST /properties/user-saveProp` to TOGGLE save/unsave
///   - calls `POST /user/saved-properties` to load the user's saved list
///   - maintains an in-memory cache of saved propertyIds so
///     [isBookmarked] is synchronous and cheap to call from list tiles
///     (avoids one HTTP round trip per property card)
///
/// Cache is invalidated explicitly via [clearCache] on logout. The first
/// [getBookmarks] / [isBookmarked] call after that re-fetches from backend.
class BookmarkService {
  static final BookmarkService _instance = BookmarkService._internal();
  factory BookmarkService() => _instance;
  BookmarkService._internal();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: Apiconstants.baseUrl,
    contentType: 'application/json',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 12),
  ));

  final _storage = const FlutterSecureStorage();

  // In-memory caches — populated lazily from backend on first read.
  List<Property> _bookmarkedProperties = [];
  Set<int> _bookmarkedIds = {};
  bool _loaded = false;

  /// Bumped every time a stay is saved or unsaved, from anywhere.
  ///
  /// The Saved tab lives inside the shell's IndexedStack, so its initState —
  /// which does force-refresh — runs ONCE, at app start, when the list was
  /// whatever it was then. Saving a stay and switching to the tab showed the
  /// list from startup: "No saved stays yet" over a save that had reached the
  /// server perfectly well. Listening to this means the tab reloads when the
  /// set actually changes, wherever the heart was tapped.
  final ValueNotifier<int> revision = ValueNotifier<int>(0);

  /// Returns the cached list (synchronously). Useful for sync UI like a
  /// property card that already called [getBookmarks] on mount.
  List<Property> get bookmarkedProperties =>
      List.unmodifiable(_bookmarkedProperties);

  /// Saved right now, from the cache, with no round trip.
  ///
  /// [isBookmarked] is a Future despite what the class comment claims, so a
  /// card could not ask during build — which is why every heart in the product
  /// was drawn as an outline whether the stay was saved or not.
  bool isSavedNow(int? propertyId) =>
      propertyId != null && _bookmarkedIds.contains(propertyId);

  Future<void> _attachAuth() async {
    final token = await _storage.read(key: 'user_token');
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Toggles save/unsave for [propertyId]. The backend is a single endpoint
  /// that flips between saved (`isSave=1`) and unsaved (`isSave=0`), so we
  /// can't tell from the request alone which direction it went — we use the
  /// local cache to predict and then trust the next [getBookmarks] to
  /// reconcile if anything diverges.
  ///
  /// Returns true on success.
  Future<bool> toggleBookmark(Property property) async {
    await _attachAuth();
    try {
      final response = await _dio.post(
        '/properties/user-saveProp',
        data: {'propId': property.propertyId},
      );
      final ok = response.statusCode == 200 &&
          response.data is Map &&
          response.data['success'] == true;
      if (!ok) {
        // ignore: avoid_print
        print('toggleBookmark non-ok: ${response.data}');
        return false;
      }

      // Mirror the toggle locally so isBookmarked() reflects it immediately.
      if (_bookmarkedIds.contains(property.propertyId)) {
        _bookmarkedIds.remove(property.propertyId);
        _bookmarkedProperties.removeWhere(
          (p) => p.propertyId == property.propertyId,
        );
      } else {
        _bookmarkedIds.add(property.propertyId);
        _bookmarkedProperties.insert(0, property);
      }
      revision.value++;
      return true;
    } on DioException catch (e) {
      // ignore: avoid_print
      print('toggleBookmark error: ${e.message}');
      return false;
    } catch (e) {
      // ignore: avoid_print
      print('toggleBookmark unexpected: $e');
      return false;
    }
  }

  /// Add semantics — same as toggle if not already saved. No-op if saved.
  Future<bool> addBookmark(Property property) async {
    if (_loaded && _bookmarkedIds.contains(property.propertyId)) {
      return true;
    }
    return toggleBookmark(property);
  }

  /// Remove semantics — same as toggle if saved. No-op if not saved.
  Future<bool> removeBookmark(int propertyId) async {
    if (_loaded && !_bookmarkedIds.contains(propertyId)) {
      return true;
    }
    // Reconstruct a minimal Property for the toggle (only ID matters server-side).
    final existing = _bookmarkedProperties.firstWhere(
      (p) => p.propertyId == propertyId,
      orElse: () => Property.fromJson({'property_id': propertyId}),
    );
    return toggleBookmark(existing);
  }

  /// Fetches the user's bookmarks from the backend and refreshes the cache.
  /// Returns the cached list on network failure (best-effort, no exception).
  Future<List<Property>> getBookmarks({bool forceRefresh = false}) async {
    if (_loaded && !forceRefresh) return bookmarkedProperties;

    await _attachAuth();
    try {
      final response = await _dio.post(
        '/user/saved-properties',
        data: <String, dynamic>{}, // pagination optional
      );
      if (response.statusCode == 200 &&
          response.data is Map &&
          response.data['success'] == true) {
        final data = response.data['data'];
        final rawList = (data is Map ? data['property'] : null) ?? const [];
        final List<Property> parsed = [];
        if (rawList is List) {
          for (final item in rawList) {
            if (item is Map<String, dynamic>) {
              try {
                parsed.add(Property.fromJson(item));
              } catch (_) {
                // Skip malformed rows rather than killing the whole load.
              }
            }
          }
        }
        _bookmarkedProperties = parsed;
        _bookmarkedIds = parsed.map((p) => p.propertyId).toSet();
        _loaded = true;
        return bookmarkedProperties;
      }
      // ignore: avoid_print
      print('getBookmarks non-ok: ${response.data}');
      return bookmarkedProperties;
    } on DioException catch (e) {
      // ignore: avoid_print
      print('getBookmarks error: ${e.message}');
      return bookmarkedProperties;
    } catch (e) {
      // ignore: avoid_print
      print('getBookmarks unexpected: $e');
      return bookmarkedProperties;
    }
  }

  /// Synchronous-after-load lookup. Returns false if cache hasn't been
  /// primed yet — callers that need certainty should `await getBookmarks()`
  /// first, then read [bookmarkedProperties] / call this.
  Future<bool> isBookmarked(int propertyId) async {
    if (!_loaded) {
      await getBookmarks();
    }
    return _bookmarkedIds.contains(propertyId);
  }

  /// Wipe the in-memory cache. Call on logout so the next user doesn't see
  /// the previous user's bookmarks.
  Future<void> clearCache() async {
    _bookmarkedProperties = [];
    _bookmarkedIds = {};
    _loaded = false;
  }

  /// Back-compat alias (legacy code calls `clearBookmarks()`).
  Future<void> clearBookmarks() => clearCache();
}
