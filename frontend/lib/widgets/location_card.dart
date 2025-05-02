import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../blocs/map_bloc/map_bloc.dart';
import '../models/mapbox_feature.dart';
import '../services/map_service.dart'; // import the new service

/// Card widget to display location info and fetch/display route.
class LocationInfoCard extends StatelessWidget {
  final MapboxFeature? feature;

  const LocationInfoCard({Key? key, required this.feature}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (feature == null) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            feature?.name ?? 'Άγνωστη Τοποθεσία',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            feature?.fullAddress ?? 'Δεν βρέθηκε διεύθυνση',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          if (feature?.poiCategory != null &&
              feature!.poiCategory.isNotEmpty &&
              !(feature!.poiCategory.length == 1 &&
                  feature!.poiCategory.first == 'address'))
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                'Categories: ${feature!.poiCategory.join(', ')}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.hintColor,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Accessibility: ', style: theme.textTheme.bodyMedium),
              Icon(
                feature?.accessibleFriendly ?? false
                    ? Icons.accessible_forward
                    : Icons.not_accessible,
                color: feature?.accessibleFriendly ?? false
                    ? Colors.green.shade700
                    : Colors.red.shade700,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                feature?.accessibleFriendly ?? false
                    ? 'Accessible'
                    : 'Not Accessible',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: feature?.accessibleFriendly ?? false
                      ? Colors.green.shade700
                      : Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Lat: ${feature?.latitude?.toStringAsFixed(5) ?? 'N/A'}   Lon: ${feature?.longitude?.toStringAsFixed(5) ?? 'N/A'}',
            style:
            theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ElevatedButton.icon(
                onPressed: () => _fetchAndDisplayRoute(context),
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('Start'),
                style: ElevatedButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: theme.textTheme.labelMedium,
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => _fetchAndDisplayRoute(context),
                icon: const Icon(Icons.directions, size: 18),
                label: const Text('Directions'),
                style: ElevatedButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: theme.textTheme.labelMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Fetches and displays route using MapService and MapBloc.
  void _fetchAndDisplayRoute(BuildContext context) async {
    if (feature == null) {
      print("Attempted to navigate but feature was null.");
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));

      final mapService = MapService(); // create instance

      final routeJson = await mapService.getFullRouteJson(
        fromLat: position.latitude,
        fromLng: position.longitude,
        toLat: feature!.latitude,
        toLng: feature!.longitude,
      );

      context.read<MapBloc>().add(DisplayRouteFromJson(routeJson));
    } catch (e) {
      print("Navigation error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load directions.')),
      );
    }
  }
}
