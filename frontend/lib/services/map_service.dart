import 'package:dio/dio.dart';

/// Custom exception for map-related operations
class MapException implements Exception {
  final String message;
  MapException(this.message);

  @override
  String toString() => 'MapException: $message';
}

/// Service class that handles requests to map-related backend functionality
class MapService {
  late final Dio _dio;

  MapService({String? baseUrl, Dio? dioClient}) {
    final String envUrl = const String.fromEnvironment('MAP_API_URL');
    final String resolvedUrl = (envUrl.isNotEmpty ? envUrl : baseUrl) ??
        'http://localhost:9090';

    print('\x1B[32m MapService using base URL: $resolvedUrl\x1B[0m');

    _dio = dioClient ??
        Dio(BaseOptions(
          baseUrl: resolvedUrl,
          headers: {'Content-Type': 'application/json'},
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ));
  }

  /// Example map method
  Future<List<List<double>>> getRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    try {
      final response = await _dio.get('/map/route', queryParameters: {
        'lat': fromLat,
        'lng': fromLng,
        'toLat': toLat,
        'toLng': toLng,
      });

      if (response.statusCode != 200) {
        throw MapException('Unexpected status: ${response.statusCode}');
      }

      final geometry = response.data['geometry'];
      final coords = List<List<double>>.from(
        geometry['coordinates'].map<List<double>>(
              (coord) => [coord[0].toDouble(), coord[1].toDouble()],
        ),
      );

      return coords;
    } on DioException catch (e) {
      throw MapException('Failed to fetch route: ${e.message}');
    }
  }
}