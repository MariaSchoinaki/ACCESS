import 'package:dio/dio.dart';
import 'dart:convert';
import '../models/mapbox_feature.dart';

/// Custom exception for search-related errors
class SearchException implements Exception {
  final String message;
  SearchException(this.message);

  @override
  String toString() => 'SearchException: \$message';
}

/// A service class that handles search queries through a backend API
class SearchService {
  late final Dio _dio;

  /// Initializes the Dio client with a base URL.
  /// Priority: --dart-define > Constructor argument > Default
  SearchService({String? baseUrl, Dio? dioClient}) {
    final String envUrl = const String.fromEnvironment('SEARCH_API_URL');
    final String resolvedUrl = (envUrl.isNotEmpty ? envUrl : baseUrl) ??
        'http://localhost:9090';

    print('\x1B[32m SearchService using base URL: $resolvedUrl\x1B[0m');

    _dio = dioClient ??
        Dio(BaseOptions(
          baseUrl: resolvedUrl,
          headers: {'Content-Type': 'application/json'},
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ));
  }

  /// Executes a search request and returns a list of Mapbox features
  Future<List<MapboxFeature>> search(String query) async {

    try {
      final response = await _dio.get(
        '/search',
        queryParameters: {'q': query},
      );


      if (response.statusCode != 200) {
        throw SearchException('Unexpected status code: ${response.statusCode}');
      }

      final features = List<Map<String, dynamic>>.from(
          response.data['results'] ?? []);

      return features.map((json) => MapboxFeature.fromJson(json)).toList();
      } on DioException catch (e) {
        print('[SearchService] DioException');
        print('    • type: ${e.type}');
        print('    • error: ${e.error}');
        print('    • response: ${e.response}');
        print('    • message: ${e.message}');
    throw SearchException(e.message ?? 'Dio error: ${e.error}');
    }
  }
}
