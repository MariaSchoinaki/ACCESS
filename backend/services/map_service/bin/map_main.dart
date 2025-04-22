import 'dart:io';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf/shelf.dart';
import 'package:map_service/map_service.dart'; // Custom handler from lib/

Future<void> main() async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '8081') ?? 8081;
  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  print('✅ map_service running on http://${server.address.address}:$port');
}
