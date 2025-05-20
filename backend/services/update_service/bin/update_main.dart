import 'dart:async';
import 'dart:io';
import 'package:access_models/firebase/rest.dart';

import '../lib/update_service.dart';

void main() async {
  const saPath = 'firebase_conf.json';
  if (!File(saPath).existsSync()) {
    stderr.writeln('❌ Cannot find service-account JSON at "$saPath"');
    exit(1);
  }

  print('>>> [MAIN] Loading Firestore credentials...');
  final rest = FirestoreRest.fromServiceAccount(saPath);

  print('>>> [MAIN] Creating updater...');
  final updater = AccessibilityUpdaterService(rest);

  // Run the updater immediately for the first time
  print('>>> [MAIN] Running updater...');
  await runUpdate(updater);

  // Then run periodically every 1 minute
  Timer.periodic(Duration(minutes: 1), (timer) async {
    print('\n>>> [TIMER] Running updater...');
    await runUpdate(updater);
  });

  // Keep main alive forever (or as long as you want)
  await Future.delayed(Duration(days: 365));
}

Future<void> runUpdate(AccessibilityUpdaterService updater) async {
  try {
    await updater.run(alpha: 0.5); // Change alpha if you want
    print('✅ Accessibility update completed.');
  } catch (e, st) {
    print('❌ Error during update: $e\n$st');
  }
}