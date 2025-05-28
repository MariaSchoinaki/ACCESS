import 'package:access_models/report.dart';
import 'package:access_models/firebase/rest.dart';
import '../../report_sync_service/lib/cluster_reports.dart';

Future<void> main() async {
  final rest = FirestoreRest.fromServiceAccount('firebase_conf.json');

  final userReports = await rest.fetchCollectionDocuments('reports');
  final municipalReports = await rest.fetchCollectionDocuments('municipal_reports');

  final allReports = [...userReports, ...municipalReports];

  final reportObjects = allReports.map((r) => Report.fromFirestore(r)).toList();

  for (final report in reportObjects) {
    print(report);
  }

  final clusters = clusterReports(reportObjects);

  print('Found ${clusters.length} clusters:\n');

  for (var i = 0; i < clusters.length; i++) {
    print('Cluster ${i + 1} (size: ${clusters[i].length}):');
    for (var report in clusters[i]) {
      print('  - ${report.locationDescription} (${report.latitude}, ${report.longitude})');
    }
    print('');
  }
}
