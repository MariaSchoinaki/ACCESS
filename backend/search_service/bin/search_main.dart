import 'dart:io';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf/shelf.dart';
import 'package:search_service/search_service.dart';

void main() async {
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler((Request req) => handleSearchRequest(req)); // from lib

  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);

  print('🔍 search_service listening on port $port');
}
