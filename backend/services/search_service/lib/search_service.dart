import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:dio/dio.dart' as dio;

Future<Response> handleSearchRequest(Request request) async {
  if (request.url.path == 'health') {
    return Response.ok('OK', headers: {'Content-Type': 'text/plain'});
  }

  final query = request.url.queryParameters['q'];
  final sessionToken = request.url.queryParameters['session_token']; // Ελέγχουμε για το session token

  if (query == null || query.isEmpty) {
    return Response.badRequest(
      body: jsonEncode({'error': 'Missing query parameter "q"'}),
    );
  }

  if (sessionToken == null || sessionToken.isEmpty) {
    return Response.badRequest(
      body: jsonEncode({'error': 'Missing session token "session_token"'}),
    );
  }

  final dioBackend = dio.Dio();
  final mapboxToken = File('/run/secrets/mapbox_token').readAsStringSync().trim();

  final encodedQuery = Uri.encodeComponent(query);
  final url = 'https://api.mapbox.com/search/searchbox/v1/suggest?q=$encodedQuery';

  print('Received session_token: $sessionToken');
  print('Query: $query');
  print('URL to Mapbox: $url');

  try {
    final response = await dioBackend.get(
      url,
      queryParameters: {
        'session_token': sessionToken,
        'access_token': mapboxToken,// Στέλνουμε το session token στο Mapbox
      },
    );

    if (response.statusCode != 200) {
      print('> Error fetching data from Mapbox');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch data from Mapbox'}),
      );
    }

    print('> Received query: $query');
    print('> Geocoding response: ${response.data}');

    return Response.ok(
      jsonEncode({'results': response.data['suggestions']}),
      headers: {'Content-Type': 'application/json'},
    );
  } on dio.DioException catch (e) {
    print('> Error fetching data from Mapbox, 47');
    return Response.internalServerError(
      body: jsonEncode({
        'error': 'Internal server error while contacting Mapbox',
        'details': e.response?.data ?? e.message,
      }),
    );
  }
}

Future<Response> handleCoordinatesRequest(Request request) async {
  final mapboxId = request.url.queryParameters['mapbox_id'];
  final sessionToken = request.url.queryParameters['session_token']; // Ελέγχουμε για το session token

  if (mapboxId == null || mapboxId.isEmpty) {
    return Response.badRequest(
      body: jsonEncode({'error': 'Missing parameter "mapbox_id"'}),
    );
  }

  final dioBackend = dio.Dio();
  final mapboxToken = File('/run/secrets/mapbox_token').readAsStringSync().trim();

  final url = 'https://api.mapbox.com/search/searchbox/v1/retrieve/$mapboxId';

  print('Received mapbox_id: $mapboxId');
  print('URL to Mapbox for coordinates: $url');

  try {
    final response = await dioBackend.get(
      url,
      queryParameters: {
        'session_token': sessionToken,
        'access_token': mapboxToken,// Στέλνουμε το session token στο Mapbox
      },
    );

    if (response.statusCode != 200) {
      print('> Error fetching data from Mapbox');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch coordinates from Mapbox'}),
      );
    }

    print('> Geocoding response: ${response.data}');

    // Επιστρέφουμε τις συντεταγμένες
    final featureData = response.data['features']?.first;
    if (featureData == null) {
      print('> No coordinates found in the response: ${response.data}');
      return Response.internalServerError(
        body: jsonEncode({'error': 'No coordinates found for the provided mapbox_id'}),
      );
    }

    /**
     * {type: FeatureCollection,
     * features: [
     * {type: Feature,
     * geometry: {coordinates: [23.7361499, 37.99577261], type: Point},
     * properties: {
     * name: Athens University of Economics and Business,
     * mapbox_id: dXJuOm1ieHBvaTo1OTdmOTNlYS1jZWVkLTRmMTQtYTU3ZC00MThjMjMyYTEzODk,
     * feature_type: poi,
     * address: Trias 2,
     * full_address: Trias 2, 113 62 Athens, Greece,
     * place_formatted: 113 62 Athens, Greece,
     * context: {country: {id: , name: Greece, country_code: GR, country_code_alpha_3: GRC},
     * postcode: {id: dXJuOm1ieHBsYzpCNDVi, name: 113 62},
     * place: {id: dXJuOm1ieHBsYzplQ2hi, name: Athens},
     * address: {id: , name: Trias 2, address_number: 2, street_name: trias},
     * street: {id: , name: trias}},
     * coordinates: {latitude: 37.99577261, longitude: 23.7361499, routable_points: [{name: POI, latitude: 37.99575024846219, longitude: 23.736146442322415}]},
     * language: en, maki: marker, poi_category: [education, university],
     * poi_category_ids: [education, university], external_ids: {},
     * metadata: {wheelchair_accessible: true},
     * operational_status: active}}
     * ],
     * attribution: © 2025 Mapbox and its suppliers. All rights reserved. Use of this data is subject to the Mapbox Terms of Service. (https://www.mapbox.com/about/maps/)}
     */

    final result = {
      'name': featureData['properties']['name'],
      'mapbox_id': featureData['properties']['mapbox_id'],
      'geometry': featureData['geometry'],
      'address': featureData['properties']['address'],
      'full_address': featureData['properties']['full_address'],
      'metadata': featureData['properties']['metadata'],
      'poi_category': featureData['properties']['poi_category'],
    };

    // Επιστρέφουμε τις συντεταγμένες με σαφήνεια
    return Response.ok(
      jsonEncode({'result': result}),
      headers: {'Content-Type': 'application/json'},
    );
  } on dio.DioException catch (e) {
    print('> Error fetching coordinates from Mapbox, 47');
    return Response.internalServerError(
      body: jsonEncode({
        'error': 'Internal server error while contacting Mapbox',
        'details': e.response?.data ?? e.message,
      }),
    );
  }
}

