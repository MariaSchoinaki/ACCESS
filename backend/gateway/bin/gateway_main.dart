import 'dart:io';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:dio/dio.dart';

final dio = Dio();
final String searchServiceUrl = 'http://search_service:8080';

void main() async {
  final router = Router();

  // Προώθηση στο search_service
  router.all('/search<ignored|.*>', (shelf.Request request) async {
    final uri = Uri.parse('$searchServiceUrl${request.requestedUri.path}${request.requestedUri.hasQuery ? '?${request.requestedUri.query}' : ''}');

    try {
      final response = await dio.request(
        uri.toString(),
        options: Options(
          method: request.method,
          headers: Map.from(request.headers),
        ),
        data: await request.readAsString(),
      );

      return shelf.Response(
        response.statusCode ?? 500,
        body: response.data.toString(),
        headers: Map.from(response.headers.map),
      );
    } catch (e) {
      return shelf.Response.internalServerError(body: 'Gateway error: $e');
    }
  });

  final handler = const shelf.Pipeline()
      .addMiddleware(shelf.logRequests())
      .addHandler(router);

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, InternetAddress.anyIPv4, port);
  print('🚀 API Gateway running on port $port');
}