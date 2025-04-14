import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:dio/dio.dart' as dio;

Future<Response> handleSearchRequest(Request request) async {
  final query = request.url.queryParameters['q'];
  if (query == null || query.isEmpty) {
    return Response.badRequest(body: jsonEncode({'error': 'Missing query'}));
  }

  final dioBackend = dio.Dio();
  final mapboxToken = Platform.environment['MAPBOX_TOKEN'] ?? '';
  final url = 'https://api.mapbox.com/geocoding/v5/mapbox.places/$query.json';

  try {
    final response = await dioBackend.get(
      url,
      queryParameters: {'access_token': mapboxToken},
    );

    if (response.statusCode != 200) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Mapbox error'}),
      );
    }

    return Response.ok(
      jsonEncode({'results': response.data['features']}),
      headers: {'Content-Type': 'application/json'},
    );
  } on dio.DioException catch (e) {
    return Response.internalServerError(
      body: jsonEncode({
        'error': 'Server error',
        'details': e.response?.data ?? e.message,
      }),
    );
  }
}