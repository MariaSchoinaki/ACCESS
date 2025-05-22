import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:dio/dio.dart' as dio;
import 'package:polyline_codec/polyline_codec.dart' as polyline;
import 'package:html/parser.dart' show parse;

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

  final alternatives = request.url.queryParameters['alternatives'] ?? 'false';
  final isAlternatives = alternatives.toLowerCase() == 'true';

  final dioBackend = dio.Dio();
  final url = 'https://maps.googleapis.com/maps/api/directions/json';
  final googleApiKey = File('/run/secrets/google_maps_key').readAsStringSync().trim();

  final queryParameters = {
    'origin': '$lat,$lng',
    'destination': '$toLat,$toLng',
    'alternatives': alternatives,
    'mode': 'walking',
    'key': googleApiKey,
  };

  try {
    final response = await dioBackend.get(url, queryParameters: queryParameters);
    final data = response.data;

    if (data['status'] != 'OK') {
      return Response.internalServerError(
        body: jsonEncode({
          'error': 'Google Directions API error',
          'details': data['status'],
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }

    final routes = (data['routes'] as List<dynamic>? ?? []).map((route) {
      final encodedPolyline = route['overview_polyline']?['points'];
      if (encodedPolyline == null) return null;

      final decodedPoints = polyline.PolylineCodec.decode(encodedPolyline);
      final summary = route['summary'] ?? '';

      final steps = ((route['legs']?.first?['steps']) as List<dynamic>? ?? []);
      final instructions = steps.map((step) {
        final rawHtml = step['html_instructions'] ?? '';
        final document = parse(rawHtml);
        final cleanText = document.body?.text ?? '';

        return {
          'instruction': cleanText,
          'distance': step['distance']?['value'],
          'duration': step['duration']?['value'],
          'location': {
            'lat': step['start_location']?['lat'],
            'lng': step['start_location']?['lng'],
          },
          'end_location': {
            'lat': step['end_location']?['lat'],
            'lng': step['end_location']?['lng'],
          },
        };
      }).toList();

      return {
        'summary': summary,
        'coordinates': decodedPoints,
        'instructions': instructions,
      };
    }).where((route) => route != null).toList();

    final responseBody = isAlternatives
        ? {'routes': routes}
        : {'route': routes.isNotEmpty ? routes.first : {}};

    return Response.ok(
      jsonEncode(responseBody),
      headers: {'Content-Type': 'application/json'},
    );
  } on dio.DioException catch (e) {
    return Response.internalServerError(
      body: jsonEncode({
        'error': 'Google Directions API request error',
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
