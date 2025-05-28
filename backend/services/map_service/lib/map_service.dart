import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:dio/dio.dart' as dio;
import 'package:polyline_codec/polyline_codec.dart' as polyline;
import 'package:html/parser.dart' show parse;

import 'package:access_models/geojson/geojson_models.dart';
import 'package:access_models/geojson/geojson_loader.dart';
import 'package:access_models/geojson/nearest_segment.dart';
import 'package:access_models/firebase/rest.dart';

// ======= GLOBALS =======
GeoJsonFeatureCollection? globalGeoJson;
FirestoreRest? globalFirestoreRest;

// ======= LOAD GLOBALS =======
Future<void> ensureGlobals() async {
  if (globalGeoJson == null) {
    final geojsonPath = Platform.environment['GEOJSON_PATH'] ?? 'data/roads.geojson';
    print('[DEBUG] Loading geojson from: $geojsonPath');
    globalGeoJson = await loadGeoJson(geojsonPath);
    print('[DEBUG] Loaded geojson.');
  }
  if (globalFirestoreRest == null) {
    final saPath = Platform.environment['FIREBASE_CONF4.JSON'] ?? 'firebase_conf.json';
    print('[DEBUG] Using Firestore service account: $saPath');
    if (!File(saPath).existsSync()) {
      stderr.writeln('❌ Cannot find service-account JSON at "$saPath"');
      exit(1);
    }
    print('>>> [MAIN] Loading Firestore credentials...');
    globalFirestoreRest = FirestoreRest.fromServiceAccount(saPath);
    print('[DEBUG] FirestoreRest initialized.');
  }
}

// ======= HEALTH ROUTE =======
Response _healthHandler(Request request) {
  print('>>> _healthHandler CALLED!');
  print('[DEBUG] Health check hit.');
  return Response.ok('OK', headers: {'Content-Type': 'text/plain'});
}

// ======= COLOR UTILITY =======
void assignRouteColorsByRank(List<Map<String, dynamic>> routes) {
  final colorOrder = [
    '#0074D9', // blue
    '#2ECC40', // green
    '#FFDC00', // yellow
    '#FF4136', // red
    '#B10DC9', // purple (5th+)
  ];
  for (var i = 0; i < routes.length; i++) {
    routes[i]['color'] = colorOrder[i < colorOrder.length ? i : colorOrder.length - 1];
  }
}

// ======= HAVERSINE AND LENGTH HELPERS =======
double haversine(List<double> a, List<double> b) {
  const R = 6371000.0; // Earth radius in meters
  final dLat = _deg2rad(b[1] - a[1]);
  final dLon = _deg2rad(b[0] - a[0]);
  final lat1 = _deg2rad(a[1]);
  final lat2 = _deg2rad(b[1]);
  final h = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
  return 2 * R * atan2(sqrt(h), sqrt(1 - h));
}
double _deg2rad(double deg) => deg * pi / 180;

double getSegmentLength(String segmentId, GeoJsonFeatureCollection geojson) {
  try {
    final feature = geojson.features.firstWhere(
          (f) => f.properties['id'].toString() == segmentId,
    );
    final coords = feature.geometry.coordinates;
    if (coords == null || coords.length < 2) return 0.0;
    double length = 0;
    for (int i = 1; i < coords.length; i++) {
      length += haversine(coords[i - 1], coords[i]);
    }
    return length;
  } catch (e) {
    // Not found or error in feature structure
    return 0.0;
  }
}


