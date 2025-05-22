import 'dart:io';

import 'package:access_models/route_data.dart';
import 'package:access_models/route_segment.dart';
import 'package:access_models/disability_type.dart';
import 'package:access_models/obstacle_type.dart';
import 'package:access_models/report.dart';
import 'package:access_models/firebase/rest.dart';

// GeoJSON imports
import 'package:access_models/geojson/geojson_loader.dart';
import 'package:access_models/geojson/geojson_models.dart';
import 'package:access_models/geojson/nearest_segment.dart';

class AccessibilityUpdaterService {
  AccessibilityUpdaterService(this._rest);
  final FirestoreRest _rest;

  /// Updates road accessibility based on user-rated routes
  Future<void> runRatings({double alpha = 0.5}) async {
    print('[STEP] Loading road geojson...');

    final geojsonPath = Platform.environment['GEOJSON_PATH'] ?? 'data/roads.geojson';
    final geojson = await loadGeoJson(geojsonPath);

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

  /// Updates road accessibility based on obstacle reports (using new utils)
  Future<void> runReports({double alpha = 0.9}) async {
    print('[STEP] Loading road geojson...');

    final geojsonPath = Platform.environment['GEOJSON_PATH'] ?? 'data/roads.geojson';
    final geojson = await loadGeoJson(geojsonPath);

    print('[STEP] Geojson loaded with ${geojson.features.length} features.');

    print('[STEP] Fetching user and municipal reports needing update...');
    final userReportsRaw = await _rest.fetchCollectionDocuments('reports');
    final municipalReportsRaw = await _rest.fetchCollectionDocuments('municipal_reports');

    // Filter only those reports with needsUpdate == true
    final userReportsToUpdate = userReportsRaw.where((d) =>
    (d['fields'] as Map<String, dynamic>)['needsUpdate']?['booleanValue'] == true
    ).toList();

    final municipalReportsToUpdate = municipalReportsRaw.where((d) =>
    (d['fields'] as Map<String, dynamic>)['needsUpdate']?['booleanValue'] == true
    ).toList();

    final allReports = [
      ...userReportsToUpdate.map((d) => {'doc': d, 'collection': 'reports'}),
      ...municipalReportsToUpdate.map((d) => {'doc': d, 'collection': 'municipal_reports'}),
    ];

    print('[STEP] Found ${allReports.length} reports needing update.');
    if (allReports.isEmpty) {
      print('No reports needing update. Exiting.');
      return;
    }

    for (final reportData in allReports) {
      final doc = reportData['doc'] as Map<String, dynamic>;
      final collection = reportData['collection'] as String;
      final report = Report.fromFirestore(doc);

      final point = [report.longitude, report.latitude];

      // Find nearest segment for this report
      final feature = findNearestFeature(point, geojson);
      if (feature == null) {
        print('[REPORT] No segment found for report: ${report.id}');
        continue;
      }
      final segmentId = feature.properties['id']?.toString() ?? '';
      final docId = segmentId.replaceAll('/', '_');

      double prevAccessibilityScore = 0.5;
      try {
        final segmentDoc = await _rest.getDoc('roads', docId);
        final fields = segmentDoc['fields'] as Map<String, dynamic>;
        final accScore = fields['AccessibilityScore'];
        if (accScore != null && accScore['doubleValue'] != null) {
          prevAccessibilityScore = (accScore['doubleValue'] as num).toDouble();
        }
      } catch (_) {}

      final ObstacleType obstacleType = obstacleTypeFromGreek(report.obstacleType);
      final double reportImpact = getObstacleWeight(obstacleType);

      final double Pold = prevAccessibilityScore;
      final double Pnew = (Pold + alpha * (reportImpact - Pold)).clamp(0.0, 1.0);

      final String color = getObstacleImpactColor(Pnew);

      print('\n[REPORT]');
      print('  Report ID: ${report.id}');
      print('  Obstacle Type: ${report.obstacleType} (impact: $reportImpact)');
      print('  Segment ID: $segmentId');
      print('  Pold: $Pold | Pnew: $Pnew | Color: $color');

      final Map<String, dynamic> roadFields = {
        'segmentId': {'stringValue': segmentId},
        'AccessibilityScore': {'doubleValue': Pnew},
        'lastUpdatedByReport': {'stringValue': report.id},
        'updatedAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
      };
      await _rest.patchDoc('roads', docId, roadFields);
      print('    [FIRESTORE] Updated segment $segmentId with score $Pnew due to report ${report.id}');

      // After processing, set needsUpdate = false for this report
      await _rest.patchDoc(
        collection,
        report.id,
        {'needsUpdate': {'booleanValue': false}},
        updateMaskFields: ['needsUpdate'],
      );
      print('    [FIRESTORE] Reset needsUpdate for report ${report.id} in $collection');
    }
    print('\n✅ Accessibility update completed for all reports needing update.');
  }
}

extension on String {
  get features => null;
}

class _User {
  _User(this.id, this.disabilityType);
  final String id;
  final DisabilityType disabilityType;
}