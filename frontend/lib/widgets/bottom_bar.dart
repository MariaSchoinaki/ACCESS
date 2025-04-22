import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../utils/auth_gate.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

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
      height: 55, // Σταθερό ύψος
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, -1),
          )
        ],
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(0.15),
            width: 0.8,
          ),
        ),
      ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: () => _navigateToScreen(context, const HomePage(), '/home'),
              icon: const Icon(Icons.home, size: 30),
            ),
            IconButton(
              onPressed: () {
                // Ειδικός έλεγχος για signup/login
                final currentRoute = ModalRoute.of(context)?.settings.name;
                if (currentRoute != '/signup' && currentRoute != '/login') {
                  _navigateToScreen(context, const AuthGate(), '/profile');
                }
              },
              icon: const Icon(Icons.person, size: 30),
            ),
          ],
        ),
    );
  }
}