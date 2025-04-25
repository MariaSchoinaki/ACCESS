import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/login_screen.dart';
import '../screens/myaccount_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Εμφάνιση φόρτωσης όσο περιμένουμε τα πρώτα δεδομένα
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Αν ο χρήστης είναι συνδεδεμένος
        if (snapshot.hasData) {
          return const MyAccountScreen();
        }

        // Αν δεν υπάρχει ενεργός χρήστης
        return LoginScreen();
      },
    );
  }
}
