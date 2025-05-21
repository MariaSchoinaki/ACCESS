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

  // Run immediately on start
  print('>>> [MAIN] Running both ratings and reports updaters (only needsUpdate == true)...');
  await runBothUpdates(updater);

  // Then run periodically every 1 minute
  Timer.periodic(Duration(minutes: 1), (timer) async {
    print('\n>>> [TIMER] Running both ratings and reports updaters (only needsUpdate == true)...');
    await runBothUpdates(updater);
  });

  // Keep main alive forever
  await Future.delayed(Duration(days: 365));
}

Future<void> runBothUpdates(AccessibilityUpdaterService updater) async {
  try {
    // Only process rated_routes and reports with needsUpdate == true
    await updater.runRatings(alpha: 0.5); // Update from user ratings (routes)
    await updater.runReports(alpha: 0.9); // Update from obstacle reports
    print('✅ Both ratings and reports accessibility updates completed.');
  } catch (e, st) {
    print('❌ Error during updates: $e\n$st');
  }
}