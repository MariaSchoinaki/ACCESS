import 'package:dio/dio.dart';

/// Custom exception thrown for errors related to map service operations.
class MapException implements Exception {
  /// A message describing the map-related error.
  final String message;

  /// Creates a [MapException] with the given [message].
  MapException(this.message);

  @override
  String toString() => 'MapException: $message';
}

/// A service class responsible for handling requests related to map functionalities,
/// such as fetching route data from a backend API.
///
/// Uses the Dio package for HTTP requests.
class MapService {
  /// The Dio instance used for making HTTP requests.
  late final Dio _dio;

  /// Initializes the [MapService].
  ///
  /// Sets up the Dio client with a base URL. The base URL resolution priority is:
  /// 1. `--dart-define=MAP_API_URL=...` environment variable.
  /// 2. The optional [baseUrl] constructor parameter.
  /// 3. A default fallback URL (`http://localhost:9090`).
  ///
  /// - [baseUrl]: An optional base URL for the map backend API.
  /// - [dioClient]: An optional pre-configured Dio instance (useful for testing).
  MapService({String? baseUrl, Dio? dioClient}) {
    // Determine the base URL based on priority
    final String envUrl = const String.fromEnvironment('MAP_API_URL');
    final String resolvedUrl = (envUrl.isNotEmpty ? envUrl : baseUrl) ??
        'http://localhost:9090'; // Default fallback

    // Log the final URL being used
    print('\x1B[32m MapService using base URL: $resolvedUrl\x1B[0m'); // Green text

    // Initialize Dio
    _dio = dioClient ??
        Dio(BaseOptions(
          baseUrl: resolvedUrl,
          headers: {'Content-Type': 'application/json'},
          connectTimeout: const Duration(seconds: 10), // Slightly longer timeout for routes
          receiveTimeout: const Duration(seconds: 10),
        ));
  }

  /// Fetches route geometry data from the backend API between two points.
  ///
  /// Sends a GET request to the `/map/route` endpoint with the start and end
  /// coordinates as query parameters. Assumes the backend returns a JSON object
  /// containing a `geometry` field, which in turn has a `coordinates` field
  /// holding a list of `[longitude, latitude]` pairs.
  ///
  /// - [fromLat]: Latitude of the starting point.
  /// - [fromLng]: Longitude of the starting point.
  /// - [toLat]: Latitude of the destination point.
  /// - [toLng]: Longitude of the destination point.
  ///
  /// Returns a `Future` completing with a list of coordinate pairs `[[longitude, latitude], ...]`,
  /// representing the points along the route.
  ///
  /// Throws a [MapException] if the request fails, returns an unexpected status code,
  /// or if the response data is not in the expected format.
  Future<List<List<double>>> getRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    print('Fetching route from ($fromLat, $fromLng) to ($toLat, $toLng)');
    try {
      final response = await _dio.get(
          '/map/route', // Assuming this is the correct endpoint
          queryParameters: {
            'lat': fromLat,
            'lng': fromLng,
            'toLat': toLat,
            'toLng': toLng,
          });

      // Check for successful status code and non-null data
      if (response.statusCode != 200 || response.data == null) {
        throw MapException(
            'Failed to fetch route. Status code: ${response.statusCode}');
      }

      // Extract geometry and coordinates, assuming specific JSON structure
      // Add more robust checking if the structure might vary
      final geometry = response.data['geometry'];
      if (geometry == null || geometry['coordinates'] == null || geometry['coordinates'] is! List) {
        throw MapException('Invalid route response format: geometry or coordinates missing/invalid.');
      }

      // Convert the list of dynamic coordinates to List<List<double>>
      // Handles potential type errors during conversion.
      final coords = List<List<double>>.from(
        (geometry['coordinates'] as List<dynamic>).map<List<double>>(
              (coord) {
            // Ensure coord is a list with at least 2 numbers
            if (coord is List && coord.length >= 2 && coord[0] is num && coord[1] is num) {
              // Ensure correct order [longitude, latitude]
              return [coord[0].toDouble(), coord[1].toDouble()];
            } else {
              // Throw error if format is incorrect
              throw MapException('Invalid coordinate format in route response: $coord');
            }
          } ,
        ),
      );

      print('Route fetched successfully with ${coords.length} points.');
      return coords;

    } on DioException catch (e) {
      // Handle Dio-specific errors
      print('[MapService] DioException during getRoute:');
      print('    • type: ${e.type}');
      print('    • error: ${e.error}');
      print('    • response status: ${e.response?.statusCode}');
      print('    • message: ${e.message}');
      // Rethrow as a MapException, trying to get backend error message
      throw MapException(e.response?.data?['error'] ?? e.message ?? 'Failed to fetch route: ${e.error}');
    } catch (e) {
      // Catch other errors, including potential format errors during parsing
      print("Unexpected error during getRoute: $e");
      // If it's already a MapException (e.g., from parsing), rethrow it
      if (e is MapException) {
        rethrow;
      }
      // Otherwise wrap it
      throw MapException('An unexpected error occurred while fetching the route.');
    }
  }
}