// splash_screen.dart
import 'package:flutter/material.dart';
import 'dart:html' as html;

// splash_screen.dart
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authToken = html.window.localStorage['authToken'];
    final currentPath = html.window.location.pathname;

    Future.microtask(() {
      if (authToken != null) {
        if (currentPath == '/profile') {
          html.window.history.replaceState({}, '','/profile');
          Navigator.pushReplacementNamed(context, '/profile');
        } else {
          html.window.history.replaceState({}, '', '/webhome');
          Navigator.pushReplacementNamed(context, '/webhome');
        }
      } else {
        html.window.history.replaceState({}, '', '/login');
        Navigator.pushReplacementNamed(context, '/login');
      }
    });

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}