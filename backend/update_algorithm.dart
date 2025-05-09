import 'dart:convert'; // Δεν το χρειαζόμαστε άμεσα πλέον για Firebase, αλλά καλό είναι να υπάρχει για γενική χρήση JSON.
import 'dart:ui';
// Imports για Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'models/disability_type.dart';
import 'models/point.dart';
import 'models/route_data.dart';



/// update algorithm
List<RouteSegment> calculateRouteAccessibility({
  required List<Point> routeWithReferencePoints,
  required DisabilityType disabilityType,
  required double alpha,
  required double initialAccessibilityScore,
}) {
  if (routeWithReferencePoints.length < 2) return [];
  final List<RouteSegment> segments = [];
  double currentAccessibility = initialAccessibilityScore;
  final double userDisabilityWeight = getDisabilityWeight(disabilityType);
  for (int i = 0; i < routeWithReferencePoints.length - 1; i++) {
    final Point start = routeWithReferencePoints[i];
    final Point end = routeWithReferencePoints[i + 1];
    final double referenceScoreForSegment = end.referenceAccessibility;
    currentAccessibility = currentAccessibility +
        alpha * userDisabilityWeight * (referenceScoreForSegment - currentAccessibility);
    currentAccessibility = currentAccessibility.clamp(0.0, 1.0);
    final String segmentColorHex = determineColorAsHexString(currentAccessibility);
    segments.add(RouteSegment(
      startPoint: start,
      endPoint: end,
      calculatedAccessibilityScore: currentAccessibility,
      colorHex: segmentColorHex,
    ));
  }
  return segments;
}

// --- ΠΡΑΓΜΑΤΙΚΗ ΥΠΗΡΕΣΙΑ FIREBASE ---
class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> fetchAllRoutesWithIds() async {
    print("FirebaseService: Fetching all routes...");
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('routes').get();
      print("FirebaseService: Fetched ${querySnapshot.docs.length} routes.");
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        return {"id": doc.id, "data": data ?? {}}; // Επιστροφή κενού map αν τα data είναι null
      }).toList();
    } catch (e) {
      print("FirebaseService: Error fetching routes: $e");
      return []; // Επιστροφή κενής λίστας σε περίπτωση σφάλματος
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllUsersWithIds() async {
    print("FirebaseService: Fetching all users...");
    try {
      QuerySnapshot querySnapshot = await _firestore.collection('users').get();
      print("FirebaseService: Fetched ${querySnapshot.docs.length} users.");
      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        return {"id": doc.id, "data": data ?? {}};
      }).toList();
    } catch (e) {
      print("FirebaseService: Error fetching users: $e");
      return [];
    }
  }

  Future<void> saveProcessedRouteSegmentsForUser({
    required String userId,
    required String routeId,
    required List<Map<String, dynamic>> segmentsData,
    required String disabilityTypeUsed,
    required double alphaUsed,
    required double initialScoreUsed,
  }) async {
    print("FirebaseService: Saving processed segments for User: $userId, Route: $routeId");
    try {
      // Χρησιμοποιούμε συνδυασμό userId και routeId για μοναδικό ID εγγράφου,
      // ή αφήνουμε το Firestore να δημιουργήσει αυτόματα ID και αποθηκεύουμε τα userId, routeId ως πεδία.
      // Για απλότητα, ας υποθέσουμε ότι θέλουμε ένα έγγραφο ανά (user, route) συνδυασμό.
      // Αν ένα τέτοιο έγγραφο μπορεί να υπάρχει ήδη, χρησιμοποιούμε .set() με MergeOptions αν χρειάζεται,
      // ή .update() αν είμαστε σίγουροι ότι υπάρχει.
      // Εδώ, θα δημιουργήσουμε/αντικαταστήσουμε.
      String docId = "${userId}_${routeId}";

      await _firestore.collection('userProcessedRoutes').doc(docId).set({
        'userId': userId,
        'routeId': routeId,
        'disabilityTypeAtCalculation': disabilityTypeUsed,
        'alphaAtCalculation': alphaUsed,
        'initialScoreAtCalculation': initialScoreUsed,
        'processedAt': FieldValue.serverTimestamp(), // Χρησιμοποιεί την ώρα του server Firebase
        'segments': segmentsData,
      });
      print("  -> Saved ${segmentsData.length} segments to 'userProcessedRoutes/$docId'.");
    } catch (e) {
      print("FirebaseService: Error saving processed segments for User $userId, Route $routeId: $e");
    }
  }
}

