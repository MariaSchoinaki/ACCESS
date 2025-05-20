import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

import '../blocs/map_bloc/map_bloc.dart';

Future<List<mapbox.QueriedRenderedFeature>> queryNearbyFeatures(mapbox.ScreenCoordinate center, int tolerance, BuildContext context) async {
  final results = <mapbox.QueriedRenderedFeature>[];
  final mapController = context.read<MapBloc>().state.mapController;
  for (int dx = -tolerance; dx <= tolerance; dx++) {
    for (int dy = -tolerance; dy <= tolerance; dy++) {
      final point = mapbox.ScreenCoordinate(
        x: center.x + dx,
        y: center.y + dy,
      );

      final features = await mapController?.queryRenderedFeatures(
        mapbox.RenderedQueryGeometry.fromScreenCoordinate(point),
        mapbox.RenderedQueryOptions(
          layerIds: ['poi-label', 'place-label', 'your-custom-layer'],
        ),
      );

      if (features != null) {
        results.addAll(features.where((f) => f != null).cast<mapbox.QueriedRenderedFeature>());
      }
    }
  }

  final seenNames = <String>{};
  final uniqueResults = <mapbox.QueriedRenderedFeature>[];

  for (final feature in results) {
    // Ανάλογα με το API, βρες που είναι το properties και το name
    final prop = feature.queriedFeature.feature['properties'];
    final props = Map<String, dynamic>.from(prop as Map);
    final name = props['name'];
    if (name != null && !seenNames.contains(name)) {
      seenNames.add(name);
      uniqueResults.add(feature);
    }
  }

  return uniqueResults;
}