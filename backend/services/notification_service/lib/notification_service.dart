import 'dart:convert';
import 'package:access_models/firebase/rest.dart';
import 'package:dio/dio.dart' as dio;
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'dart:async';
import 'dart:math';

/// Map that stores user locations.
/// Key: userId (String), Value: Map containing 'userToken', 'latitude', 'longitude', 'timestamp'.
final Map<String, dynamic> _locations = {};

/// Dio instance for HTTP requests.
final dynamic _dio = dio.Dio();
/// FirestoreRest instance for interacting with Firestore.
late FirestoreRest firestoreRest;

/// Function that initializes the FirestoreRest instance and starts the periodic check for nearby users.
void initializeFirestoreRest(FirestoreRest instance) {
  firestoreRest = instance;
  /// Executes findUsersNear every 1 minute.
  Timer.periodic(const Duration(minutes: 1), (Timer t) => findUsersNear());
}

/// Handler for the /notify endpoint. Updates a user's location.
Future<Response> _notifyHandler(Request request) async {
  try {
    /// Reads the request body as a String.
    final payload = await request.readAsString();
    /// Decodes the JSON payload into a Dart Map.
    final data = jsonDecode(payload);

    /// Extracts the necessary fields from the payload.
    final userId = data['userId'];
    final userToken = data['userToken'];
    final latitude = data['latitude'];
    final longitude = data['longitude'];

    /// Checks if any required fields are missing.
    if (userId == null || latitude == null || longitude == null) {
      return Response.badRequest(
        body: jsonEncode({'error': 'Missing required fields'}),
        headers: {'Content-Type': 'application/json'},
      );
    }

    /// Stores or updates the user's location in the _locations map.
    _locations[userId] = {
      'userToken': userToken,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': DateTime.now().toIso8601String(),
    };

    print('📍 Updated $userId → $latitude, $longitude');

    // Returns a successful response.
    return Response.ok(
      jsonEncode({'status': 'success'}),
      headers: {'Content-Type': 'application/json'},
    );
  } catch (e) {
    // Handles errors during payload reading or parsing.
    return Response.internalServerError(
      body: jsonEncode({'error': 'Invalid payload'}),
      headers: {'Content-Type': 'application/json'},
    );
  }
}

