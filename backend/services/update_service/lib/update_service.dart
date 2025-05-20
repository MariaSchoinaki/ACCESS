import 'package:access_models/route_data.dart';
import 'package:access_models/route_segment.dart';
import 'package:access_models/disability_type.dart';
import 'package:access_models/firebase/rest.dart';

// GeoJSON imports
import 'package:access_models/geojson/geojson_loader.dart';
import 'package:access_models/geojson/geojson_models.dart';
import 'package:access_models/geojson/nearest_segment.dart';

class AccessibilityUpdaterService {
  AccessibilityUpdaterService(this._rest);
  final FirestoreRest _rest;

  Future<void> run({required double alpha}) async {
    print('[STEP] Loading road geojson...');
    final geojson = await loadGeoJson('../../data/roads.geojson');
    print('[STEP] Geojson loaded with ${geojson.features.length} features.');

    print('[STEP] Loading rated_routes needing update...');
    final rawRoutes = await _rest.listDocs('rated_routes');
    final routesToUpdate = rawRoutes.where((d) {
      final f = d['fields'] as Map<String, dynamic>;
      return f['needsUpdate']?['booleanValue'] == true;
    }).toList();

    print('[STEP] Found ${routesToUpdate.length} routes needing update.');

    if (routesToUpdate.isEmpty) {
      print('No routes needing update. Exiting.');
      return;
    }

    // 3. Load all users
    final rawUsers = await _rest.listDocs('users');
    final users = rawUsers.map((d) {
      final uid = (d['name'] as String).split('/').last;
      final str = (d['fields']['disabilityType'] as Map)['stringValue'] as String? ?? '';
      return _User(uid, disabilityTypeFromGreek(str));
    }).toList();

    // 4. Process each route needing update
    for (final d in routesToUpdate) {
      final id = (d['name'] as String).split('/').last;
      final f = d['fields'] as Map<String, dynamic>;
      final simple = <String, dynamic>{};
      f.forEach((k, rv) {
        final m = rv as Map<String, dynamic>;
        if (m.containsKey('doubleValue') || m.containsKey('integerValue')) {
          final v = m['doubleValue'] ?? m['integerValue'];
          simple[k] = v is String ? double.parse(v) : (v as num).toDouble();
        } else if (m.containsKey('stringValue')) {
          simple[k] = m['stringValue'];
        } else if (m.containsKey('arrayValue')) {
          simple[k] = (m['arrayValue']['values'] as List? ?? []);
        }
      });
      final route = RouteData.fromFs(id: id, json: simple, defaultRefAcc: 0.5);

      print('\n[ROUTE] =============================');
      print('[ROUTE] Route ID: $id');
      print('[ROUTE] Points: ${route.routePoints.length}');
      print('[ROUTE] Rating: ${route.rating}');
      print('[ROUTE] needsUpdate: ${f['needsUpdate']?['booleanValue']}');

      // Get the segmentIds for this route (one segment = one road)
      final userRoutePoints = route.routePoints.map((pt) => [pt.longitude, pt.latitude]).toList();
      final List<String> matchedSegmentIds = matchRouteToSegments(userRoutePoints, geojson);
      final double routeRating = route.rating ?? 0.5;

      print('[ROUTE] Matched Segment IDs: $matchedSegmentIds');

      // For each segment
      for (final segmentId in matchedSegmentIds) {
        final docId = segmentId.replaceAll('/', '_');
        double prevAccessibilityScore = 0.5;

        // --- Read the current AccessibilityScore of the segment (if it exists) ---
        final segmentDoc = await _rest.getDoc('roads', docId);
        if (segmentDoc != null && segmentDoc['fields'] != null) {
          final fields = segmentDoc['fields'] as Map<String, dynamic>;
          final accScore = fields['AccessibilityScore'];
          if (accScore != null && accScore['doubleValue'] != null) {
            prevAccessibilityScore = (accScore['doubleValue'] as num).toDouble();
            print('[SEGMENT] Found previous AccessibilityScore for $segmentId: $prevAccessibilityScore');
          } else {
            print('[SEGMENT] No previous AccessibilityScore for $segmentId. Using default 0.5');
          }
        } else {
          print('[SEGMENT] Segment $segmentId does not exist. Using default score 0.5');
        }

        // For each user/disability type
        for (final u in users) {
          final disabilityType = u.disabilityType;
          final w = getDisabilityWeight(disabilityType);
          final double Pold = prevAccessibilityScore;
          final double R = routeRating;
          final double Pnew = (Pold + alpha * w * (R - Pold)).clamp(0.0, 1.0);
          final String color = determineColorAsHexString(Pnew);

          print('    [USER]');
          print('      User: ${u.id}');
          print('      DisabilityType: $disabilityType | Weight: $w');
          print('      segmentId: $segmentId');
          print('      Pold: $Pold | R: $R | alpha: $alpha');
          print('      Pnew: $Pnew | Color: $color');

          // --- Write the new score to roads collection ---
          final Map<String, dynamic> roadFields = {
            'segmentId': {'stringValue': segmentId},
            'AccessibilityScore': {'doubleValue': Pnew},
            'lastUpdatedByRoute': {'stringValue': route.id},
            'lastUpdatedByUser': {'stringValue': u.id},
            'updatedAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
          };
          await _rest.patchDoc('roads', docId, roadFields);
          print('      [FIRESTORE] Updated segment $segmentId with score $Pnew for user ${u.id}');
        }
      }

      // Set needsUpdate = false for this route (updateMask so you don't touch other fields)
      await _rest.patchDoc(
        'rated_routes',
        route.id,
        {'needsUpdate': {'booleanValue': false}},
        updateMaskFields: ['needsUpdate'],
      );
      print('[ROUTES] Reset needsUpdate for ${route.id}');
    }
    print('\n✅ Accessibility update completed for all routes needing update.');
  }
}

class _User {
  _User(this.id, this.disabilityType);
  final String id;
  final DisabilityType disabilityType;
}