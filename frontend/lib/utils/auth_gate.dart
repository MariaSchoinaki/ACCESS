import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Adjust import paths based on your project structure
import '../screens/login_screen.dart';
import '../screens/myaccount_screen.dart';

/// A widget that acts as an authentication gate.
///
/// Listens to Firebase authentication state changes ([FirebaseAuth.instance.authStateChanges])
/// and displays either the [MyAccountScreen] if a user is logged in,
/// or the [LoginScreen] if no user is logged in. It shows a loading indicator
/// while waiting for the initial authentication state.
class AuthGate extends StatelessWidget {
  /// Creates a const [AuthGate].
  const AuthGate({super.key});

  @override
  /// Builds the widget tree based on the authentication state.
  ///
  /// Uses a [StreamBuilder] to reactively rebuild when the auth state changes.
  /// It displays:
  /// - A loading indicator while waiting for the connection.
  /// - [MyAccountScreen] if the user is authenticated ([snapshot.hasData] is true).
  /// - [LoginScreen] if the user is not authenticated.
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // Listen to the stream of authentication state changes from Firebase Auth.
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show a loading indicator while waiting for the initial auth state result.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold( // Provides a basic layout during loading
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If the snapshot contains user data, the user is signed in.
        if (snapshot.hasData) {
          // Display the screen for authenticated users.
          return const MyAccountScreen();
        }

        // If the snapshot has no data, the user is signed out.
        // Display the login screen.
        return LoginScreen();
      },
    );
  }
}