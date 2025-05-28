import 'dart:convert';
import 'dart:io';

import 'package:access_models/route_data.dart';
import 'package:access_models/disability_type.dart';
import 'package:access_models/obstacle_type.dart';
import 'package:access_models/report.dart';
import 'package:access_models/firebase/rest.dart';

// GeoJSON imports
import 'package:access_models/geojson/geojson_loader.dart';
import 'package:access_models/geojson/geojson_models.dart';
import 'package:access_models/geojson/nearest_segment.dart';

/// Service to update road segment accessibility in Firestore based on user-rated routes.
class AccessibilityUpdaterService {
  AccessibilityUpdaterService(this._rest);

  final FirestoreRest _rest;

  /// Main routine: Update accessibility scores based on user ratings.
  /// [a] is the learning rate (alpha), default is 0.5.
  Future<void> runRatings({double a = 0.5}) async {
    print('[STEP] Loading road geojson...');
    final geojsonPath = Platform.environment['GEOJSON_PATH'] ?? 'data/roads.geojson';
    //final geojsonPath = '../../../data/roads.geojson';
    final geojson = await loadGeoJson(geojsonPath);
    print('[STEP] Geojson loaded with ${geojson.features.length} features.');

    // 1. Load all rated routes that need updating.
    print('[STEP] Loading rated_routes needing update...');
    final rawRoutes = await _rest.listDocs('rated_routes');
    final routesToUpdate = rawRoutes.where((d) {
      final fields = d['fields'] as Map<String, dynamic>;
      return fields['needsUpdate']?['booleanValue'] == true;
    }).toList();
    print('[STEP] Found ${routesToUpdate.length} routes needing update.');
    if (routesToUpdate.isEmpty) {
      print('No routes needing update. Exiting.');
      return;
    }

    // 2. Load all users for lookup.
    final rawUsers = await _rest.listDocs('users');
    print('[INFO] Loaded users: $rawUsers');

    // 3. Process each route.
    for (final routeToUpdate in routesToUpdate) {
      final routeId = (routeToUpdate['name'] as String)
          .split('/')
          .last;
      final fieldsOfRoute = routeToUpdate['fields'] as Map<String, dynamic>;
      final routeFields = extractSimpleFields(fieldsOfRoute);

      final route = RouteData.fromFs(
        id: routeId,
        json: routeFields,
        defaultRefAcc: 0.5,
      );

      print('\n[ROUTE] =============================');
      print('[ROUTE] Route ID: $routeId');
      print('[ROUTE] Points: ${route.routePoints.length}');
      print('[ROUTE] Rating: ${route.rating}');
      print('[ROUTE] needsUpdate: ${routeFields['needsUpdate']}');

      // 4. Find all road segments that the route passes through.
      final userRoutePoints = route.routePoints
          .map((pt) => [pt.longitude, pt.latitude])
          .toList();
      final matchedSegmentIds = matchRouteToSegments(userRoutePoints, geojson);
      print('[ROUTE] Matched Segment IDs: $matchedSegmentIds');

      final routeRating = route.rating ?? 0.5;
      print('[ROUTE] Route rating used: $routeRating');

      // 5. Retrieve user info (disability type, weight).
      final userId = route.userId;
      print('[ROUTE] UserId: $userId');
      final userDoc = rawUsers.firstWhere(
            (u) => getUserIdFromNameField(u['name'] as String) == userId,
        orElse: () => {},
      );
      print('[ROUTE] UserDoc: $userDoc');

      if (userDoc.isEmpty) {
        print('[ERROR] User $userId not found in users!');
        continue;
      }

      final userFields = userDoc['fields'] as Map<String, dynamic>;
      final disabilityStr = userFields['disabilityType']?['stringValue'] ?? '';
      final disabilityType = disabilityTypeFromGreek(disabilityStr);
      final weight = getDisabilityWeight(disabilityType);
      print(
          '[ROUTE] Disability: "$disabilityStr" | Type: $disabilityType | Weight: $weight');

      // 6. Calculate and update accessibility for each matched segment.
      for (final segmentId in matchedSegmentIds) {
        final docId = segmentId.replaceAll('/', '_');

        // a. Fetch or create the segment in Firestore.
        final segmentDoc = await getOrCreateSegmentDoc(
          docId: docId,
          segmentId: segmentId,
          geojson: geojson,
          rest: _rest,
        );
        final P = extractAccessibilityScore(segmentDoc);
        print('[SEGMENT] Previous score: $P');

        // b. Update using the weighted user rating formula.
        final alpha = a;
        final W = weight;
        final R = routeRating;
        final Pnew = (P + alpha * W * (R - P)).clamp(0.0, 1.0);
        final color = determineColorAsHexString(Pnew);

        print('    [UPDATE]');
        print('      segmentId: $segmentId');
        print('      Pold: $P | R: $R | alpha: $alpha | W: $W');
        print('      Pnew: $Pnew | Color: $color');

        // c. PATCH update segment with new accessibility score and metadata.
        final roadFields = {
          'segmentId': {'stringValue': segmentId},
          'accessibilityScore': {'doubleValue': Pnew},
          'lastUpdatedByRoute': {'stringValue': route.id},
          'lastUpdatedByUser': {'stringValue': userId},
          'updatedAt': {
            'timestampValue': DateTime.now().toUtc().toIso8601String()
          },
        };
        await _rest.patchDoc(
          'roads',
          docId,
          roadFields,
          updateMaskFields: roadFields.keys
              .toList(), // Update only these fields!
        );
        print(
            '      [FIRESTORE] Updated segment $segmentId with score $Pnew for user $userId');
      }

      // 7. Mark this route as updated (needsUpdate = false).
      await _rest.patchDoc(
        'rated_routes',
        route.id,
        {'needsUpdate': {'booleanValue': false}},
        updateMaskFields: ['needsUpdate'],
      );
      print('[ROUTE] Reset needsUpdate for ${route.id}');
    }
    print('\n✅ Accessibility update completed for all routes needing update.');
  }

