import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'admin_dashboard_screen.dart';
import 'admin_login_screen.dart';

class AdminAuthGate extends StatelessWidget {
  const AdminAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Αν περιμένουμε ακόμα την αρχική κατάσταση auth
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Αν ο χρήστης είναι συνδεδεμένος
        if (snapshot.hasData) {
          // TODO: Προαιρετικά, έλεγξε εδώ αν ο συνδεδεμένος χρήστης ΕΙΝΑΙ admin
          // π.χ., ελέγχοντας το email του ή ένα custom claim από το Firebase Auth
          // if (snapshot.data!.email == 'admin@example.com') {
          return const AdminDashboardScreen();
          // } else {
          //   // Δεν είναι admin, δείξε μήνυμα ή τη login screen ξανά;
          //   // Εδώ θα μπορούσε να γίνει αυτόματη αποσύνδεση και εμφάνιση login
          //    print("User ${snapshot.data!.email} is not authorized admin.");
          //    FirebaseAuth.instance.signOut(); // Κάνε τον logout
          //    return const AdminLoginScreen(); // Δείξε login
          // }
        }

        // Αν ο χρήστης ΔΕΝ είναι συνδεδεμένος
        return const AdminLoginScreen();
      },
    );
  }
}