import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:dio/dio.dart' as dio;

// Route handler
Response _healthHandler(Request request) {
  return Response.ok('OK', headers: {'Content-Type': 'text/plain'});
}

Future<Response> _routeHandler(Request request) async {
  final lat = request.url.queryParameters['lat'];
  final lng = request.url.queryParameters['lng'];
  final toLat = request.url.queryParameters['toLat'];
  final toLng = request.url.queryParameters['toLng'];

  if ([lat, lng, toLat, toLng].any((v) => v == null || v.isEmpty)) {
    return Response.badRequest(
      body: jsonEncode({'error': 'Missing query parameters'}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  final dioBackend = dio.Dio();
  final mapboxToken = File('/run/secrets/mapbox_token').readAsStringSync().trim();
  final url = 'https://api.mapbox.com/directions/v5/mapbox/driving/$lng,$lat;$toLng,$toLat';

  final alternatives = request.url.queryParameters['alternatives'] ?? 'false';
  final isAlternatives = alternatives.toLowerCase() == 'true';

  try {
    final response = await dioBackend.get(
      url,
      queryParameters: {
        'access_token': mapboxToken,
        'geometries': 'geojson',
        'alternatives': alternatives,
      },
    );

    final routes = (response.data['routes'] as List<dynamic>? ?? [])
        .map((route) => route['geometry']?['coordinates'])
        .where((coords) => coords != null)
        .toList();

    final responseBody = isAlternatives
        ? {'routes': routes}
        : {'route': routes.isNotEmpty ? routes.first : []};

    return Response.ok(
      jsonEncode(responseBody),
      headers: {'Content-Type': 'application/json'},
    );
  } on dio.DioException catch (e) {
    return Response.internalServerError(
      body: jsonEncode({
        'error': 'Mapbox route error',
        'details': e.message,
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }
}

Handler get handler {
  final router = Router()
    ..get('/health', _healthHandler)
    ..get('/route', _routeHandler);

  return Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router);
}