import 'package:flutter/material.dart';

import '../../widgets/bottom_bar.dart';

class MyAccountScreen extends StatelessWidget {
  const MyAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F0),
      body: const Center(
        child: Text("Εδώ είναι το προφίλ"),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}