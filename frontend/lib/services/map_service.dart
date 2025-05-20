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
    return envUrl.isNotEmpty ? envUrl : (overrideUrl ?? 'http://192.168.1.69:9090');
  }

  /// Fetches route JSON between two points.
  Future<Map<String, dynamic>> getRoutesJson({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    required bool alternatives,
  }) async {
    print(
        'Requesting route(s) from ($fromLat, $fromLng) to ($toLat, $toLng) [alternatives=$alternatives]');
    try {
      final response = await _dio.get(
        '/map/route',
        queryParameters: {
          'lat': fromLat,
          'lng': fromLng,
          'toLat': toLat,
          'toLng': toLng,
          'alternatives': alternatives.toString(),
        },
      );

      if (response.statusCode != 200 || response.data == null) {
        throw MapException(
            'Failed to fetch route(s). Status: ${response.statusCode}');
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

  /// Extracts route coordinates (list of [longitude, latitude]) from the full JSON.
  /// Returns a list of routes, where each route is a list of coordinate pairs.
  Future<List<List<List<double>>>> getAllRoutesCoordinates({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    final data = await getRoutesJson(
      fromLat: fromLat,
      fromLng: fromLng,
      toLat: toLat,
      toLng: toLng,
      alternatives: true,
    );

    final routesList = data['routes'] as List<dynamic>?;

    if (routesList == null || routesList.isEmpty) {
      throw MapException('No routes found in response.');
    }

    final allCoordinates = <List<List<double>>>[];

    for (final route in routesList) {
      final geometry = route['geometry'];
      if (geometry == null ||
          geometry['coordinates'] == null ||
          geometry['coordinates'] is! List) {
        throw MapException(
            'Invalid route format: geometry or coordinates missing.');
      }

      final coords = List<List<double>>.from(
        (geometry['coordinates'] as List<dynamic>).map<List<double>>(
              (coord) {
            if (coord is List && coord.length >= 2 && coord[0] is num && coord[1] is num) {
              return [coord[0].toDouble(), coord[1].toDouble()];
            } else {
              throw MapException('Invalid coordinate format: $coord');
            }
          },
        ),
      );

      allCoordinates.add(coords);
    }

    print('[MapService] Extracted ${allCoordinates.length} route(s)');
    return allCoordinates;
  }
}
