class Report {
  final String id;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final String obstacleType;
  final String locationDescription;
  final String imageUrl;
  final String accessibility;

  Report({
    required this.id,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.obstacleType,
    required this.locationDescription,
    required this.imageUrl,
    required this.accessibility,
  });

  factory Report.fromFirestore(Map<String, dynamic> doc) {
    final fields = doc['fields'] as Map<String, dynamic>? ?? {};
    final geo = fields['coordinates']?['geoPointValue'] ?? {};

    return Report(
      id: doc['name'] ?? '',
      timestamp: DateTime.tryParse(
        fields['timestamp']?['timestampValue'] ?? '',
      ) ??
          DateTime.now(),
      latitude: geo['latitude'] ?? 0.0,
      longitude: geo['longitude'] ?? 0.0,
      obstacleType: fields['obstacleType']?['stringValue'] ?? 'Άγνωστο',
      locationDescription: fields['locationDescription']?['stringValue'] ?? '',
      imageUrl: fields['imageUrl']?['stringValue'] ?? '',
      accessibility: fields['accessibility']?['stringValue'] ?? 'Άγνωστο',
    );
  }

  @override
  String toString() {
    return 'Report(id: $id, timestamp: $timestamp, location: ($latitude, $longitude), '
        'type: $obstacleType, description: $locationDescription, accessibility: $accessibility)';
  }
}
