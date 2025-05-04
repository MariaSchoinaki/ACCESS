import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import '../blocs/map_bloc/map_bloc.dart';
import '../models/mapbox_feature.dart';
import '../services/map_service.dart';

/// Card widget to display location info and fetch/display route(s).
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
                'Κατηγορίες: ${feature!.poiCategory.join(', ')}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: theme.hintColor,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text('Προσβασιμότητα: ', style: theme.textTheme.bodyMedium),
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
                    ? 'Προσβάσιμο'
                    : 'Μη Προσβάσιμο',
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
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ElevatedButton.icon(
                onPressed: () =>
                    _fetchAndDisplayRoute(context, alternatives: false),
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('Έναρξη'),
                style: ElevatedButton.styleFrom(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: theme.textTheme.labelMedium,
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () =>
                    _fetchAndDisplayRoute(context, alternatives: true),
                icon: const Icon(Icons.directions, size: 18),
                label: const Text('Οδηγίες'),
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

  /// Fetches and displays route(s) using MapService and dispatches events to MapBloc.
  void _fetchAndDisplayRoute(BuildContext context,
      {required bool alternatives}) async {
    if (feature == null) {
      print("Attempted to navigate but feature was null.");
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));

      final mapService = MapService();

      // Call the API with `alternatives` query param
      final responseJson = await mapService.getRoutesJson(
        fromLat: position.latitude,
        fromLng: position.longitude,
        toLat: feature!.latitude,
        toLng: feature!.longitude,
        alternatives: alternatives,
      );

      if (alternatives) {
        // Extract all routes
        final List<List<List<double>>> alternativeRoutes = [];

        final routes = responseJson['routes'] as List<dynamic>?;


        if (routes != null) {
          for (var route in routes) {
            if (route is List) {
              alternativeRoutes.add(List<List<double>>.from(
                  route.map((c) => [c[0].toDouble(), c[1].toDouble()])));
            }
          }
        }

        if (alternativeRoutes.isNotEmpty) {
          context
              .read<MapBloc>()
              .add(DisplayAlternativeRoutesFromJson(alternativeRoutes));
        } else {
          print('No alternative routes found.');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Δεν βρέθηκαν διαδρομές.')),
          );
        }
      } else {
        // Send only the first route as JSON
        context.read<MapBloc>().add(DisplayRouteFromJson(responseJson));
      }
    } catch (e) {
      print("Navigation error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Δεν φορτώθηκαν οι οδηγίες. Ξαναπροσπάθησε αργότερα!')),
      );
    }
  }
}
