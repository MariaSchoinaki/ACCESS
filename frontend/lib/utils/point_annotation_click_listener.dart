// Custom listener class
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class PointAnnotationClickListener extends OnPointAnnotationClickListener {
  PointAnnotationClickListener({
    required this.onAnnotationClick,
  });

  final void Function(PointAnnotation annotation) onAnnotationClick;

  @override
  void onPointAnnotationClick(PointAnnotation annotation) {
    print("Point annotation clicked, id: ${annotation.id}");
    onAnnotationClick(annotation);
  }
}
