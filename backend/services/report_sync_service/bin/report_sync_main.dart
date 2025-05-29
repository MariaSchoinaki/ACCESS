import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:access_models/firebase/rest.dart';
import 'package:access_models/municipality_mapping.dart';
import 'package:access_models/report.dart';
import 'package:report_sync_service/cluster_reports.dart';
import '../lib/report_sync_service.dart';

late MunicipalityMapping municipalityMapping; // for handler access



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
          'timestamp': report.timestamp.toIso8601String(),
          'latitude': report.latitude,
          'longitude': report.longitude,
          'obstacleType': report.obstacleType,
          'locationDescription': report.locationDescription,
          'imageUrl': report.imageUrl,
          'accessibility': report.accessibility,
          'description': report.description,
          'userId': report.userId,
          'userEmail': report.userEmail,
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

