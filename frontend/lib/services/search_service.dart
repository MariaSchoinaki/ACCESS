import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mapbox_feature.dart';

/// Custom exception for search-related errors
class SearchException implements Exception {
  /// A message describing the search error.
  final String message;
  /// Creates a [SearchException] with the given [message].
  SearchException(this.message);

  @override
  String toString() => 'SearchException: $message';
}

/// A service class responsible for handling search and geocoding queries
/// by communicating with a backend API (presumably providing Mapbox results or similar).
///
/// Uses the Dio package for HTTP requests and manages a persistent session token.
class SearchService {
  late final Dio _dio;

  // Session token
  String? _sessionToken;

  /// Initializes the [SearchService].
  ///
  /// Sets up the Dio client with a base URL. The base URL resolution priority is:
  /// 1. `--dart-define=SEARCH_API_URL=...` environment variable.
  /// 2. The optional [baseUrl] constructor parameter.
  /// 3. A default fallback URL (`http://ip:9090`).
  ///
  /// Also initializes the [_sessionToken].
  ///
  /// - [baseUrl]: An optional base URL for the backend API.
  /// - [dioClient]: An optional pre-configured Dio instance (useful for testing).
  SearchService({String? baseUrl, Dio? dioClient}) {
    final String envUrl = const String.fromEnvironment('SEARCH_API_URL');
    final String resolvedUrl = (envUrl.isNotEmpty ? envUrl : baseUrl) ??
        'http://ip:9090';

    print('\x1B[32m SearchService using base URL: $resolvedUrl\x1B[0m');

    _dio = dioClient ??
        Dio(BaseOptions(
          baseUrl: resolvedUrl,
          headers: {'Content-Type': 'application/json'},
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ));

    // Initialize the session token when the class is created
    _initializeSessionToken();
  }

  /// Initializes the session token.
  ///
  /// Attempts to load an existing session token from [SharedPreferences].
  /// If not found, generates a new UUID v4 token and saves it.
  Future<void> _initializeSessionToken() async {
    final prefs = await SharedPreferences.getInstance();
    _sessionToken = prefs.getString('session_token');

    if (_sessionToken == null) {
      _sessionToken = Uuid().v4();
      await prefs.setString('session_token', _sessionToken!);
    }
  }

  /// Executes a search request based on a text [query].
  ///
  /// Sends a GET request to the `/search` endpoint of the backend API.
  /// Includes the query and the session token as parameters.
  ///
  /// Returns a list of [MapboxFeature] objects parsed from the response.
  /// Throws a [SearchException] if the request fails or returns an unexpected status code.
  Future<List<MapboxFeature>> search(String query) async {
    try {
      final response = await _dio.get(
        '/search',
        queryParameters: {
          'q': query,
          'session_token': _sessionToken,
        },
      );

      if (response.statusCode != 200) {
        throw SearchException('Unexpected status code: ${response.statusCode}');
      }

      final features = List<Map<String, dynamic>>.from(
          response.data['results'] ?? []);

      print(response);
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

  /// Executes a search request based on a [category].
  ///
  /// Sends a GET request to the `/category` endpoint of the backend API.
  /// Includes the category and the session token as parameters.
  ///
  /// Returns a list of [MapboxFeature] objects parsed from the response.
  /// Throws a [SearchException] if the request fails or returns an unexpected status code.
  Future<List<MapboxFeature>> searchByCategory(String category, String? bbox) async {
    try {
      final response = await _dio.get(
        '/category', // Assuming this is your category search endpoint
        queryParameters: {
          'category': category,
          'bbox': bbox,
          'session_token': _sessionToken,
        },
      );

      if (response.statusCode != 200) {
        throw SearchException('Unexpected status code: ${response.statusCode}');
      }

      final features = List<Map<String, dynamic>>.from(
          response.data['results'] ?? []);

      print(response);
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

  /// Retrieves the details (likely including coordinates) for a feature identified by [mapboxId].
  ///
  /// Sends a GET request to the `/retrieve` endpoint of the backend API.
  /// Includes the mapbox_id and the session token as parameters.
  ///
  /// Returns a single [MapboxFeature] object parsed from the response.
  /// Throws a [SearchException] if the request fails or returns an unexpected status code.
  Future<MapboxFeature> retrieveCoordinates(String mapboxId) async {
    try {
      final response = await _dio.get(
        '/retrieve',
        queryParameters: {
          'mapbox_id': mapboxId,
          'session_token': _sessionToken,
        },
      );

      if (response.statusCode != 200) {
        throw SearchException('Unexpected status code: ${response.statusCode}');
      }

      final featureData = response.data['result'];
      print(featureData);
      return MapboxFeature.fromJson(featureData);

    } on DioException catch (e) {
      print('[SearchService] DioException');
      print('    • type: ${e.type}');
      print('    • error: ${e.error}');
      print('    • response: ${e.response}');
      print('    • message: ${e.message}');
      throw SearchException(e.message ?? 'Dio error: ${e.error}');
    }
  }

  /// Retrieves address/feature information for given coordinates (reverse geocoding).
  ///
  /// Sends a GET request to the `/getname` endpoint of the backend API.
  /// Includes the [latitude] and [longitude] as parameters.
  ///
  /// Returns a single [MapboxFeature] object parsed from the response,
  /// typically containing address details.
  /// Throws a [SearchException] if the request fails or returns an unexpected status code.
  Future<MapboxFeature> retrieveNameFromCoordinates(double latitude, double longitude) async {
    try {
      final response = await _dio.get(
        '/getname',
        queryParameters: {
          'lat': latitude,
          'lng': longitude,
        },
      );

      if (response.statusCode != 200) {
        throw SearchException('Unexpected status code: ${response.statusCode}');
      }
      print(response.data);
      final featureData = response.data['result'];
      print(featureData);
      return MapboxFeature.fromJson(featureData);

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