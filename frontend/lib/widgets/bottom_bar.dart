import 'package:access/screens/home_screen.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../screens/sign_up_screen.dart';
import '../utils/auth_gate.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.background,
        boxShadow: [BoxShadow(color: AppColors.black, blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
              );
            },
            child: const Icon(Icons.home, color: AppColors.black),
          ),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AuthGate()),
              );
            },
            child: const Icon(Icons.person, color: AppColors.black),
          ),
        ],
      ),
    );
  }
}