import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../utils/auth_gate.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  // Βοηθητική συνάρτηση για έλεγχο σελίδας
  void _navigateToScreen(BuildContext context, Widget screen, String routeName) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (currentRoute != routeName) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => screen,
          settings: RouteSettings(name: routeName),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            onPressed: () => _navigateToScreen(context, const HomePage(), '/home'),
            icon: const Icon(Icons.home, size: 30),
          ),
          IconButton(
            onPressed: () => _navigateToScreen(context, const AuthGate(), '/profile'),
            icon: const Icon(Icons.person, size: 30),
          ),
        ],
      ),
    );
  }
}