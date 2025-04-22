import 'package:access/screens/myaccount/log%20in/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/myaccount/myaccount_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: FirebaseAuth.instance.authStateChanges().first,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          return const MyAccountScreen(); // Ο χρήστης είναι ήδη συνδεδεμένος
        } else {
          return const LoginScreen(); // Ο χρήστης δεν είναι συνδεδεμένος
        }
      },
    );
  }
}
