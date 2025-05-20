import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:dio/dio.dart';

// Shared Dio client with timeouts
final Dio dio = Dio(BaseOptions(
  connectTimeout: const Duration(seconds: 5),
  receiveTimeout: const Duration(seconds: 5),
));

// Docker service names
const String searchServiceUrl = 'http://search_service:8080';
const String mapServiceUrl = 'http://map_service:8081';

Future<void> main() async {
  final router = Router();

  // Health check
  router.get('/health', (shelf.Request request) {
    return shelf.Response.ok('Gateway OK');
  });

  // no stripPrefix here
  router.all('/search<ignored|.*>', (req) => _proxy(req, searchServiceUrl, stripPrefix: ''));
  router.all('/retrieve<ignored|.*>', (req) => _proxy(req, searchServiceUrl, stripPrefix: ''));
  router.all('/getname<ignored|.*>', (req) => _proxy(req, searchServiceUrl, stripPrefix: ''));
  router.all('/category<ignored|.*>', (req) => _proxy(req, searchServiceUrl, stripPrefix: ''));
  router.all('/poi<ignored|.*>', (req) => _proxy(req, searchServiceUrl, stripPrefix: ''));

  print('> Proxy /search to $searchServiceUrl');
  // Proxy /map to map service
  router.all('/map<ignored|.*>', (req) =>
      _proxy(req, mapServiceUrl, stripPrefix: '/map'));

  final handler = const shelf.Pipeline()
      .addMiddleware(shelf.logRequests())
      .addHandler(router);

  final port = int.tryParse(Platform.environment['PORT'] ?? '9090') ?? 9090;
  final server = await serve(handler, InternetAddress.anyIPv4, port);

  print('\x1B[32m✅ Gateway running on http://${server.address.address}:$port\x1B[0m');
}

Future<shelf.Response> _proxy(
    shelf.Request request,
    String targetBaseUrl, {
      required String stripPrefix,
    }) async {
  final originalPath = request.url.path;

  // Strip the prefix (e.g., "/map" or "/search")
  final strippedPath = originalPath.startsWith(stripPrefix.replaceFirst('/', ''))
      ? originalPath.substring(stripPrefix.length)
      : originalPath;

  final normalizedPath = strippedPath.startsWith('/')
      ? strippedPath
      : '/$strippedPath';

  final query = request.url.query.isNotEmpty ? '?${request.url.query}' : '';
  final targetUri = Uri.parse('$targetBaseUrl$normalizedPath$query');

  print('[GATEWAY] Forwarding ${request.method} /$originalPath → $targetUri');

  try {
    final response = await dio.request(
      targetUri.toString(),
      options: Options(
        method: request.method,
        headers: Map.from(request.headers),
        responseType: ResponseType.json,
        validateStatus: (_) => true,
      ),
      data: await request.readAsString(),
    );

    final contentType = response.headers.map['content-type']?.first ?? 'application/json';
    final responseBody = response.data is String
        ? response.data
        : jsonEncode(response.data);

    return shelf.Response(
      response.statusCode ?? 500,
      body: responseBody,
      headers: {'Content-Type': contentType},
    );
  } on DioException catch (e) {
    stderr.writeln('[GATEWAY ERROR] Dio: ${e.message}');
    return shelf.Response.internalServerError(
      body: 'Gateway DioException: ${e.message}',
      headers: {'Content-Type': 'text/plain'},
    );
  } catch (e, stack) {
    stderr.writeln('[GATEWAY ERROR] Unexpected: $e\n$stack');
    return shelf.Response.internalServerError(
      body: 'Gateway internal error: $e',
      headers: {'Content-Type': 'text/plain'},
    );
  }
}
