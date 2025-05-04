import 'dart:convert'; // Required for jsonEncode
import 'dart:io'; // Required for File operations (reading token)
import 'package:shelf/shelf.dart'; // Shelf framework for request handling
import 'package:dio/dio.dart' as dio; // Dio HTTP client (aliased)

/// Handles search suggestion requests, likely corresponding to an endpoint like `/search`.
///
/// Expects 'q' (query) and 'session_token' as query parameters in the [request].
/// Proxies the request to the Mapbox SearchBox Suggest API and returns the suggestions.
/// Includes a basic '/health' check endpoint.
///
/// Returns:
/// - `Response.ok` with 'OK' for the health check.
/// - `Response.ok` with a JSON body containing '{ "results": [...] }' on successful suggestion fetching.
/// - `Response.badRequest` if 'q' or 'session_token' parameters are missing.
/// - `Response.internalServerError` if fetching from Mapbox fails or another server error occurs.
Future<Response> handleSearchRequest(Request request) async {
  // Handle simple health check endpoint
  if (request.url.path == 'health') {
    return Response.ok('OK', headers: {'Content-Type': 'text/plain'});
  }

  // Extract query parameters
  final query = request.url.queryParameters['q'];
  final sessionToken = request.url.queryParameters['session_token'];

  // Validate required parameters
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

  // Initialize Dio client for making HTTP requests
  final dioBackend = dio.Dio();
  final mapboxToken = File('/run/secrets/mapbox_token').readAsStringSync().trim();

  final encodedQuery = Uri.encodeComponent(query);
  final url = 'https://api.mapbox.com/search/searchbox/v1/suggest?q=$encodedQuery';

  print('Received session_token: $sessionToken');
  print('Query: $query');
  print('URL to Mapbox: $url');

  try {
    // Make the GET request to Mapbox API
    final response = await dioBackend.get(
      url,
      queryParameters: {
        'session_token': sessionToken,
        'access_token': mapboxToken,
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

    // Return Mapbox suggestions wrapped in a 'results' key
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

/// Handles requests to retrieve detailed information for a specific Mapbox ID,
/// corresponding to an endpoint `/retrieve`.
///
/// Expects 'mapbox_id' and 'session_token' as query parameters in the [request].
/// Proxies the request to the Mapbox SearchBox Retrieve API.
/// Extracts and formats relevant fields from the Mapbox response.
///
/// Returns:
/// - `Response.ok` with a JSON body containing '{ "result": { ... } }' on success.
/// - `Response.badRequest` if 'mapbox_id' parameter is missing.
/// - `Response.internalServerError` if fetching from Mapbox fails, the ID is not found,
///   or another server error occurs.
Future<Response> handleCoordinatesRequest(Request request) async {
  final mapboxId = request.url.queryParameters['mapbox_id'];
  final sessionToken = request.url.queryParameters['session_token'];

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
        'access_token': mapboxToken,
      },
    );

    if (response.statusCode != 200) {
      print('> Error fetching data from Mapbox');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch coordinates from Mapbox'}),
      );
    }

    print('> Geocoding response: ${response.data}');

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
     * language: en, maki: marker,
     * poi_category: [education, university],
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

/// Handles reverse geocoding requests using Mapbox Geocoding API v6,
/// corresponding to an endpoint `/getname`.
///
/// Expects 'lat' (latitude) and 'lng' (longitude) as query parameters in the [request].
/// Calls the Mapbox Reverse Geocoding API to find addresses or places at the given coordinates.
/// Extracts and formats relevant fields from the first result feature.
///
/// Returns:
/// - `Response.ok` with a JSON body containing '{ "result": { ... } }' on success.
/// - `Response.badRequest` if 'lat' or 'lng' parameters are missing.
/// - `Response.internalServerError` if fetching from Mapbox fails or another server error occurs.
Future<Response> getLocationNameFromMapbox(Request request) async {
  final lat = request.url.queryParameters['lat'];
  final lng = request.url.queryParameters['lng'];

  // If the query is missing or empty, return an error response
  if (lat == null || lng == null) {
    return Response.badRequest(body: jsonEncode({'error': 'Missing query'}));
  }

  // Create a Dio client instance
  final dioBackend = dio.Dio();

  // Retrieve the Mapbox token from environment variables
  final mapboxToken = File('/run/secrets/mapbox_token').readAsStringSync().trim();

  // Construct the Mapbox geocoding endpoint
  final url = 'https://api.mapbox.com/search/geocode/v6/reverse?';

  try {
    // Make the GET request to Mapbox API
    final response = await dioBackend.get(
      url,
      queryParameters: {
        'longitude': lng,
        'latitude' : lat,
        'access_token': mapboxToken,
      },
    );
    print(url);
    print(response.data);


    // If Mapbox responds with an error status
    if (response.statusCode != 200) {
      print('> Error fetching data from Mapbox');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch data from Mapbox'}),
      );
    }

    /**
     * {type: FeatureCollection,
     * features: [
     * {type: Feature, id: dXJuOm1ieGFkcjo2NDZjNmM1Yy03MjNkLTQxMmQtODc4MC02YTU0ZWNjMmRlZjg,
     * geometry: {type: Point, coordinates: [23.733896, 37.997591]},
     *
     * properties: {
     *
     * mapbox_id: dXJuOm1ieGFkcjo2NDZjNmM1Yy03MjNkLTQxMmQtODc4MC02YTU0ZWNjMmRlZjg,
     * feature_type: address,
     * full_address: Ιωάννου Δροσοπούλου 29, 112 57 Athina, Greece,
     * name: Ιωάννου Δροσοπούλου 29,
     * name_preferred: Ιωάννου Δροσοπούλου 29,
     * coordinates: {longitude: 23.733896, latitude: 37.997591, accuracy: rooftop, routable_points: [{name: default, latitude: 37.99757, longitude: 23.734036}]},
     * place_formatted: 112 57 Athina, Greece,
     * context: {address: {mapbox_id: dXJuOm1ieGFkcjo2NDZjNmM1Yy03MjNkLTQxMmQtODc4MC02YTU0ZWNjMmRlZjg, address_number: 29, street_name: Ιωάννου Δροσοπούλου, name: Ιωάννου Δροσοπούλου 29},
     * street: {mapbox_id: dXJuOm1ieGFkci1zdHI6NjQ2YzZjNWMtNzIzZC00MTJkLTg3ODAtNmE1NGVjYzJkZWY4, name: Ιωάννου Δροσοπούλου},
     * postcode: {mapbox_id: dXJuOm1ieHBsYzpCMDVi, name: 112 57},
     * place: {mapbox_id: dXJuOm1ieHBsYzplQ2hi, name: Athina, wikidata_id: Q1524},
     * region: {mapbox_id: dXJuOm1ieHBsYzpBYVJi, name: Attica, wikidata_id: Q758056, region_code: I, region_code_full: GR-I},
     * country: {mapbox_id: dXJuOm1ieHBsYzpJbHM, name: Greece, wikidata_id: Q41, country_code: GR, country_code_alpha_3: GRC}}}},
     * {type: Feature, id: dXJuOm1ieHBsYzpCMDVi,
     * geometry: {type: Point, coordinates: [23.73336, 38.000114]},
     * properties: {mapbox_id: dXJuOm1ieHBsYzpCMDVi,
     * feature_type: postcode, full_address: 112 57, Athina, Attica, Greece, name: 112 57, name_preferred: 112 57, coordinates: {longitude: 23.73336, latitude: 38.000114}, place_formatted: Athina, Attica, Greece, bbox: [23.73227, 37.995364, 23.736918, 38.004194], context: {place: {mapbox_id: dXJuOm1ieHBsYzplQ2hi, name: Athina, wikidata_id: Q1524}, region: {mapbox_id: dXJuOm1ieHBsYzpBYVJi, name: Attica, wikidata_id: Q758056, region_code: I, region_code_full: GR-I}, country: {mapbox_id: dXJuOm1ieHBsYzpJbHM, name: Greece, wikidata_id: Q41, country_code: GR, country_code_alpha_3: GRC}, postcode: {mapbox_id: dXJuOm1ieHBsYzpCMDVi, name: 112 57}}}}, {type: Feature, id: dXJuOm1ieHBsYzplQ2hi, geometry: {type: Point, coordinates: [23.729275, 37.97757]}, properties: {mapbox_id: dXJuOm1ieHBsYzplQ2hi, feature_type: place, full_address: Athina, Attica, Greece, name: Athina, name_preferred: Athina, coordinates: {longitude: 23.729275, latitude: 37.97757}, place_formatted: Attica, Greece, bbox: [23.686932, 37.948804, 23.790157, 38.032552], context: {region: {mapbox_id: dXJuOm1ieHBsYzpBYVJi, name: Attica, wikidata_id: Q758056, region_code: I, region_code_full: GR-I}, country: {mapbox_id: dXJuOm1ieHBsYzpJbHM, name: Greece, wikidata_id: Q41, country_code: GR, country_code_alpha_3: GRC}, place: {mapbox_id: dXJuOm1ieHBsYzplQ2hi, name: Athina, wikidata_id: Q1524}}}}, {type: Feature, id: dXJuOm1ieHBsYzpBYVJi, geometry: {type: Point, coordinates: [23.728305, 37.983941]}, properties: {mapbox_id: dXJuOm1ieHBsYzpBYVJi, feature_type: region, full_address: Attica, Greece, name: Attica, name_preferred: Attica, coordinates: {longitude: 23.728305, latitude: 37.983941}, place_formatted: Greece, bbox: [22.812488, 35.742767, 24.160955, 38.374911], context: {country: {mapbox_id: dXJuOm1ieHBsYzpJbHM, name: Greece, wikidata_id: Q41, country_code: GR, country_code_alpha_3: GRC}, region: {mapbox_id: dXJuOm1ieHBsYzpBYVJi, name: Attica, region_code: I, region_code_full: GR-I, wikidata_id: Q758056}}}}, {type: Feature, id: dXJuOm1ieHBsYzpJbHM, geometry: {type: Point, coordinates: [23.828554, 38.589021]}, properties: {mapbox_id: dXJuOm1ieHBsYzpJbHM, feature_type: country, full_address: Greece, name: Greece, name_preferred: Greece, coordinates: {longitude: 23.828554, latitude: 38.589021}, bbox: [19.277377, 34.724425, 29.696158, 41.749518], context: {country: {mapbox_id: dXJuOm1ieHBsYzpJbHM, name: Greece, country_code: GR, country_code_alpha_3: GRC, wikidata_id: Q41}}}}], attribution: NOTICE: © 2025 Mapbox and its suppliers. All rights reserved. Use of this data is subject to the Mapbox Terms of Service (https://www.mapbox.com/about/maps/). This response and the information it contains may not be retained.}
     */

    print(response.data);
    final featureData = response.data['features']?.first;
    // Return the geocoding results as JSON
    final result = {
      'name': featureData['properties']['name'],
      'mapbox_id': featureData['properties']['mapbox_id'],
      'geometry': featureData['geometry'],
      'address': featureData['properties']['name_preferred'],
      'full_address': featureData['properties']['full_address'],
      'metadata': {},
      'poi_category': [featureData['properties']['feature_type']],
    };

    return Response.ok(
      jsonEncode({'result': result}),
      headers: {'Content-Type': 'application/json'},
    );
  } on dio.DioException catch (e) {
    // Handle errors from Dio (e.g. network, timeout, etc.)
    print('> Error fetching data from Mapbox, 47');
    return Response.internalServerError(
      body: jsonEncode({
        'error': 'Internal server error while contacting Mapbox',
        'details': e.response?.data ?? e.message,
      }),
    );
  }
}

/// Handles search requests filtered by category, optionally within a bounding box,
/// corresponding to an endpoint `/category`.
///
/// Expects 'category', 'session_token', and optionally 'bbox' as query parameters
/// in the [request]. The 'bbox' should be in "minLng,minLat,maxLng,maxLat" format.
/// Proxies the request to the Mapbox SearchBox Category API.
/// Formats the resulting features into a standardized list.
///
/// Returns:
/// - `Response.ok` with a JSON body containing '{ "results": [...] }' on success.
/// - `Response.badRequest` if 'category' or 'session_token' parameters are missing.
/// - `Response.internalServerError` if fetching from Mapbox fails or another server error occurs.
Future<Response> handleSearchByCategoryRequest(Request request) async {
  final category = request.url.queryParameters['category'];
  final sessionToken = request.url.queryParameters['session_token'];
  final bbox = request.url.queryParameters['bbox'];


  if (category == null || category.isEmpty) {
    return Response.badRequest(
      body: jsonEncode({'error': 'Missing category parameter'}),
    );
  }

  if (sessionToken == null || sessionToken.isEmpty) {
    return Response.badRequest(
      body: jsonEncode({'error': 'Missing session token "session_token"'}),
    );
  }

  final dioBackend = dio.Dio();
  final mapboxToken = File('/run/secrets/mapbox_token').readAsStringSync().trim();

  final encodedCategory = Uri.encodeComponent(category);
  final url = 'https://api.mapbox.com/search/searchbox/v1/category/$encodedCategory';

  print('Received category: $category');
  print('Received session_token: $sessionToken');
  print('BBOX: $bbox');
  print('URL to Mapbox for category: $url');

  try {
    final response = await dioBackend.get(
      url,
      queryParameters: {
        'bbox': bbox,
        'access_token': mapboxToken,
      },
    );

    if (response.statusCode != 200) {
      print('> Error fetching data from Mapbox for category');
      return Response.internalServerError(
        body: jsonEncode({'error': 'Failed to fetch data from Mapbox for category'}),
      );
    }

    print('> Geocoding response for category: ${response.data}');

    final suggestions = (response.data['features'] as List?) ?? [];
    final List<Map<String, dynamic>> formattedResults = [];

    for (final suggestion in suggestions) {
      final properties = suggestion['properties'] as Map<String, dynamic>?;
      final geometry = suggestion['geometry'] as Map<String, dynamic>?;

      if (properties != null && geometry != null) {
        formattedResults.add({
          'name': properties['name'],
          'mapbox_id': properties['mapbox_id'],
          'geometry': geometry,
          'address': properties['address'],
          'full_address': properties['full_address'],
          'metadata': properties['metadata'] ?? {},
          'poi_category': (properties['poi_category'] as List?)?.cast<String>() ?? [],
        });
      }
    }
    return Response.ok(
      jsonEncode({'results': formattedResults}),
      headers: {'Content-Type': 'application/json'},
    );
  } on dio.DioException catch (e) {
    print('> Error fetching data from Mapbox for category, 47');
    return Response.internalServerError(
      body: jsonEncode({
        'error': 'Internal server error while contacting Mapbox for category',
        'details': e.response?.data ?? e.message,
      }),
    );
  }
}
