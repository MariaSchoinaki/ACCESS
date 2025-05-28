import 'dart:io';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf/shelf.dart';
import '../lib/map_service.dart';// Change this if the file is elsewhere

Future<void> main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '8081') ?? 8081;
  print('>>> MAIN START');
  try {
    final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
    print('✅ map_service running on http://${server.address.address}:$port');
  } catch (e, st) {
    print('❌ Failed to start server: $e');
    print(st);
    exit(1);
  }
}
