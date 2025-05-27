import 'dart:convert';
import 'dart:io';
import 'package:access_models/firebase/rest.dart';
import 'package:dio/dio.dart' as dio;
import 'package:googleapis_auth/auth_io.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:async';
import 'dart:math';

final Map<String, dynamic> _locations = {};

final dynamic _dio = dio.Dio();
late FirestoreRest firestoreRest;

void initializeFirestoreRest(FirestoreRest instance) {
  firestoreRest = instance;
  Timer.periodic(const Duration(minutes: 1), (Timer t) => findUsersNear());
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

Future<Response> sendNotification(Map<String, dynamic> user, String reportId) async {
  print("notification was called!");
  try {
    final scope = 'https://www.googleapis.com/auth/firebase.messaging';

    final token = await firestoreRest.getToken(scope);
    print(token);

    final fcmUri = 'https://fcm.googleapis.com/v1/projects/${firestoreRest.projectId}/messages:send';
    final userToken = user['userToken'];
    print('sending notification to $reportId');
    final payload = {
      "message": {
        "token": userToken,
        "notification": {
          "title": "Νέα Αναφορά",
          "body": "📍 Υπάρχει μια νέα αναφορά κοντά σου!"
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
                "title": "Νέα Αναφορά",
                "body": "📍 Υπάρχει μια νέα αναφορά κοντά σου!"
              },
              "sound": "default"
            }
          }
        },
        "data": {
          "customKey": reportId
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
  } catch (e, st) {
    print('FCM Error: $e');
    if (e is dio.DioException && e.response != null) {
      print('FCM Error Response Data: ${e.response!.data}');
    }
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
    ..post('/notify', _notifyHandler);

  return Pipeline()
      .addMiddleware(logRequests())
      .addHandler(router);
}

void findUsersNear() async {
  print('🔎 Running findUsersNear at ${DateTime.now()}');
  final reports = await firestoreRest.fetchCollectionDocuments('municipal_reports');
  var user_reports = await firestoreRest.fetchCollectionDocuments('reports');
  final proximityRadius = 200;
  print("got reports");
  user_reports = user_reports.where((report) {
    final fields = report['fields'] as Map<String, dynamic>;
    return fields['isApproved']?['booleanValue'] == true;
  }).toList();
  reports.addAll(user_reports);

  //TODO: only the most recent reports
  for(final report in reports){
    final fields = report['fields'] as Map<String, dynamic>;
    final geoPointLocation = fields['coordinates']?['geoPointValue'] as Map<String, dynamic>?;
    final lat = double.tryParse(geoPointLocation!['latitude']?.toString() ?? '');
    final lng = double.tryParse(geoPointLocation['longitude']?.toString() ?? '');
    final createdAtTimestamp = fields['createdAt']?['timestampValue'] as String?;
    for(final user in _locations.keys){
      print("users now");
      print('$user: ${user.runtimeType}');
      final userLat = _locations[user]['latitude'];
      final userLng = _locations[user]['longitude'];
      final distance = haversineDistance(lat!, lng!, userLat, userLng);
      if (distance <= proximityRadius){
        await sendNotification(_locations[user], report['name']);
      }
    }
  }
}

// Calculates distance (in meters) using the Haversine formula
double haversineDistance(double lat1, double lon1, double lat2, double lon2) {
  print("calculating distance...");
  const R = 6371000; // Earth radius in meters
  final dLat = _toRadians(lat2 - lat1);
  final dLon = _toRadians(lon2 - lon1);
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
          sin(dLon / 2) * sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}

double _toRadians(double degree) => degree * pi / 180;