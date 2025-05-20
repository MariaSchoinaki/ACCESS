import 'point.dart';

class RouteSegment {
  final Point startPoint;
  final Point endPoint;
  final double calculatedAccessibilityScore;
  final String colorHex;

  const RouteSegment({
    required this.startPoint,
    required this.endPoint,
    required this.calculatedAccessibilityScore,
    required this.colorHex,
  });

  /// For saving to Firestore / API
  Map<String, dynamic> toMap() => {
    'startPoint': startPoint.toMap(),
    'endPoint'  : endPoint.toMap(),
    'calculatedAccessibilityScore': calculatedAccessibilityScore,
    'colorHex'  : colorHex,
  };

  /// Compatible with toJson() calls
  Map<String, dynamic> toJson() => toMap();
}
