import 'dart:io';
import 'package:googleapis_auth/auth_io.dart';
import 'utils/get_from_firebase.dart';
import '../models/lib/report.dart';
import 'utils/cluster_reports_algorithm.dart';

const _scopes = ['https://www.googleapis.com/auth/datastore'];

Future<void> main() async {
  final credentials = ServiceAccountCredentials.fromJson(
    File('firebase_conf.json').readAsStringSync(),
  );

  final authClient = await clientViaServiceAccount(credentials, _scopes);

  final projectId = 'access-b54d6';

  final userReports = await fetchCollectionDocuments(authClient, projectId, 'reports');
  final municipalReports = await fetchCollectionDocuments(authClient, projectId, 'municipal_reports');

  final allReports = [...userReports, ...municipalReports];

  final reportObjects = allReports.map((r) => Report.fromFirestore(r)).toList();


  for (final report in reportObjects) {
    print(report);
  }

  final clusters = clusterReports(reportObjects);

  print('Βρέθηκαν ${clusters.length} clusters:\n');

  for (var i = 0; i < clusters.length; i++) {
    print('Cluster ${i + 1} (μέγεθος: ${clusters[i].length}):');
    for (var report in clusters[i]) {
      print('  - ${report.locationDescription} (${report.latitude}, ${report.longitude})');
    }
    print('');
  }


  //print('Σύνολο αναφορών: ${allReports.length}');
  //print('Λίστα αναφορών:');

  //for (var i = 0; i < allReports.length; i++) {
  //  final report = allReports[i];
  //  final name = report['name'] ?? 'Unknown';
  //  final fields = report['fields'] as Map<String, dynamic>? ?? {};
//
  //  print('${i + 1}. Document name: $name');
//
  //  for (var key in fields.keys) {
  //    final dynamic rawValue = fields[key];
  //    var value;
//
  //    if (rawValue is Map<String, dynamic>) {
  //      if (rawValue.containsKey('stringValue')) {
  //        value = rawValue['stringValue'];
  //      } else if (rawValue.containsKey('integerValue')) {
  //        value = int.tryParse(rawValue['integerValue'].toString());
  //      } else if (rawValue.containsKey('doubleValue')) {
  //        value = double.tryParse(rawValue['doubleValue'].toString());
  //      } else if (rawValue.containsKey('booleanValue')) {
  //        value = rawValue['booleanValue'];
  //      } else if (rawValue.containsKey('timestampValue')) {
  //        value = DateTime.tryParse(rawValue['timestampValue'].toString());
  //      } else if (rawValue.containsKey('geoPointValue')) {
  //        final geo = rawValue['geoPointValue'];
  //        value = '(${geo['latitude']}, ${geo['longitude']})';
  //      } else if (rawValue.containsKey('mapValue')) {
  //        value = '[Map with ${rawValue['mapValue']['fields']?.length ?? 0} fields]';
  //      } else if (rawValue.containsKey('arrayValue')) {
  //        value = '[Array with ${rawValue['arrayValue']['values']?.length ?? 0} items]';
  //      } else {
  //        value = rawValue;
  //      }
  //    } else {
  //      value = rawValue;
  //    }
//
  //    print('    $key: $value');
  //  }
//
  //  print('---');
  //}


  authClient.close();
}
