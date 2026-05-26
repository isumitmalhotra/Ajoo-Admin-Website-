
import 'package:rent_home/data/source/remote/api_client/api_client.dart';
import 'package:rent_home/data/models/search_property_model.dart';

class HomePageSearchService {
  final ApiClient apiClient = ApiClient();
  HomePageSearchService();
  Future<SearchResponse> searchProperty(String query) async {
    final data = {
      "query": query,
      "longitude": "",
      "latitude": "",
      "sort_by": "property_id",
      "order": "desc",
      "limit": 10,
      "offset": 0,
      "radius": 10
    };
    try {
      final response = await apiClient.post("/properties/list", data: data);
      return SearchResponse.fromJson(response);
    } catch (e) {
      throw e;
    }
  }

  Future<SearchResponse> getPreBooking({bool isLuxury = false}) async {
    final data = {
      "query": "",
      "longitude": "",
      "latitude": "",
      "sort_by": "property_id",
      "order": "desc",
      "limit": 10,
      "offset": 0,
      "radius": 10,
      "isLuxury": isLuxury
    };
    try {
      final response = await apiClient.post("/properties/list", data: data);
      return SearchResponse.fromJson(response);
    } catch (e) {
      throw e;
    }
  }
}