/// Function to send a notification to a user for a specific report.
Future<Response> sendNotification(Map<String, dynamic> user, String reportId,) async {
  print("notification was called!");
  try {
    /// Defines the scope for the token request for Firebase Messaging.
    final scope = 'https://www.googleapis.com/auth/firebase.messaging';

    /// Retrieves an OAuth 2.0 access token from FirestoreRest.
    final token = await firestoreRest.getToken(scope);
    print(token);

    /// Constructs the URI for the FCM v1 API to send messages.
    final fcmUri =
        'https://fcm.googleapis.com/v1/projects/${firestoreRest.projectId}/messages:send';
    // Retrieves the user's FCM token from the _locations map.
    final userToken = user['userToken'];
    print('sending notification to $reportId');
    /// the FCM message payload.
    final payload = {
      "message": {
        "token": userToken,
        "notification": {
          "title": "Νέα Αναφορά",
          "body": "📍 Υπάρχει μια νέα αναφορά κοντά σου!",
        },
        "android": {
          "priority": "high",
          "notification": {"click_action": "FLUTTER_NOTIFICATION_CLICK"},
        },
        "apns": {
          "headers": {"apns-priority": "10"},
          "payload": {
            "aps": {
              "alert": {
                "title": "Νέα Αναφορά",
                "body": "📍 Υπάρχει μια νέα αναφορά κοντά σου!",
              },
              "sound": "default",
            },
          },
        },
        "data": {"customKey": reportId},
      },
    };

    /// Makes the HTTP POST request to the FCM API.
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

    // Returns the response from the FCM API.
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

/// Handler for the /health endpoint. Returns an indication that the service is healthy.
Response _healthHandler(Request request) {
  return Response.ok(
    'Notification service is up 🧠',
    headers: {'Content-Type': 'text/plain'},
  );
}

/// Function that defines the handlers for the different routes of the server.
Handler get handler {
  final router =
      Router()
        ..get('/health', _healthHandler)
        ..post('/notify', _notifyHandler);

  // Creates a middleware pipeline for logging requests and adds the router.
  return Pipeline().addMiddleware(logRequests()).addHandler(router);
}

/// Function that finds users near new approved reports and sends notifications.
void findUsersNear() async {
  print('🔎 Running findUsersNear at ${DateTime.now()}');
  /// Retrieves municipal reports and adds a 'reportType' field.
  final reports =
      (await firestoreRest.fetchCollectionDocuments(
        'municipal_reports',
      )).map((r) => {...r, 'reportType': 'municipal_reports'}).toList();
  /// Retrieves user reports and adds a 'reportType' field.
  var user_reports =
      (await firestoreRest.fetchCollectionDocuments(
        'reports',
      )).map((r) => {...r, 'reportType': 'reports'}).toList();

  /// Defines the proximity radius in meters.
  final proximityRadius = 200;

  /// Filters user reports for approved and not yet notified ones.
  user_reports =
      user_reports.where((report) {
        final fields = report['fields'] as Map<String, dynamic>;
        return fields['isApproved']?['booleanValue'] == true &&
            fields['notificationSent']?['booleanValue'] != true;
      }).toList();
  reports.addAll(user_reports);

  /// Processes each report.
  for (final report in reports) {
    final reportId = report['name']?.split('/').last;
    print("report id: $reportId");
    final fields = report['fields'] as Map<String, dynamic>;

    final geoPointLocation =
        fields['coordinates']?['geoPointValue'] as Map<String, dynamic>?;
    final createdAtTimestamp =
        fields['timestamp']?['timestampValue'] as String?;

    // Parses the timestamp string to a DateTime object.
    final reportCreatedAt = DateTime.parse(createdAtTimestamp!);
    final now = DateTime.now();
    /// Calculates the time difference between now and the report creation time.
    final difference = now.difference(reportCreatedAt);

    /// Checks if the report is recent (created within the last hour).
    if (difference.inHours < 1) {
      final lat = double.tryParse(
        geoPointLocation?['latitude']?.toString() ?? '',
      );
      final lng = double.tryParse(
        geoPointLocation?['longitude']?.toString() ?? '',
      );

      if (lat != null && lng != null) {
        /// Checks each user in the stored locations.
        for (final user in _locations.keys) {
          print('$user: ${user.runtimeType}');
          final userLat = _locations[user]['latitude'];
          final userLng = _locations[user]['longitude'];
          final distance = haversineDistance(lat, lng, userLat, userLng);
          if (distance <= proximityRadius) {
            final notificationSentResult = await sendNotification(
              _locations[user],
              reportId,
            );
            // If the notification was sent successfully.
            if (notificationSentResult.statusCode >= 200 &&
                notificationSentResult.statusCode < 300) {
              // Updates the 'notificationSent' field in the corresponding report in Firestore.
              await firestoreRest.patchDoc(
                report['reportType'], // Uses 'reportType' to know which collection to patch.
                reportId,
                {
                  'notificationSent': {'booleanValue': true},
                },
                updateMaskFields: ['notificationSent'],
              );
              print(
                "Notification sent and 'notificationSent' updated for report: $reportId",
              );
            } else {
              print(
                "Failed to send notification for report: $reportId. Not marking as sent.",
              );
            }
          }
        }
      }
    }
  }
}

/// Calculates distance (in meters) using the Haversine formula
double haversineDistance(double lat1, double lon1, double lat2, double lon2) {
  print("calculating distance...");
  const R = 6371000; // Earth radius in meters
  final dLat = _toRadians(lat2 - lat1);
  final dLon = _toRadians(lon2 - lon1);
  final a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(lat1)) *
          cos(_toRadians(lat2)) *
          sin(dLon / 2) *
          sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c;
}

/// Converts degrees to radians.
double _toRadians(double degree) => degree * pi / 180;