// ======= FIRESTORE SEGMENT SCORE GETTER =======
Future<double> getAccessibilityScoreForSegment(
    String segmentId, FirestoreRest rest) async {
  try {
    print('[DEBUG] Fetching segmentId: $segmentId');
    final doc = await rest.getDoc('roads', segmentId.replaceAll('/', '_'));
    print('[DEBUG] Firestore getDoc result: $doc');
    if (doc == null || doc['fields'] == null) {
      print('[DEBUG] No doc or fields for $segmentId, returning 0.5');
      return 0.5;
    }
    final fields = doc['fields'] as Map<String, dynamic>;
    final acc = fields['accessibilityScore']?['doubleValue'];
    final score = acc != null ? (acc as num).toDouble() : 0.5;
    print('[DEBUG] Score for $segmentId: $score');
    return score;
  }catch (e, st) {
    final isNotFound = e.toString().contains('"status": "NOT_FOUND"') || e.toString().contains('code": 404');
    if (isNotFound) {
      print('[INFO] Segment $segmentId not in Firestore. Using default 0.5.');
    } else {
      print('[ERROR] [Segment $segmentId] getAccessibilityScoreForSegment error: $e');
      print(st);
    }
    return 0.5;
  }
}

// ======= ROUTE SCORE CALCULATOR (LENGTH-WEIGHTED) =======
Future<double> getRouteAccessibilityScore(
    List<List<double>> routePoints,
    FirestoreRest rest,
    GeoJsonFeatureCollection geojson, {
      int maxDownsamplePoints = 60,
    }) async {
  try {
    List<List<double>> points = routePoints;
    if (routePoints.length > maxDownsamplePoints) {
      final step = (routePoints.length / maxDownsamplePoints).ceil();
      points = [for (int i = 0; i < routePoints.length; i += step) routePoints[i]];
      print('[DEBUG] Downsampled routePoints from ${routePoints.length} to ${points.length} points.');
    } else {
      print('[DEBUG] No downsampling. Points: ${points.length}');
    }

    final matchedSegments = matchRouteToSegments(points, geojson);
    print('[DEBUG] Matched segments (ordered, unique): ${matchedSegments.length}');
    print('[DEBUG] Segment IDs: $matchedSegments');

    if (matchedSegments.isEmpty) {
      print('[WARN] No segments matched for this route. Returning default score 0.5');
      return 0.5;
    }

    // Βελτιστοποίηση: Χτύπα όλα τα segments παράλληλα, με timeout fallback
    final segmentScores = await Future.wait(
      matchedSegments.map((segId) async {
        double score;
        try {
          score = await getAccessibilityScoreForSegment(segId, rest).timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              print('[WARN] Timeout on segment $segId. Using default 0.5');
              return 0.5;
            },
          );
        } catch (e) {
          print('[WARN] Error fetching score for $segId: $e');
          score = 0.5;
        }

        final length = getSegmentLength(segId, geojson);
        return {'score': score, 'length': length};
      }),
    );

    double weightedSum = 0;
    double totalLength = 0;
    for (final entry in segmentScores) {
      weightedSum += (entry['score']! * entry['length']!)!;
      totalLength += entry['length']!;
    }

    final weightedAvg = totalLength > 0 ? weightedSum / totalLength : 0.5;
    print('[DEBUG] FINAL WEIGHTED AVG ROUTE SCORE: $weightedAvg');
    return weightedAvg;
  } catch (e, st) {
    print('[ERROR] Exception in getRouteAccessibilityScore: $e');
    print(st);
    return 0.5;
  }
}

