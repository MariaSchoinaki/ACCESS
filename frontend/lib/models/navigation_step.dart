import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class NavigationStep {
  final String instruction;
  final double? distance; // σε μέτρα
  final double? duration; // σε δευτερόλεπτα
  final Point location;

  NavigationStep({
    required this.instruction,
    required this.location,
    this.distance,
    this.duration,
  });

  factory NavigationStep.fromJson(Map<String, dynamic> json) {
    return NavigationStep(
      instruction: json['instruction'] ?? '',
      distance: (json['distance'] as num?)?.toDouble(),
      duration: (json['duration'] as num?)?.toDouble(),
      location: Point(coordinates: Position(
          (json['location']['lng'] as num).toDouble(),
          (json['location']['lat'] as num).toDouble(),
        )
      ),
    );
  }
}
