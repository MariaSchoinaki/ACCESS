import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';  // Εισάγουμε το uuid package
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mapbox_feature.dart';

/// Custom exception for search-related errors
class SearchException implements Exception {
  final String message;
  SearchException(this.message);

  @override
  String toString() => 'SearchException: $message';
}

/// A service class that handles search queries through a backend API
class SearchService {
  late final Dio _dio;

  // Session token
  String? _sessionToken;

  /// Initializes the Dio client with a base URL.
  /// Priority: --dart-define > Constructor argument > Default
  SearchService({String? baseUrl, Dio? dioClient}) {
    final String envUrl = const String.fromEnvironment('SEARCH_API_URL');
    final String resolvedUrl = (envUrl.isNotEmpty ? envUrl : baseUrl) ??
        'http://192.168.1.69:9090';

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

  // Initialize or retrieve session token from SharedPreferences
  Future<void> _initializeSessionToken() async {
    final prefs = await SharedPreferences.getInstance();
    _sessionToken = prefs.getString('session_token');

    if (_sessionToken == null) {
      _sessionToken = Uuid().v4();  // Create new UUID for session
      await prefs.setString('session_token', _sessionToken!);
    }
  }

  /// Executes a search request and returns a list of Mapbox features
  Future<List<MapboxFeature>> search(String query) async {
    try {
      final response = await _dio.get(
        '/search',
        queryParameters: {
          'q': query,
          'session_token': _sessionToken,  // Send session token as query parameter
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

  Future<MapboxFeature> retrieveCoordinates(String mapboxId) async {
    try {
      final response = await _dio.get(
        '/retrieve',  // Διεύθυνση του endpoint για retrieve
        queryParameters: {
          'mapbox_id': mapboxId,  // Το mapbox_id της επιλεγμένης τοποθεσίας
          'session_token': _sessionToken,  // Αν απαιτείται το session_token
        },
      );

      if (response.statusCode != 200) {
        throw SearchException('Unexpected status code: ${response.statusCode}');
      }

      final featureData = response.data['result'];
      print(featureData);// Παίρνουμε τα δεδομένα του πρώτου αποτελέσματος
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
