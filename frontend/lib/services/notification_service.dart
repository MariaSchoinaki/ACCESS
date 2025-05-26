import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import '../main_mobile.dart';

class NotificationService {
  final Dio _dio;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  NotificationService({String? baseUrl, Dio? dioClient})
      : _dio = dioClient ??
      Dio(
        BaseOptions(
          baseUrl: _resolveBaseUrl(baseUrl),
          headers: {'Content-Type': 'application/json'},
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      ) {
    print('\x1B[32m[NotificationService] Base URL: ${_dio.options
        .baseUrl}\x1B[0m');
  }

  static String _resolveBaseUrl(String? overrideUrl) {
    const envUrl = String.fromEnvironment('SEARCH_API_URL');
    return envUrl.isNotEmpty ? envUrl : (overrideUrl ?? 'http://ip:9090');
  }

  Future<void> init() async {
    if (await Permission.notification.isDenied) {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    await setupNotificationChannel();

    // Fired whenever a location is recorded
    bg.BackgroundGeolocation.onLocation((bg.Location location) {
      print('[location] - $location');
      _sendLocationToBackend(location);
    });

    // Fired whenever the plugin changes motion-state (stationary->moving and vice-versa)
    bg.BackgroundGeolocation.onMotionChange((bg.Location location) {
      print('[motionchange] - $location');
    });

    // Fired whenever the state of location-services changes.  Always fired at boot
    bg.BackgroundGeolocation.onProviderChange((bg.ProviderChangeEvent event) {
      print('[providerchange] - $event');
    });

    ////
    // 2.  Configure the plugin
    //
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

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📱 [Foreground] Message received: ${message.data}');
      if (message.notification != null) {
        final notification = message.notification!;
        final android = message.notification!.android;

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
      }
    });
  }



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
        // πρόσθεσε ό,τι άλλο θες
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



  Future<void> setupNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'access_notifications', // το ίδιο ID που θα βάλεις στο backend payload
      'Access Notifications',
      description: 'Channel for Access app notifications',
      importance: Importance.high,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

}
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("🔙 [Background] Message data: ${message.data}");
  final notification = message.notification;
  final android = notification?.android;

  if (notification != null && android != null) {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'access_notifications',
      'Access',
      channelDescription: 'Default notification channel',
      importance: Importance.max,
      priority: Priority.high,
      icon: 'logo',
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      platformDetails,
    );
  }
}

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