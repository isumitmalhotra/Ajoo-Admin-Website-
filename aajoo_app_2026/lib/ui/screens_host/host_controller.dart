import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:rent_home/controller/alert_dialog.dart';
import 'package:rent_home/data/models/host_booking_history_model.dart';
import 'package:rent_home/data/models/host_ongoing_response.dart';
import 'package:rent_home/models/host_negotiation.dart';
import 'package:rent_home/data/models/host_properties_reponse.dart';
import 'package:rent_home/data/models/transaction_model.dart';
import 'package:rent_home/service/host_service.dart';
import 'package:rent_home/service/property_service.dart';

class HostController extends GetxController {
  final HostService hostService = HostService();
  final PropertyService propertyService = PropertyService();
  final storage = const FlutterSecureStorage();
  RxBool loading = false.obs;
  RxString error = ''.obs;

  // Per-resource fetch flags. Lets each list UI distinguish "still loading"
  // from "fetched but empty/error" without depending on the shared `loading`
  // flag (which is reused across endpoints and causes flicker).
  final RxBool propertiesFetched = false.obs;
  final RxBool ongoingFetched = false.obs;
  final RxBool transactionsFetched = false.obs;
  Rx<HostOnGoingBookingResponse?> HostOngoingResponse =
      Rx<HostOnGoingBookingResponse?>(null);
  Rx<HostPropertiesResponse?> hostPropertiesResponse =
      Rx<HostPropertiesResponse?>(null);
  /// Separate from `loading` so appending a page doesn't replace the list
  /// already on screen with a shimmer.
  final RxBool loadingMore = false.obs;
  final RxString propertySearch = ''.obs;

  /// How many listings the host owns, across all pages. `properties.length` is
  /// one page — 20 where this is 29,230 for the test host.
  int get hostPropertyCount =>
      hostPropertiesResponse.value?.data?.totalCount ?? 0;
  bool get hasMoreProperties =>
      hostPropertiesResponse.value?.data?.hasMore ?? false;

  Rx<TransactionResponse?> transactionHistoryResponse =
      Rx<TransactionResponse?>(null);
  String TOKEN_KEY = 'user_token';
  Rx<File?> coverImage = Rx<File?>(null);

  Rx<HostBookingHistoryResponse?> hostBookingHistoryResponse =
      Rx<HostBookingHistoryResponse?>(null);

  /// Negotiations addressed to this host, newest first (A-70).
  final RxList<HostNegotiation> negotiations = <HostNegotiation>[].obs;
  final RxBool negotiationsFetched = false.obs;

  Future<void> _initialize() async {
    final token = await storage.read(key: TOKEN_KEY);
    hostService.setToken(token ?? '');
  }

  @override
  void onInit() {
    super.onInit();
    _initialize();
  }

  Future<void> getHostBookingHistory() async {
    try {
      loading.value = true;
      final response = await hostService.getBookingHistory();
      hostBookingHistoryResponse.value = response;
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  /// Every offer waiting on this host (A-70). Never throws — the service
  /// returns an empty list on failure, and an empty negotiations section is a
  /// correct dashboard.
  Future<void> getNegotiations() async {
    negotiationsFetched.value = false;
    negotiations.value = await hostService.getNegotiations();
    negotiationsFetched.value = true;
  }

  Future<void> getTransactionHistory() async {
    try {
      loading.value = true;
      final response = await hostService.getHostTransactions();
      transactionHistoryResponse.value = response;
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
      transactionsFetched.value = true;
    }
  }

  Future<bool> updateCoverImage(int id) async {
    final picked = coverImage.value;
    if (picked == null) {
      showSnackbar("No image selected", "Pick an image first", true);
      return false;
    }
    loading.value = true;
    try {
      final ok =
          await propertyService.updatePropertyCoverImage(id, picked);
      if (ok) {
        showSnackbar("Image Updated Successfully", "", false);
        // Refresh so the new cover shows in the list immediately.
        await getHostProperties();
      } else {
        showSnackbar("Something went Wrong", "error updating image", true);
      }
      return ok;
    } catch (e) {
      error.value = e.toString();
      showSnackbar(e.toString(), "Error updating image", true);
      return false;
    } finally {
      loading.value = false;
    }
  }

  Future<bool> updatePropertyStatus(int propId, int status) async {
    loading.value = true;
    try {
      final response = await hostService.updatePropertyStatus(propId, status);
      if (response) {
        showSnackbar("Property Status Updated Successfully", "", false);
        await getHostProperties();
      } else {
        showSnackbar(
            "Something went Wrong", "error updating property status", true);
      }
      return response;
    } catch (e) {
      error.value = e.toString();
      showSnackbar(e.toString(), "Error updating property status", true);
      return false;
    } finally {
      loading.value = false;
    }
  }

  /// First page of the host's listings. /host/property-search is paginated —
  /// it used to return all 29,230 rows (38 MB) for the test host.
  Future<void> getHostProperties({String? q}) async {
    try {
      loading.value = true;
      propertySearch.value = q ?? "";
      final response = await hostService.getHostProperties(page: 1, q: q);
      hostPropertiesResponse.value = response;
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
      propertiesFetched.value = true;
    }
  }

  /// Append the next page. No-op while one is in flight or the list is complete.
  Future<void> loadMoreHostProperties() async {
    final current = hostPropertiesResponse.value?.data;
    if (current == null || loadingMore.value || !current.hasMore) return;
    try {
      loadingMore.value = true;
      final next = await hostService.getHostProperties(
        page: current.page + 1,
        q: propertySearch.value.isEmpty ? null : propertySearch.value,
      );
      final more = next.data;
      if (more == null) return;
      hostPropertiesResponse.value = next.copyWith(
        data: more.copyWith(
          properties: [...current.properties, ...more.properties],
        ),
      );
    } catch (e) {
      error.value = e.toString();
    } finally {
      loadingMore.value = false;
    }
  }

  Future<bool> deleteProperty(int id) async {
    loading.value = true;
    try {
      final response = await propertyService.deleteProperty(id);
      if (response) {
        showSnackbar("Property Deleted Successfully", "", false);
        await getHostProperties();
      } else {
        showSnackbar("Something went Wrong", "error deleting property", true);
      }
      return response;
    } catch (e) {
      error.value = e.toString();
      showSnackbar("Error deleting property", e.toString(), true);
      return false;
    } finally {
      loading.value = false;
    }
  }

  Future<void> getHostOngoing(int hostId) async {
    await _initialize();

    try {
      loading.value = true;
      final response = await hostService.getHostOngoing(hostId);
      HostOngoingResponse.value = response;
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
      ongoingFetched.value = true;
    }
  }

  Future<void> addUserReview(
      int rating, String id, String description, String title) async {
    loading.value = true;
    try {
      final response =
          await hostService.addUserReview(rating, id, description, title);
      if (response) {
        showSnackbar("Review Added Successfully", "", false);
      } else {
        showSnackbar("Something went Wrong", "error adding review", true);
      }
    } catch (e) {
      error.value = e.toString();
      showSnackbar(e.toString(), "Error adding review", true);
    } finally {
      loading.value = false;
    }
  }

  void showSnackbar(String title, String message, bool isError) {
    showAlert(title, message, isError);
  }
}
