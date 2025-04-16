import 'dart:io';
import 'dart:convert';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:dio/dio.dart';

final dio = Dio(BaseOptions(
  connectTimeout: const Duration(seconds: 5),
  receiveTimeout: const Duration(seconds: 5),
));

final String searchServiceUrl = 'http://search_service:8080';

void main() async {
  final router = Router();

  // Health check
  router.get('/health', (shelf.Request request) {
    return shelf.Response.ok('OK');
  });

  // Forward /search to search_service
  router.all('/search<ignored|.*>', (shelf.Request request) async {
    final uri = Uri.parse(
      '$searchServiceUrl${request.requestedUri.path}${request.requestedUri.hasQuery ? '?${request.requestedUri.query}' : ''}',
    );
    

    try {
      final response = await dio.request(
        uri.toString(),
        options: Options(
          method: request.method,
          headers: Map.from(request.headers),
          responseType: ResponseType.json,
        ),
        data: await request.readAsString(),
      );

      return shelf.Response(
        response.statusCode ?? 500,
        body: jsonEncode(response.data),
        headers: {'Content-Type': 'application/json'},
      );
    } on DioException catch (e) {
      stderr.writeln('DioException: ${e.message}');
      return shelf.Response.internalServerError(
        body: 'Gateway error: ${e.message}',
        headers: {'Content-Type': 'text/plain'},
      );
    } catch (e) {
      stderr.writeln('Unexpected error: $e');
      return shelf.Response.internalServerError(
        body: 'Gateway error: $e',
        headers: {'Content-Type': 'text/plain'},
      );
    }
  });

  // Add logging middleware and start server
  final handler = const shelf.Pipeline()
      .addMiddleware(shelf.logRequests())
      .addHandler(router);

  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  final server = await serve(handler, InternetAddress.anyIPv4, port);

  print('API Gateway running on port $port');
}
