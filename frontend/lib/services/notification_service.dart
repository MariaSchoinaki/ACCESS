import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../main_mobile.dart';

/// This class is responsible for handling all notification-related tasks in the application,
/// including setting up notification channels, listening for incoming FCM messages,
/// displaying local notifications, handling notification clicks, and sending location
/// data to the backend. It implements the singleton pattern to ensure that only one
/// instance of this service exists throughout the app's lifecycle.
class NotificationService {
  /// Used for making HTTP requests to the backend.
  final Dio _dio;
  /// Plugin for displaying local notifications on the device.
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  /// Instance for interacting with Firebase Cloud Messaging.
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  /// Private static instance of NotificationService, used for the singleton pattern.
  static NotificationService? _instance;

  /// Factory constructor ensures that only one instance of NotificationService exists.
  /// If _instance is null, it creates a new instance via _internal; otherwise, it returns the existing one.
  factory NotificationService({Dio? dioClient, String? baseUrl}) {
    _instance ??= NotificationService._internal(dioClient: dioClient, baseUrl: baseUrl);
    return _instance!;
  }

  /// Private internal constructor used by the factory. It initializes the _dio instance.
  NotificationService._internal({Dio? dioClient, String? baseUrl}) : _dio = dioClient ?? Dio() {
    _init(baseUrl);
  }

  /// Initializes the Dio client's base URL and headers.
  void _init(String? baseUrl) {
    _dio.options = BaseOptions(
      baseUrl: _resolveBaseUrl(baseUrl),
      headers: {'Content-Type': 'application/json'},
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    );
  }

  /// Public static getter to access the singleton instance of NotificationService.
  /// If _instance is null, it creates a new instance (using the default constructor,
  /// which in turn calls the factory). This ensures lazy initialization.
  static NotificationService get instance {
    _instance ??= NotificationService();
    return _instance!;
  }

  /// Resolves the base URL for the Dio client, prioritizing environment variables
  /// and then the provided override URL or a default URL.
  static String _resolveBaseUrl(String? overrideUrl) {
    const envUrl = String.fromEnvironment('SEARCH_API_URL');
    return envUrl.isNotEmpty ? envUrl : (overrideUrl ?? 'http://ip:9090');
  }

  /// Asynchronous method to initialize notification channels, background geolocation,
  /// and Firebase Messaging listeners.
  Future<void> init() async {
    await setupNotificationChannel();

    /// --- Background Geolocation Listeners ---

    /// Fired whenever a location is recorded by the background geolocation plugin.
    bg.BackgroundGeolocation.onLocation((bg.Location location) {
      print('[location] - $location');
      _sendLocationToBackend(location);
    });

    /// Fired whenever the plugin changes motion-state (stationary->moving and vice-versa)
    bg.BackgroundGeolocation.onMotionChange((bg.Location location) {
      print('[motionchange] - $location');
    });

    /// Fired whenever the state of location-services changes.  Always fired at boot
    /// (e.g., GPS enabled/disabled)
    bg.BackgroundGeolocation.onProviderChange((bg.ProviderChangeEvent event) {
      print('[providerchange] - $event');
    });

    /// --- Background Geolocation Configuration and Start ---
    bg.BackgroundGeolocation.ready(bg.Config(
        desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
        distanceFilter: 10.0,
        stopOnTerminate: false,
        startOnBoot: true,
        debug: true,
        logLevel: bg.Config.LOG_LEVEL_VERBOSE
    )).then((bg.State state) {
      if (!state.enabled) {
        ////
        // 3.  Start the plugin.
        //
        bg.BackgroundGeolocation.start();
      }
    });

    /// --- Firebase Messaging Listeners ---
    /// Listens for incoming messages when the app is in the foreground.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📱 [Foreground] Message received: ${message.data}');
      if (message.notification != null) {
        final notification = message.notification!;
        final android = message.notification!.android;

        /// Displays a local notification using the flutter_local_notifications plugin.
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'access_notifications',
              'Access',
              channelDescription: '',
              importance: Importance.max,
              priority: Priority.high,
              icon: 'logo',
            ),
          ),
        );

        /// Shows an AlertDialog using the global navigatorKey when a foreground
        /// notification is received. This ensures the dialog is displayed on top
        /// of the current UI.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          handleNotificationNavigation(message);
        });
      }
    });

    /// Listens for when the user taps on a notification that opened the app
    /// from the background.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📲 [Opened from notification]');
      handleNotificationNavigation(message);
    });

    /// Gets the initial message if the app was opened from a terminated state
    /// by clicking on a notification.
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        print('📦 [Terminated → opened from notification]');
        handleNotificationNavigation(message);
      }
    });
  }

  /// Sets up the Android notification channel for your app.
  Future<void> setupNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'access_notifications',
      'Access Notifications',
      description: 'Channel for Access app notifications',
      importance: Importance.high,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Sends the device's location data to backend API.
  Future<void> _sendLocationToBackend(bg.Location location) async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      print('FCM token: $fcmToken');
      final data = {
        'userId': FirebaseAuth.instance.currentUser?.uid,
        'userToken': fcmToken,
        'latitude': location.coords.latitude,
        'longitude': location.coords.longitude,
        'timestamp': location.timestamp,
      };

      final response = await _dio.post('/notify', data: data);

      if (response.statusCode == 200) {
        print('Location sent successfully');
      } else {
        print('Failed to send location: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending location: $e');
    }
  }

}

/// This function is marked as the entry point for background isolate execution
/// when a Firebase Messaging background message is received. However, in the
/// provided code, it only logs the message data and doesn't perform any UI-related tasks
/// directly, as those need to be handled in the main isolate.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("🔙 [Background] Message data: ${message.data}");
}

/// Handles the navigation or UI display (in this case, an AlertDialog) when a
/// notification is tapped by the user or received in the foreground. It checks
/// for a 'route' key in the message data to perform navigation; otherwise, it shows a generic AlertDialog.
void handleNotificationNavigation(RemoteMessage message) {
  final data = message.data;
  final notification = message.notification;
  showDialog(
    context: navigatorKey.currentContext!,
    builder: (_) => AlertDialog(
      title: Text(notification?.title ?? "Notification"),
      content: Text(notification?.body ?? "No content"),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(navigatorKey.currentContext!),
          child: Text("ΟΚ"),
        ),
      ],
    ),
  );
  //TODO: implement navigation logic to the report
  /*
    final route = data['route'];
    if (route != null) {
      print('🚀 Navigating to $route');
      navigatorKey.currentState?.pushNamed(route);
    } else if (notification != null) {
      print('🔔 Notification title: ${notification.title}');
      print('📝 Notification body: ${notification.body}');
    }*/
}
