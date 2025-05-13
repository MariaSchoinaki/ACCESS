import 'dart:convert';
import 'dart:io';
// Imports for Firebase
import 'package:firebase_admin/firebase_admin.dart';
import 'package:gcloud/storage.dart';
import 'package:http/http.dart' as http;
import '../../../models/disability_type.dart';
import '../../../models/point.dart';
import '../../../models/route_data.dart';
import 'package:firebase_admin/src/app.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';


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
  final _firestore = FirebaseAdmin.instance.app()?.database();

  Future<List?>? fetchAllRoutesWithIds() async {
    print("FirebaseService: Fetching all routes...");

    var querySnapshot = await _firestore?.ref();//?.collection('routes').get();
    print(querySnapshot?.reference());
    print(querySnapshot?.path);

    var l = await querySnapshot?.get().asStream().toList();

    return l;
  }
}

// --- ΚΥΡΙΟΣ ΑΛΓΟΡΙΘΜΟΣ ΕΝΗΜΕΡΩΣΗΣ ---
Future<void> runUpdateAccessibilityAlgorithm() async {

  final firebaseService = FirebaseService();

  const double alpha = 0.4;
  const double initialAccessibilityScore = 0.5;

  print("Έναρξη διαδικασίας ενημέρωσης προσβασιμότητας...");

  List? allRoutesRaw = await firebaseService.fetchAllRoutesWithIds();
  List<Map<String, dynamic>> allUsersRaw = [];//await firebaseService.fetchAllUsersWithIds();

  print(allRoutesRaw.toString());
  if (allRoutesRaw != null) {
    print("Δεν βρέθηκαν διαδρομές για επεξεργασία.");
    return;
  }
  if (allUsersRaw.isEmpty) {
    print("Δεν βρέθηκαν χρήστες για επεξεργασία.");
    return;
  }


  if (allRoutesRaw!=null){
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
/*
        await firebaseService.saveProcessedRouteSegmentsForUser(
            userId: userId,
            routeId: routeId,
            segmentsData: segmentsToStore,
            disabilityTypeUsed: userDisabilityTypeEnum.name,
            alphaUsed: alpha,
            initialScoreUsed: initialAccessibilityScore
        );*/
      } else {
        print("    -> Δεν υπολογίστηκαν τμήματα για Χρήστη $userId, Διαδρομή $routeId.");
      }
    }
  }
  print("\nΗ διαδικασία ενημέρωσης προσβασιμότητας ολοκληρώθηκε.");}
}
///1
String _createJWT(Map<String, dynamic> serviceAccount) {
  final privateKey = serviceAccount['private_key'];
  final clientEmail = serviceAccount['client_email'];
  final now = DateTime.now().toUtc();

  final jwt = JWT(
    {
      'iss': clientEmail,
      'scope': 'https://www.googleapis.com/auth/datastore',
      'aud': 'https://oauth2.googleapis.com/token',
      'iat': now.millisecondsSinceEpoch ~/ 1000,
      'exp': now.add(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
    },
  );

  // Υπογραφή με RS256
  return jwt.sign(
    RSAPrivateKey(privateKey),
    algorithm: JWTAlgorithm.RS256,
  );
}

Future<String> _getAccessToken(String jwt) async {
  final response = await http.post(
    Uri.parse('https://oauth2.googleapis.com/token'),
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: {
      'grant_type': 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      'assertion': jwt,
    },
  );

  if (response.statusCode == 200) {
    print(response.body);
    return jsonDecode(response.body)['access_token'];
  } else {
    throw Exception('Failed to get access token: ${response.body}');
  }
}

Future<void> readRoutes() async {
  final serviceAccount = jsonDecode(File('firebase_conf.json').readAsStringSync());

  final jwt = _createJWT(serviceAccount);
  final accessToken = await _getAccessToken(jwt);

  final url = Uri.parse(
    'https://firestore.googleapis.com/v1/projects/access-b54d6/databases/(default)/documents/rated_routes',
  );

  final response = await http.get(url, headers: {
    'Authorization': 'Bearer $accessToken',
  });

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    print('Routes: $data');
  } else {
    print('Error: ${response.statusCode} - ${response.body}');
  }
}

///2
Future<void> readRoutesAndRunAlgorithm() async {
  final serviceAccount = jsonDecode(File('firebase_conf.json').readAsStringSync());
  final jwt = _createJWT(serviceAccount);
  final accessToken = await _getAccessToken(jwt);

  final url = Uri.parse(
    'https://firestore.googleapis.com/v1/projects/access-id/databases/(default)/documents/rated_routes',
  );

  final response = await http.get(url, headers: {
    'Authorization': 'Bearer $accessToken',
  });

  if (response.statusCode != 200) {
    print('Error: ${response.statusCode} - ${response.body}');
    return;
  }

  final data = jsonDecode(response.body);
  final documents = data['documents'] as List<dynamic>;

  for (var doc in documents) {
    final docFields = doc['fields'] as Map<String, dynamic>;
    final docName = doc['name'];
    final docId = docName.split('/').last;

    if (!docFields.containsKey('routePoints') || !docFields.containsKey('rating')) {
      print("  - Το έγγραφο $docId δεν έχει όλα τα απαιτούμενα πεδία. Παράλειψη.");
      continue;
    }

    final List<Point> routePoints = [];
    final List<dynamic> pointsList = docFields['routePoints']['arrayValue']['values'];

    /**for (var p in pointsList) {
      final fields = p['mapValue']['fields'];
      final lat = fields['latitude']['doubleValue'];
      final lon = double.parse(fields['longitude']['doubleValue'] ?? fields['longitude']['integerValue']);
      final refScore = double.parse(fields['referenceAccessibility']['doubleValue'] ?? '0.5');
      final accuracy = fields['accuracy'] != null ? double.parse(fields['accuracy']['doubleValue']) : null;
      final altitude = fields['altitude'] != null ? double.parse(fields['altitude']['doubleValue']) : null;

      routePoints.add(Point(latitude: lat, longitude: lon, referenceAccessibility: refScore, accuracy: accuracy!, altitude: altitude!, speed: 0.0, timestamp: DateTime.now()));
    }*/
    final List<dynamic> rawList = doc['fields']['routePoints']['arrayValue']['values'];
    final points = rawList.map((e) => Point.fromFirebase(e)).toList();
    print(points);

    final rating = double.parse(docFields['rating']['doubleValue'] ?? '0.0');

    final routeData = RouteData(routePoints: routePoints, rating: rating);

    final calculatedSegments = calculateRouteAccessibility(
      routeWithReferencePoints: routeData.routePoints,
      disabilityType: DisabilityType.mobility, // δοκιμαστικά
      alpha: 0.4,
      initialAccessibilityScore: 0.5,
    );

    print("🔹 Διαδρομή $docId: Υπολογίστηκαν ${calculatedSegments.length} τμήματα");
    for (var seg in calculatedSegments) {
      print("  - Από (${seg.startPoint.latitude}, ${seg.startPoint.longitude})"
          " προς (${seg.endPoint.latitude}, ${seg.endPoint.longitude})"
          " → ${seg.calculatedAccessibilityScore.toStringAsFixed(2)} [${seg.colorHex}]");
    }
  }
}


Future<void> main() async {
  await readRoutesAndRunAlgorithm();
}
