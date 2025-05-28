import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:access_models/firebase/rest.dart';
import 'package:access_models/municipality_mapping.dart';
import 'package:access_models/report.dart';
import '../lib/report_sync_service.dart';

late MunicipalityMapping municipalityMapping; // for handler access

// -------- Added from cluster_reports.dart --------
double haversineDistance(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371000; // Earth radius in meters
  final dLat = _toRadians(lat2 - lat1);
  final dLon = _toRadians(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
          sin(dLon / 2) * sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}

double _toRadians(double degree) => degree * pi / 180;

List<List<Report>> clusterReports(List<Report> reports) {
  final List<List<Report>> clusters = [];

  for (var report in reports) {
    bool addedToCluster = false;

    for (var cluster in clusters) {
      for (var existing in cluster) {
        final distance = haversineDistance(
          report.latitude,
          report.longitude,
          existing.latitude,
          existing.longitude,
        );

        final timeDiff = report.timestamp.difference(existing.timestamp).inDays;

        if (distance < 15 && timeDiff.abs() <= 3) {
          cluster.add(report);
          addedToCluster = true;
          break;
        }
      }
      if (addedToCluster) break;
    }

    if (!addedToCluster) {
      clusters.add([report]);
    }
  }

  return clusters;
}

Future<void> handleClusterReports(HttpRequest request, FirestoreRest rest) async {
  try {
    final userReports = await rest.fetchCollectionDocuments('reports');
    final municipalReports = await rest.fetchCollectionDocuments('municipal_reports');
    final allReports = [...userReports, ...municipalReports];

    final reportObjects = allReports.map((r) => Report.fromFirestore(r)).toList();
    final clusters = clusterReports(reportObjects);

    // Convert clusters to JSON-serializable format
    final clustersJson = clusters.map((cluster) {
      return cluster.map((report) {
        return {
          'id': report.id,
          'locationDescription': report.locationDescription,
          'latitude': report.latitude,
          'longitude': report.longitude,
          'timestamp': report.timestamp.toIso8601String(),
          // Add other report fields as needed
        };
      }).toList();
    }).toList();

    request.response
      ..headers.contentType = ContentType.json
      ..headers.add('Access-Control-Allow-Origin', '*')
      ..write(jsonEncode(clustersJson))
      ..close();
  } catch (e) {
    request.response
      ..statusCode = HttpStatus.internalServerError
      ..write(jsonEncode({'error': e.toString()}))
      ..close();
  }
}

Future<void> main(List<String> args) async {
  //final saPath = '../firebase_conf.json';
  final saPath = Platform.environment['FIREBASE_CONF3.JSON'] ?? 'firebase_conf.json';
  if (!File(saPath).existsSync()) {
    stderr.writeln('❌ Cannot find service-account JSON at "$saPath"');
    exit(1);
  }

  //final postalCsvPath = '../../../data/postalcode.csv';
  final postalCsvPath = Platform.environment['POSTAL_CONF'] ?? 'data/postalcode.csv';
  if (!File(postalCsvPath).existsSync()) {
    stderr.writeln('❌ Cannot find postal CSV at "$postalCsvPath"');
    exit(1);
  }

  print('>>> [MAIN] Loading Firestore credentials...');
  final rest = FirestoreRest.fromServiceAccount(saPath);

  print('>>> [MAIN] Loading postal codes...');
  final csvString = await File(postalCsvPath).readAsString();
  municipalityMapping = MunicipalityMapping.fromCsv(csvString);

  print('>>> [MAIN] Creating statistics service...');
  final statsService = StatisticsService(rest, municipalityMapping);

  final server = await HttpServer.bind(InternetAddress.anyIPv4, 8083);
  print('Statistics service running on http://localhost:8083/');

  await for (HttpRequest request in server) {
    if (request.uri.path == '/stats') {
      await handleStats(request, statsService);
    } else if (request.uri.path == '/reports-by-tk') {
      await handleMunicipalityReports(request, statsService);
    } else if (request.uri.path == '/health') {
      request.response
        ..statusCode = HttpStatus.ok
        ..write('OK')
        ..close();
    } else if (request.uri.path == '/setreport') {
      await handleClusterReports(request, rest);
    } else {
      request.response
        ..statusCode = HttpStatus.notFound
        ..write('Not Found')
        ..close();
    }
  }
}

// NEW: Handler for /municipality endpoint
Future<void> handleMunicipalityLookup(HttpRequest request) async {
  final tk = request.uri.queryParameters['tk'];
  if (tk == null) {
    request.response
      ..statusCode = HttpStatus.badRequest
      ..write(jsonEncode({'error': 'Missing tk parameter'}))
      ..close();
    return;
  }
  final municipality = municipalityMapping.getMunicipality(tk) ?? 'Άγνωστος';
  request.response
    ..headers.contentType = ContentType.json
    ..write(jsonEncode({'tk': tk, 'municipality': municipality}))
    ..close();
}

Future<void> handleStats(HttpRequest request, StatisticsService statsService) async {
  try {
    final statsAndReports = await statsService.statsAndReportsPerMunicipality();
    request.response
      ..headers.contentType = ContentType.json
      ..headers.add('Access-Control-Allow-Origin', '*')
      ..write(jsonEncode(statsAndReports))
      ..close();
  } catch (e) {
    request.response
      ..statusCode = HttpStatus.internalServerError
      ..write('{"error": "${e.toString()}"}')
      ..close();
  }
}

Future<void> handleMunicipalityReports(HttpRequest request, StatisticsService statsService) async {
  try {
    // Get TK (postal code) from frontend
    final tk = request.uri.queryParameters['tk'];
    if (tk == null || tk.isEmpty) {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write(jsonEncode({'error': 'Missing postal code parameter (tk).'}))
        ..close();
      return;
    }

    // Get all reports and mapping
    final allStats = await statsService.statsAndReportsPerMunicipality();

    // Use your MunicipalityMapping to get the municipality
    final municipality = statsService.municipalityMapping.getMunicipality(tk);

    // Get reports for that municipality
    final reports = allStats['reports']?[municipality] ?? [];

    request.response
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'municipality': municipality, 'reports': reports}))
      ..close();
  } catch (e) {
    request.response
      ..statusCode = HttpStatus.internalServerError
      ..write(jsonEncode({'error': e.toString()}))
      ..close();
  }
}

