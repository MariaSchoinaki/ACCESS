import 'package:dio/dio.dart';

/// Exception for map-related errors.
class MapException implements Exception {
  final String message;
  MapException(this.message);

  @override
  String toString() => 'MapException: $message';
}

/// A service to handle fetching route data from the backend.
class MapService {
  final Dio _dio;

  /// Initializes the service.
  ///
  /// Priority for base URL:
  /// 1. --dart-define=MAP_API_URL
  /// 2. [baseUrl] parameter
  /// 3. Fallback to 'http://localhost:9090'
  MapService({String? baseUrl, Dio? dioClient})
      : _dio = dioClient ??
      Dio(
        BaseOptions(
          baseUrl: _resolveBaseUrl(baseUrl),
          headers: {'Content-Type': 'application/json'},
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      ) {
    print('\x1B[32m[MapService] Base URL: ${_dio.options.baseUrl}\x1B[0m');
  }

  static String _resolveBaseUrl(String? overrideUrl) {
    const envUrl = String.fromEnvironment('SEARCH_API_URL');
    return envUrl.isNotEmpty ? envUrl : (overrideUrl ?? 'http://ip:9090');
  }

  /// Fetches the full route JSON between two points.
  Future<Map<String, dynamic>> getFullRouteJson({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    print('Requesting route from ($fromLat, $fromLng) to ($toLat, $toLng)');
    try {
      final response = await _dio.get(
        '/map/route',
        queryParameters: {
          'lat': fromLat,
          'lng': fromLng,
          'toLat': toLat,
          'toLng': toLng,
        },
      );

      if (response.statusCode != 200 || response.data == null) {
        throw MapException(
            'Failed to fetch route. Status: ${response.statusCode}');
      }

      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      print('[MapService] DioException: ${e.message}');
      throw MapException(
          e.response?.data?['error'] ?? e.message ?? 'Route fetch error');
    } catch (e) {
      print('Unexpected error: $e');
      if (e is MapException) rethrow;
      throw MapException('Unexpected error fetching the route.');
    }
  }

  /// Optional: Extracts route coordinates [longitude, latitude] from the full JSON.
  Future<List<List<double>>> getRouteCoordinates({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    final data = await getFullRouteJson(
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
    );

    final geometry = data['geometry'];
    if (geometry == null ||
        geometry['coordinates'] == null ||
        geometry['coordinates'] is! List) {
      throw MapException(
          'Invalid response: geometry or coordinates missing/invalid.');
    }

    return List<List<double>>.from(
      (geometry['coordinates'] as List<dynamic>).map<List<double>>(
            (coord) {
          if (coord is List &&
              coord.length >= 2 &&
              coord[0] is num &&
              coord[1] is num) {
            return [coord[0].toDouble(), coord[1].toDouble()];
          } else {
            throw MapException('Invalid coordinate format: $coord');
          }
        },
      ),
    );
  }
}
