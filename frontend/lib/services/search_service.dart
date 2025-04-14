import 'package:dio/dio.dart';
import 'dart:convert';
import '../models/mapbox_feature.dart';

class SearchService {
  late final Dio _dio;

  SearchService({String? baseUrl}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? 'http://192.168.1.11:8080',
      headers: {'Content-Type': 'application/json'},
    ));
  }

  Future<List<MapboxFeature>> search(String query) async {
    try {
      final response = await _dio.get(
        '/search',
        queryParameters: {'q': query},
      );

      final features = List<Map<String, dynamic>>.from(response.data['results'] ?? []);
      return features.map((json) => MapboxFeature.fromJson(json)).toList();
    } on DioException catch (e) {
      throw Exception('Search failed: ${e.response?.data ?? e.message}');
    }
  }
}