// ======= ROUTE HANDLER (GET) =======
Future<Response> _routeHandler(Request request) async {
  print('>>> HANDLER GETTER RUNS!');
  print('\n[DEBUG] /route endpoint called.');
  try {
    await ensureGlobals();
    final geojson = globalGeoJson!;
    final firestoreRest = globalFirestoreRest!;
    final lat = request.url.queryParameters['lat'];
    final lng = request.url.queryParameters['lng'];
    final toLat = request.url.queryParameters['toLat'];
    final toLng = request.url.queryParameters['toLng'];
    print('[DEBUG] Query params: $lat,$lng -> $toLat,$toLng');
    if ([lat, lng, toLat, toLng].any((v) => v == null || v.isEmpty)) {
      return Response.badRequest(
        body: jsonEncode({'error': 'Missing query parameters'}),
        headers: {'Content-Type': 'application/json'},
      );
    }
    final alternatives = request.url.queryParameters['alternatives'] ?? 'false';
    final isAlternatives = alternatives.toLowerCase() == 'true';
    final dioBackend = dio.Dio(dio.BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
    final url = 'https://maps.googleapis.com/maps/api/directions/json';
    final googleApiKey = File('/run/secrets/google_maps_key').readAsStringSync().trim();
    final queryParameters = {
      'origin': '$lat,$lng',
      'destination': '$toLat,$toLng',
      'alternatives': alternatives,
      'mode': 'walking',
      'key': googleApiKey,
      'language': 'el', // Greek
    };
    print('[DEBUG] Sending request to Google Directions API...');
    final swGoogle = Stopwatch()..start();
    final response = await dioBackend.get(url, queryParameters: queryParameters);
    swGoogle.stop();
    print('[DEBUG] Google Directions response received in ${swGoogle.elapsedMilliseconds} ms.');
    final data = response.data;
    print('[DEBUG] Google response status: ${data['status']}');
    if (data['status'] != 'OK') {
      print('[DEBUG] Google Directions API error: ${data['status']}');
      return Response.internalServerError(
        body: jsonEncode({
          'error': 'Google Directions API error',
          'details': data['status'],
        }),
        headers: {'Content-Type': 'application/json'},
      );
    }
    final routesRaw = (data['routes'] as List<dynamic>? ?? [])
        .where((route) => route['overview_polyline']?['points'] != null)
        .toList();
    print('[DEBUG] routesRaw count: ${routesRaw.length}');
    final List<Map<String, dynamic>> routesWithScores = [];
    for (var i = 0; i < routesRaw.length; i++) {
      var route = routesRaw[i];
      final encodedPolyline = route['overview_polyline']['points'];
      final decodedPoints = polyline.PolylineCodec.decode(encodedPolyline)
          .map((point) => [point[1].toDouble(), point[0].toDouble()]) // Swap + double!
          .toList();

      final summary = route['summary'] ?? '';
      final steps = (route['legs']?.first?['steps'] as List<dynamic>? ?? []);
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
      print('[DEBUG] Calculating score for route $i ($summary)...');
      double score;
      try {
        score = await getRouteAccessibilityScore(decodedPoints, firestoreRest, geojson);
      } catch (e, st) {
        print('[ERROR] Error scoring route: $e\n$st');
        score = 0.5;
      }
      print('[DEBUG] accessibilityScore for route $i ($summary): $score');
      routesWithScores.add({
        'summary': summary,
        'coordinates': decodedPoints,
        'instructions': instructions,
        'accessibilityScore': score,
      });
    }
    print('[DEBUG] Sorting routes by accessibilityScore...');
    routesWithScores.sort((a, b) =>
        (b['accessibilityScore'] as double).compareTo(a['accessibilityScore'] as double));
    print('[DEBUG] Assigning colors to routes');
    assignRouteColorsByRank(routesWithScores);
    print('[DEBUG] Final routesWithScores: $routesWithScores');
    Map<String, dynamic> responseBody;
    if (isAlternatives) {
      responseBody = {'routes': routesWithScores};
    } else {
      responseBody = {'route': routesWithScores.isNotEmpty ? routesWithScores.first : null};
    }
    return Response.ok(
      jsonEncode(responseBody),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e, st) {
    print('[ERROR] Unknown error in /route!');
    print(e);
    print(st);
    return Response.internalServerError(
      body: jsonEncode({
        'error': 'Internal server error',
        'details': e.toString(),
        'stack': st.toString(),
      }),
      headers: {'Content-Type': 'application/json'},
    );
  }
}

// ======= SHELF HANDLER ENTRY =======
Handler get handler {
  final router = Router()
    ..get('/health', _healthHandler)
    ..get('/route', _routeHandler);
  return Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router);
}
