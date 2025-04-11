import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

void main() async {
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addHandler((Request request) {
    return Response.ok('✅ Hello from search_service!');
  });

  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);

  print('🚀 search_service listening on port ${server.port}');
}
