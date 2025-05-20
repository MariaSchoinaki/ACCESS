/// Represents a GPS point, optionally with accuracy, altitude, speed, timestamp and rating.
class Point {
  final double latitude;
  final double longitude;
  final double? accuracy;   // Optional accuracy in meters
  final double? altitude;   // Optional altitude in meters
  final double? speed;      // Optional speed in m/s
  final DateTime timestamp; // UTC time
  final double? rating;     // Accessibility/user rating (0.0–1.0, optional)

  /// Standard constructor
  Point({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    required this.timestamp,
    this.rating,
  });

  /// Factory for Firestore/JSON
  factory Point.fromFs(
      Map<String, dynamic> json, {
        required double defaultRefAcc,
      }) {
    final f = json['mapValue']?['fields'] ?? json['fields'] ?? {};

    double _num(Map<String, dynamic>? n, [double def = 0.0]) {
      final v = n?['doubleValue'] ?? n?['integerValue'];
      if (v == null) return def;
      return v is num ? v.toDouble() : double.tryParse('$v') ?? def;
    }

    DateTime _parseTimestamp(dynamic raw) {
      if (raw == null) return DateTime.now().toUtc();
      if (raw is Map && raw.containsKey('integerValue')) {
        final ms = int.tryParse('${raw['integerValue']}');
        if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
      }
      if (raw is Map && raw.containsKey('timestampValue')) {
        return DateTime.parse(raw['timestampValue']).toUtc();
      }
      if (raw is String) {
        return DateTime.tryParse(raw)?.toUtc() ??
            DateTime.fromMillisecondsSinceEpoch(int.tryParse(raw) ?? 0, isUtc: true);
      }
      return DateTime.now().toUtc();
    }

    double? _optNum(Map<String, dynamic>? n) {
      if (n == null) return null;
      final v = n['doubleValue'] ?? n['integerValue'];
      if (v == null) return null;
      return v is num ? v.toDouble() : double.tryParse('$v');
    }

    return Point(
      latitude: _num(f['latitude']),
      longitude: _num(f['longitude']),
      accuracy: f.containsKey('accuracy') ? _num(f['accuracy']) : null,
      altitude: f.containsKey('altitude') ? _num(f['altitude']) : null,
      speed: f.containsKey('speed') ? _num(f['speed']) : null,
      timestamp: _parseTimestamp(f['timestamp']),
      rating: f.containsKey('rating') ? _optNum(f['rating']) : null,
    );
  }

  /// Serializes this point to a simple map (API/Firestore).
  Map<String, dynamic> toMap() => {
    'latitude': latitude,
    'longitude': longitude,
    if (accuracy != null) 'accuracy': accuracy,
    if (altitude != null) 'altitude': altitude,
    if (speed != null) 'speed': speed,
    if (rating != null) 'rating': rating,
    'timestamp': timestamp.millisecondsSinceEpoch,
  };

  Map<String, dynamic> toJson() => toMap();
}
