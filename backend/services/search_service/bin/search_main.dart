import 'dart:io';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf/shelf.dart';
import 'package:search_service/search_service.dart'; // Custom handler from lib/

Future<void> main() async {
  // Create a request pipeline:
  // - Adds logging middleware for requests
  // - Connects to the custom search request handler
  final handler = Pipeline()
      .addMiddleware(logRequests()) // Logs method, URI, status, duration
      .addHandler((Request request) async {
        print('Received request: ${request.method} ${request.url}');
    if (request.url.path == 'retrieve') {
      return await handleCoordinatesRequest(request);
    }else if (request.url.path == 'getname'){
      return await getLocationNameFromMapbox(request);
    }else if (request.url.path == 'category') {
      return await handleSearchByCategoryRequest(request);
    } else if (request.url.path == 'poi') {
      print('Received request to /poi');
      return await handlePoiRequest(request);
    }
    return await handleSearchRequest(request);  // Υπάρχων handler για search
  }); // Defined in lib/search_service.dart

  // Read the port from environment or use 8080 by default
  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;

  // Start the HTTP server
  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);

  // Logging output to terminal
  print('\x1B[32m√ search_service is running on http://${server.address.host}:${server.port}\x1B[0m');
}