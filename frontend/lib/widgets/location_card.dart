import 'package:access/models/metadata.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/map_bloc/map_bloc.dart';
import '../models/mapbox_feature.dart';
import '../utils/metadata_utils.dart';

/// Card widget to display location info and fetch/display route(s).
class LocationInfoCard extends StatelessWidget {
  final MapboxFeature? feature;
  final MapboxFeature? feature2;

  const LocationInfoCard({super.key, required this.feature, this.feature2});

  @override
  Widget build(BuildContext context) {
    if (feature == null) return const SizedBox.shrink();
    ParsedMetadata? metadata;
    if (feature2 != null) {
      metadata = createMetaData(feature2!.metadata);
    }
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
            'Lat: ${feature?.latitude.toStringAsFixed(5) ?? 'N/A'}   Lon: ${feature?.longitude.toStringAsFixed(5) ?? 'N/A'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<MapBloc>().add(StartNavigationRequested(feature!, false));
                  },
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Έναρξη'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: theme.textTheme.labelMedium,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => context.read<MapBloc>().add(DisplayAlternativeRoutes(feature!)),
                  icon: const Icon(Icons.directions, size: 18),
                  label: const Text('Οδηγίες'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: theme.textTheme.labelMedium,
                  ),
                ),
                const SizedBox(width: 10),
                if (feature2 != null)
                  if(metadata?.phone != null)
                    ElevatedButton.icon(
                      onPressed: () => context.read<MapBloc>().add(LaunchPhoneDialerRequested(metadata?.phone)),
                      icon: const Icon(Icons.call, size: 18),
                      label: const Text('Κλήση'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: theme.textTheme.labelMedium,
                      ),
                    ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => context.read<MapBloc>().add(ShareLocationRequested(feature!.id)),
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Μοίρασε'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: theme.textTheme.labelMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (feature2 != null)
            buildMetadataFromList(feature2?.metadata),
        ],
      ),
    );
  }

}
