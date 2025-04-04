import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Καλωσήρθες στο ACCESS'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Ξεκίνα να σχεδιάζεις τη μετακίνησή σου!',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Εδώ θα πας π.χ. στη σελίδα με το χάρτη ή επιλογές
              },
              child: const Text('Επόμενο'),
            ),
          ],
        ),
      ),
    );
  }
}
