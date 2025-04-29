import 'package:cloud_firestore/cloud_firestore.dart';

class Report {
  final String id;
  final String userId;
  final String? userEmail;
  final String locationDescription;
  final GeoPoint coordinates;
  final String obstacleType;
  final String accessibility;
  final String? description;
  final String? imageUrl;
  final Timestamp timestamp;
  final bool isApproved;
  final Timestamp? approvedTimestamp;

  Report({
    required this.id,
    required this.userId,
    this.userEmail,
    required this.locationDescription,
    required this.coordinates,
    required this.obstacleType,
    required this.accessibility,
    this.description,
    this.imageUrl,
    required this.timestamp,
    required this.isApproved,
    this.approvedTimestamp,
  });

  // Factory constructor για δημιουργία από Firestore DocumentSnapshot
  factory Report.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw StateError('Missing data for Report ${doc.id}');
    }

    return Report(
      id: doc.id,
      userId: data['userId'] ?? 'unknown_user',
      userEmail: data['userEmail'] as String?,
      locationDescription: data['locationDescription'] ?? 'Άγνωστη τοποθεσία',
      // Χειρισμός GeoPoint με ασφάλεια
      coordinates: data['coordinates'] is GeoPoint
          ? data['coordinates'] as GeoPoint
          : const GeoPoint(0, 0), // Προεπιλογή αν λείπει/λάθος τύπος
      obstacleType: data['obstacleType'] ?? 'Άγνωστος τύπος',
      accessibility: data['accessibility'] ?? 'Άγνωστη προσβασιμότητα',
      description: data['description'] as String?,
      imageUrl: data['imageUrl'] as String?,
      // Χειρισμός Timestamp με ασφάλεια
      timestamp: data['timestamp'] is Timestamp
          ? data['timestamp'] as Timestamp
          : Timestamp.now(), // Προεπιλογή αν λείπει/λάθος τύπος
      isApproved: data['isApproved'] ?? false, // Προεπιλογή σε false
      approvedTimestamp: data['approvedTimestamp'] as Timestamp?,
    );
  }

  // Βοηθητική μέθοδος για εμφάνιση ημερομηνίας
  String get formattedTimestamp {
    return timestamp.toDate().toLocal().toString().substring(0, 16); // π.χ. 2025-04-29 12:30
  }

  String get formattedApprovalTimestamp {
    if (approvedTimestamp == null) return '-';
    return approvedTimestamp!.toDate().toLocal().toString().substring(0, 16);
  }
}