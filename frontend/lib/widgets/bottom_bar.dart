import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../blocs/report_obstacle_bloc/report_obstacle_bloc.dart';
import '../screens/home_screen.dart';
import '../screens/report_obstacle_screen.dart';
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

  Future<void> _openCamera(BuildContext context) async {

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SizedBox(
            height: MediaQuery.of(dialogContext).size.height * 0.9, // 90% pf screen
            child: BlocProvider(
              create: (context) => ReportObstacleBloc(),
              child: const ReportObstacleScreen(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Container(
      height: 55,
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
          if (user != null)
            IconButton(
              onPressed: () => _openCamera(context),
              icon: const Icon(Icons.add_box_rounded, size: 30),
            ),
          IconButton(
            onPressed: () {
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
