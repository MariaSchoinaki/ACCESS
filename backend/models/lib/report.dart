class Report {
  final String id;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final String obstacleType;
  final String locationDescription;
  final String imageUrl;
  final String accessibility;
  final String description;

  Report({
    required this.id,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.obstacleType,
    required this.locationDescription,
    required this.imageUrl,
    required this.accessibility,
    required this.description,
  });

  factory Report.fromFirestore(Map<String, dynamic> doc) {
    final fields = doc['fields'] as Map<String, dynamic>? ?? {};
    final geo = fields['coordinates']?['geoPointValue'] ?? {};

    // Extract the ID from the Firestore document name if necessary
    final fullName = doc['name'] as String? ?? '';
    final id = fullName.isNotEmpty ? fullName.split('/').last : '';

    // Safely parse latitude and longitude to double
    double parseDouble(dynamic v) {
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    return Report(
      id: id,
      timestamp: DateTime.tryParse(fields['timestamp']?['timestampValue'] ?? '') ?? DateTime.now(),
      latitude: parseDouble(geo['latitude']),
      longitude: parseDouble(geo['longitude']),
      obstacleType: fields['obstacleType']?['stringValue'] ?? 'Unknown',
      locationDescription: fields['locationDescription']?['stringValue'] ?? '',
      imageUrl: fields['imageUrl']?['stringValue'] ?? '',
      accessibility: fields['accessibility']?['stringValue'] ?? 'Unknown',
      description: fields['description']?['stringValue'] ?? '',
    );
  }

  @override
  String toString() {
    return 'Report(id: $id, timestamp: $timestamp, location: ($latitude, $longitude), '
        'type: $obstacleType, locationDescription: $locationDescription, '
        'accessibility: $accessibility, description: $description)';
  }
}