// --- ΚΥΡΙΟΣ ΑΛΓΟΡΙΘΜΟΣ ΕΝΗΜΕΡΩΣΗΣ ---
Future<void> runUpdateAccessibilityAlgorithm() async {

  final firebaseService = FirebaseService();

  const double alpha = 0.4;
  const double initialAccessibilityScore = 0.5;

  print("Έναρξη διαδικασίας ενημέρωσης προσβασιμότητας...");

  List<Map<String, dynamic>> allRoutesRaw = await firebaseService.fetchAllRoutesWithIds();
  List<Map<String, dynamic>> allUsersRaw = await firebaseService.fetchAllUsersWithIds();

  if (allRoutesRaw.isEmpty) {
    print("Δεν βρέθηκαν διαδρομές για επεξεργασία.");
    return;
  }
  if (allUsersRaw.isEmpty) {
    print("Δεν βρέθηκαν χρήστες για επεξεργασία.");
    return;
  }

  for (var routeRaw in allRoutesRaw) {
    String routeId = routeRaw['id'] as String;
    Map<String, dynamic> routeJsonData = routeRaw['data'] as Map<String, dynamic>;

    if (routeJsonData.isEmpty) {
      print("Η διαδρομή $routeId έχει κενά δεδομένα. Παράλειψη.");
      continue;
    }

    RouteData routeData = RouteData.fromJson(routeJsonData);

    if (routeData.routePoints.length < 2) {
      print("Η διαδρομή $routeId έχει λιγότερα από 2 σημεία. Παράλειψη.");
      continue;
    }
    print("\nΕπεξεργασία Διαδρομής ID: $routeId (Rating Διαδρομής: ${routeData.rating})");

    for (var userRaw in allUsersRaw) {
      String userId = userRaw['id'] as String;
      Map<String, dynamic> userJsonData = userRaw['data'] as Map<String, dynamic>;
      String? userDisabilityTypeString = userJsonData['disabilityType'] as String?;

      DisabilityType userDisabilityTypeEnum = DisabilityType.unknown;
      if (userDisabilityTypeString != null && userDisabilityTypeString.isNotEmpty) {
        try {
          userDisabilityTypeEnum = DisabilityType.values.firstWhere(
                (e) => e.name.toLowerCase() == userDisabilityTypeString.toLowerCase(),
          );
        } catch (e) {
          print("  - Χρήστης $userId: Άγνωστος τύπος αναπηρίας '$userDisabilityTypeString'. Χρησιμοποιείται ο τύπος '${DisabilityType.unknown.name}'.");
        }
      } else {
        print("  - Χρήστης $userId: Δεν έχει οριστεί τύπος αναπηρίας. Χρησιμοποιείται ο τύπος '${DisabilityType.unknown.name}'.");
      }

      print("  - Για Χρήστη ID: $userId (Τύπος Αναπηρίας: ${userDisabilityTypeEnum.name})");

      List<RouteSegment> calculatedSegments = calculateRouteAccessibility(
        routeWithReferencePoints: routeData.routePoints,
        disabilityType: userDisabilityTypeEnum,
        alpha: alpha,
        initialAccessibilityScore: initialAccessibilityScore,
      );

      if (calculatedSegments.isNotEmpty) {
        List<Map<String, dynamic>> segmentsToStore = calculatedSegments.map((seg) {
          return {
            "startPoint": {"latitude": seg.startPoint.latitude, "longitude": seg.startPoint.longitude},
            "endPoint": {"latitude": seg.endPoint.latitude, "longitude": seg.endPoint.longitude},
            "calculatedAccessibilityScore": seg.calculatedAccessibilityScore,
            "colorHex": seg.colorHex,
          };
        }).toList();

        await firebaseService.saveProcessedRouteSegmentsForUser(
            userId: userId,
            routeId: routeId,
            segmentsData: segmentsToStore,
            disabilityTypeUsed: userDisabilityTypeEnum.name,
            alphaUsed: alpha,
            initialScoreUsed: initialAccessibilityScore
        );
      } else {
        print("    -> Δεν υπολογίστηκαν τμήματα για Χρήστη $userId, Διαδρομή $routeId.");
      }
    }
  }
  print("\nΗ διαδικασία ενημέρωσης προσβασιμότητας ολοκληρώθηκε.");
}
