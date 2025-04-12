import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/mapbox_feature.dart';

class SearchService {
  final String _baseUrl;

  /// Creates a SearchService that points to a local or remote backend.
  SearchService({String? baseUrl})
      : _baseUrl = baseUrl ?? 'http://localhost:8080';

  /// Sends a GET request to the backend microservice to perform a search.
  /// Returns a list of [MapboxFeature]s parsed from the backend response.
  Future<List<MapboxFeature>> search(String query) async {
    final url = Uri.parse('$_baseUrl/search?q=$query');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      // Ensure results exist and are properly formatted
      final features = List<Map<String, dynamic>>.from(decoded['results'] ?? []);

      return features.map((json) => MapboxFeature.fromJson(json)).toList();
    } else {
      throw Exception('Search failed: ${response.body}');
    }
  }
}
