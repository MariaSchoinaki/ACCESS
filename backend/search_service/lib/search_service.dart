import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:http/http.dart' as http;

Future<Response> handleSearchRequest(Request request) async {
  final query = request.url.queryParameters['q'];
  if (query == null || query.isEmpty) {
    return Response.badRequest(body: jsonEncode({'error': 'Missing query'}));
  }

  final mapboxToken = 'token';
  final url = Uri.parse(
    'https://api.mapbox.com/geocoding/v5/mapbox.places/$query.json?access_token=$mapboxToken',
  );

  try {
    final response = await http.get(url);
    if (response.statusCode != 200) {
      return Response.internalServerError(body: jsonEncode({'error': 'Mapbox error'}));
    }

    final data = jsonDecode(response.body);
    final features = data['features'] ?? [];
    return Response.ok(jsonEncode({'results': features}),
        headers: {'Content-Type': 'application/json'});
  } catch (e) {
    return Response.internalServerError(body: jsonEncode({'error': 'Server crashed', 'details': e.toString()}));
  }
}
