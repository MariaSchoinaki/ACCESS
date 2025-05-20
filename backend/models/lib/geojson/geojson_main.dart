import 'geojson_loader.dart';
import 'nearest_segment.dart';

void main() async {
  // Load your geojson file (adjust the path!)
  final geojson = await loadGeoJson('../../../data/roads.geojson');

  // Example
  final List<List<double>> userRoute = [
    [23.7237, 37.9766],  // [lng, lat]
    [23.7239, 37.97653],
    [23.7241, 37.97669],
  ];

  final segments = matchRouteToSegments(userRoute, geojson);
  print('User route segments: $segments');
}