  /// Updates road accessibility based on obstacle reports
  Future<void> runReports({double a = 0.9}) async {
    //final geojsonPath = '../../../data/roads.geojson';
    final geojsonPath = Platform.environment['GEOJSON_PATH'] ?? 'data/roads.geojson';
    print('[STEP] Loading road geojson...');
    final geojson = await loadGeoJson(geojsonPath);
    print('[STEP] Geojson loaded with ${geojson.features.length} features.');

    // 1. Fetch all reports (user and municipal) that need update.
    print('[STEP] Loading reports needing update...');

    final userReportsRaw = await _rest.fetchCollectionDocuments('reports');
    final municipalReportsRaw = await _rest.fetchCollectionDocuments('municipal_reports');

    // Only keep those reports where needsUpdate == true
    final userReportsToUpdate = userReportsRaw.where((d) =>
    (d['fields'] as Map<String, dynamic>)['needsUpdate']?['booleanValue'] == true
    ).toList();

    final municipalReportsToUpdate = municipalReportsRaw.where((d) {
      final fields = d['fields'] as Map<String, dynamic>;
      final needsUpdate = fields['needsUpdate']?['booleanValue'] == true;
      final needsImprove = fields['needsImprove']?['booleanValue'] == true;
      return needsUpdate || needsImprove;
    }).toList();

    final allReports = [
      ...userReportsToUpdate.map((d) => {'doc': d, 'collection': 'reports'}),
      ...municipalReportsToUpdate.map((d) => {'doc': d, 'collection': 'municipal_reports'}),
    ];

    print('[STEP] Found ${allReports.length} reports needing update.');
    if (allReports.isEmpty) {
      print('No reports needing update. Exiting.');
      return;
    }

    // 2. Load all users for lookup (for user reports)
    final rawUsers = await _rest.listDocs('users');
    print('[INFO] Loaded users: $rawUsers');

    // 3. Process each report
    for (final reportData in allReports) {
      final doc = reportData['doc'] as Map<String, dynamic>;
      final collection = reportData['collection'] as String;
      final report = Report.fromFirestore(doc);

      print('\n[REPORT] =============================');
      print('[REPORT] Report ID: ${report.id}');
      print('[REPORT] UserId: ${report.userId} | Type: ${report.obstacleType}');
      print('[REPORT] Location: (${report.latitude}, ${report.longitude})');

      // Determine the user weight W (for municipal: fixed at 0.5)
      double W = 1.0;
      String disabilityStr = '';
      var disabilityType;
      final userId = report.userId;

      // --- MUNICIPAL LOGIC: DATE CHECKS FOR PROJECT START/END ---
      bool skip = false;            // If true, skip this report (e.g., project hasn't started)
      bool resolveObstacle = false; // If true, the obstacle is now considered solved (project ended)
      if (collection == 'municipal_reports') {
        W = 0.5;
        // Extract startDate and endDate from Firestore doc:
        final fields = doc['fields'] as Map<String, dynamic>;

        final bool needsImprove = fields['needsImprove']?['booleanValue'] == true;
        final bool needsUpdate = fields['needsUpdate']?['booleanValue'] == true;

        DateTime? endDate, startDate;
        try {
          final startDateStr = fields['startDate']?['timestampValue'];
          final endDateStr = fields['endDate']?['timestampValue'];
          if (startDateStr != null) startDate = DateTime.tryParse(startDateStr);
          if (endDateStr != null) endDate = DateTime.tryParse(endDateStr);
        } catch (e) {}

        final now = DateTime.now().toUtc();
        if (needsUpdate == false && (endDate == null || !now.isAfter(endDate))){
          print('[REPORT] Project doesnt need to update, but needs to be improved when end date comes, skipping update.');
          skip = true;
        }
        // If project has not started yet, skip this report!
        if (startDate != null && now.isBefore(startDate)) {
          print('[REPORT] Project not started yet (${startDate.toIso8601String()}), skipping update.');
          skip = true;
        }
        // If project has ended, set flag to improve accessibility:
        if (endDate != null && now.isAfter(endDate) && needsImprove == true) {
          print(endDate);
          print('[REPORT] Project has ended (${endDate.toIso8601String()}), accessibility will be improved!');
          resolveObstacle = true;
        }
      } else {
        // User reports: find user, get disability and weight
        final userDoc = rawUsers.firstWhere(
              (u) => getUserIdFromNameField(u['name'] as String) == userId,
          orElse: () => {},
        );
        if (userDoc.isEmpty) {
          print('[ERROR] User $userId not found! Using default weight 1.');
        } else {
          final userFields = userDoc['fields'] as Map<String, dynamic>;
          disabilityStr = userFields['disabilityType']?['stringValue'] ?? '';
          disabilityType = disabilityTypeFromGreek(disabilityStr);
          W = getDisabilityWeight(disabilityType);
        }
        print('[REPORT] User report: disability "$disabilityStr" | type $disabilityType | weight $W');
      }

      if (skip) {
        // Ignore this report for now, DO NOT mark as updated.
        // Let it be processed in a future run when the date arrives.
        continue;
      }

      // 4. Find nearest segment for this report
      final point = [report.longitude, report.latitude];
      final feature = findNearestFeature(point, geojson);
      if (feature == null) {
        print('[REPORT] No segment found for report: ${report.id}');
        continue;
      }
      final segmentId = feature.properties['id']?.toString() ?? '';
      final docId = segmentId.replaceAll('/', '_');
      print('[REPORT] Matched Segment ID: $segmentId');

      // 5. Fetch or create segment in Firestore
      final segmentDoc = await getOrCreateSegmentDoc(
        docId: docId,
        segmentId: segmentId,
        geojson: geojson,
        rest: _rest,
      );
      final P = extractAccessibilityScore(segmentDoc);
      print('[SEGMENT] Previous score: $P');

      // 6. Calculate the new accessibility score
      final ObstacleType obstacleType = obstacleTypeFromGreek(report.obstacleType);
      final double reportImpact = getObstacleWeight(obstacleType);
      final alpha = a;
      // If the project has ended, set R=1.0 (max accessibility, obstacle is solved)
      final double R = resolveObstacle ? 1.0 : reportImpact;
      final double Wupdate = W;
      final double Pnew = (P + alpha * Wupdate * (R - P)).clamp(0.0, 1.0);
      final String color = getObstacleImpactColor(Pnew);

      print('    [UPDATE]');
      print('      Weight: $Wupdate');
      print('      ObstacleType: ${report.obstacleType} | Impact: $reportImpact');
      print('      segmentId: $segmentId');
      print('      Pold: $P | Impact: $reportImpact | alpha: $alpha | W: $Wupdate');
      print('      Pnew: $Pnew | Color: $color');

      // 7. PATCH update segment with new accessibility score and metadata.
      final roadFields = {
        'segmentId': {'stringValue': segmentId},
        'accessibilityScore': {'doubleValue': Pnew},
        'lastUpdatedByReport': {'stringValue': report.id},
        'lastUpdatedByUser': {'stringValue': userId},
        'updatedAt': {'timestampValue': DateTime.now().toUtc().toIso8601String()},
      };
      await _rest.patchDoc(
        'roads',
        docId,
        roadFields,
        updateMaskFields: roadFields.keys.toList(),
      );
      print('      [FIRESTORE] Updated segment $segmentId with score $Pnew due to report ${report.id}');

      // 8. Mark this report as updated (needsUpdate = false)
      await _rest.patchDoc(
        collection,
        report.id,
        {'needsUpdate': {'booleanValue': false}},
        updateMaskFields: ['needsUpdate'],
      );

      // If the obstacle is resolved, also set needsImprove = false
      if (resolveObstacle == true) {
        await _rest.patchDoc(
          collection,
          report.id,
          {'needsImprove': {'booleanValue': false}},
          updateMaskFields: ['needsImprove'],
        );
        print('      [FIRESTORE] Set needsImprove = false for report ${report.id} in $collection');
      }

      print('      [FIRESTORE] Reset needsUpdate for report ${report.id} in $collection');
    }
    print('\n✅ Accessibility update completed for all reports needing update.');
  }

