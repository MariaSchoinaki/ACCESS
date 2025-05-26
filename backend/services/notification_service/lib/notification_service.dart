import 'dart:convert';
import 'dart:io';
import 'package:access_models/firebase/rest.dart';
import 'package:dio/dio.dart' as dio;
import 'package:googleapis_auth/auth_io.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

final Map<String, dynamic> _locations = {};
final dynamic _dio = dio.Dio();
late FirestoreRest firestoreRest;

void initializeFirestoreRest(FirestoreRest instance) {
  firestoreRest = instance;
}


Future<Response> _notifyHandler(Request request) async {
  try {
    final payload = await request.readAsString();
    final data = jsonDecode(payload);

    final userId = data['userId'];
    final userToken = data['userToken'];
    final latitude = data['latitude'];
    final longitude = data['longitude'];

    if (userId == null || latitude == null || longitude == null) {
      return Response.badRequest(
        body: jsonEncode({'error': 'Missing required fields'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    _locations[userId] = {
      'userToken': userToken,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': DateTime.now().toIso8601String(),
    };

    print('📍 Updated $userId → $latitude, $longitude');

    return Response.ok(
      jsonEncode({'status': 'success'}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    return Response.internalServerError(
      body: jsonEncode({'error': 'Invalid payload'}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}

Future<Response> sendTestNotification(Request request) async {
  try {
    final scope = 'https://www.googleapis.com/auth/firebase.messaging';

    final token = await firestoreRest.getToken(scope);
    print(token);

    final fcmUri = 'https://fcm.googleapis.com/v1/projects/${firestoreRest.projectId}/messages:send';
    for(final userId in _locations.keys){
      final user = _locations[userId];
      final userToken = user['userToken'];
      final payload = {
        "message": {
          "token": userToken,
          "notification": {
            "title": "ACCESS",
            "body": "Έλαβα την τοποθεσία σου! 😈"
          },
          "android": {
            "priority": "high",
            "notification": {
              "click_action": "FLUTTER_NOTIFICATION_CLICK"
            }
          },
          "apns": {
            "headers": {
              "apns-priority": "10"
            },
            "payload": {
              "aps": {
                "alert": {
                  "title": "ACCESS",
                  "body": "Έλαβα την τοποθεσία σου! 😈"
                },
                "sound": "default"
              }
            }
          },
          "data": {
            "customKey": "1234567890"
          }
        }
      };

      final response = await _dio.post(
        fcmUri,
        options: dio.Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json; charset=UTF-8',
          },
        ),
        data: jsonEncode(payload),
      );

      print('[FCM v1] Status code: ${response.statusCode}');
      print('[FCM v1] Response body: ${response.data}');


      return Response.ok('Notification sent: ${response.statusCode}');
    }
    return Response.ok('Notification sent!');
  } catch (e, st) {
    print('FCM Error: $e');
    print(st);
    return Response.internalServerError(body: 'Failed to send notification');
  }
}

Response _healthHandler(Request request) {
  return Response.ok('Notification service is up 🧠', headers: {'Content-Type': 'text/plain'});
}

Handler get handler {
  final router = Router()
    ..get('/health', _healthHandler)
    ..post('/notify', _notifyHandler)
    ..post('/send', sendTestNotification);

  return Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router);
}
