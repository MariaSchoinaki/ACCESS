import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:notification_service/notification_service.dart';
import 'package:shelf/shelf_io.dart' as io; // Custom handler from lib/
import 'package:access_models/firebase/rest.dart';

Future<void> main() async {
  final saPath = Platform.environment['FIREBASE_CONF2.JSON'] ?? 'firebase_conf.json';
  if (!File(saPath).existsSync()) {
    stderr.writeln('❌ Cannot find service-account JSON at "$saPath"');
    exit(1);
  }

  print('>>> [MAIN] Loading Firestore credentials...');
  final rest = FirestoreRest.fromServiceAccount(saPath);
  initializeFirestoreRest(rest);
  final port = int.parse(Platform.environment['PORT'] ?? '8089');
  final server = await io.serve(handler, InternetAddress.anyIPv4, port);
  print('✅ NotificationService running on port ${server.port}');
}