  /// Extracts the userId from Firestore's document 'name' field.
  String getUserIdFromNameField(String nameField) =>
      nameField
          .split('/')
          .last;

  /// Fetches a segment document from Firestore or creates it from GeoJSON if missing.
  Future<Map<String, dynamic>> getOrCreateSegmentDoc({
    required String docId,
    required String segmentId,
    required GeoJsonFeatureCollection geojson,
    required FirestoreRest rest,
  }) async {
    try {
      print('>>> [SEGMENT] Fetching doc $docId');
      final doc = await rest.getDoc('roads', docId);
      print('[SEGMENT] Fetched existing segment $segmentId from Firestore.');
      return doc;
    } catch (e) {
      // If not found, create it from geojson.
      GeoJsonFeature? feature;
      try {
        feature = geojson.features.firstWhere((f) =>
        f.properties['id']?.toString() == segmentId);
      } catch (_) {
        feature = null;
      }
      if (feature == null) {
        print('[ERROR] Segment $segmentId not found in geojson! Skipping...');
        throw Exception('Segment $segmentId not found in geojson');
      }
      // Prepare initial fields for Firestore.
      final Map<String, dynamic> initFields = {
        'segmentId': {'stringValue': segmentId},
        'geometry': {'stringValue': jsonEncode(feature.geometry.toJson())},
        'properties': {'stringValue': jsonEncode(feature.properties)},
        'accessibilityScore': {'doubleValue': 0.5},
        'createdAt': {
          'timestampValue': DateTime.now().toUtc().toIso8601String()
        },
      };
      await rest.patchDoc('roads', docId, initFields);
      print(
          '[CREATE] Created new segment $segmentId in Firestore with default score 0.5.');
      return {'fields': initFields};
    }
  }

  /// Converts Firestore fields to a simple flat map for easier use.
  Map<String, dynamic> extractSimpleFields(Map<String, dynamic> f) {
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
      } else if (m.containsKey('booleanValue')) {
        simple[k] = m['booleanValue'];
      } else if (m.containsKey('timestampValue')) {
        simple[k] = m['timestampValue'];
      }
    });
    return simple;
  }

  /// Returns the previous accessibility score from a Firestore doc, or 0.5 if missing.
  double extractAccessibilityScore(Map<String, dynamic> segmentDoc) {
    if (segmentDoc['fields'] != null) {
      final fields = segmentDoc['fields'] as Map<String, dynamic>;
      final accScore = fields['accessibilityScore'];
      if (accScore != null && accScore['doubleValue'] != null) {
        return (accScore['doubleValue'] as num).toDouble();
      }
    }
    print('[WARN] Segment accessibilityScore is empty, using default 0.5');
    return 0.5;
  }
}