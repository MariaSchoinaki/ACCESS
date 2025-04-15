import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:dio/dio.dart' as dio;

Future<Response> handleSearchRequest(Request request) async {
  if (request.url.path == 'health') {
    return Response.ok('OK', headers: {'Content-Type': 'text/plain'});
  }

  final query = request.url.queryParameters['q'];

  if (query == null || query.isEmpty) {
    return Response.badRequest(
      body: jsonEncode({'error': 'Missing query parameter "q"'}),
    );
  }

  final dioBackend = dio.Dio();
  final mapboxToken = File('/run/secrets/mapbox_token').readAsStringSync().trim();

  final url = 'https://api.mapbox.com/geocoding/v5/mapbox.places/$query.json';

  try {
    final response = await dioBackend.get(
      url,
      queryParameters: {'access_token': mapboxToken},
    );

    if (response.statusCode != 200) {
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch data from Mapbox'}),
      );
    }
    print('> Received query: $query');
    print('> Geocoding response: ${response.data}');

    return Response.ok(
      jsonEncode({'results': response.data['features']}),
      headers: {'Content-Type': 'application/json'},
    );
  } on dio.DioException catch (e) {
    return Response.internalServerError(
      body: jsonEncode({
        'error': 'Internal server error while contacting Mapbox',
        'details': e.response?.data ?? e.message,
      }),
    );
  }
}

