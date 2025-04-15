import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:dio/dio.dart' as dio;

/// Handles the search API request using Mapbox Geocoding API
Future<Response> handleSearchRequest(Request request) async {
  // Get the "q" parameter from the query string (e.g. /search?q=Athens)
  final query = request.url.queryParameters['q'];

  // If the query is missing or empty, return an error response
  if (query == null || query.isEmpty) {
    return Response.badRequest(
      body: jsonEncode({'error': 'Missing query parameter "q"'}),
    );
  }

  // Create a Dio client instance
  final dioBackend = dio.Dio();

  // Retrieve the Mapbox token from environment variables
  final mapboxToken = Platform.environment['MAPBOX_TOKEN'] ?? '';

  // Construct the Mapbox geocoding endpoint
  final url = 'https://api.mapbox.com/geocoding/v5/mapbox.places/$query.json';

  try {
    // Make the GET request to Mapbox API
    final response = await dioBackend.get(
      url,
      queryParameters: {'access_token': mapboxToken},
    );

    print('> response status: ${response.statusCode}');
    // If Mapbox responds with an error status
    if (response.statusCode != 200) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch data from Mapbox'}),
      );
    }
    print('> Received query: $query');
    print('> Geocoding response: ${response.data}');

    // Return the geocoding results as JSON
    return Response.ok(
      jsonEncode({'results': response.data['features']}),
      headers: {'Content-Type': 'application/json'},
    );
  } on dio.DioException catch (e) {
    // Handle errors from Dio (e.g. network, timeout, etc.)
    return Response.internalServerError(
      body: jsonEncode({
        'error': 'Internal server error while contacting Mapbox',
        'details': e.response?.data ?? e.message,
      }),
    );
  }
}