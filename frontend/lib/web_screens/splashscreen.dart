// splash_screen.dart
import 'package:flutter/material.dart';
import 'dart:html' as html;

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authToken = html.window.localStorage['authToken'];
    Future.microtask(() {
      if (authToken != null) {
        Navigator.pushReplacementNamed(context, '/webhome');
        html.window.history.replaceState(null, '', '/webhome');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
        html.window.history.replaceState(null, '', '/login');
      }
    });

    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}