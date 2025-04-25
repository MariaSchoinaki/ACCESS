import 'package:flutter/material.dart';

import '../models/mapbox_feature.dart';

class LocationInfoCard extends StatelessWidget {
  final MapboxFeature? feature;

  const LocationInfoCard({
    Key? key,
    required this.feature,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            feature!.name,
            style: theme.textTheme.titleLarge,
          ),
          Text(
            feature!.fullAddress,
            style: theme.textTheme.titleSmall,
          ),
          if (feature!.poiCategory.contains('address') == false)
            Text(
              feature!.poiCategory.join(', '),
              style: theme.textTheme.titleSmall,
            ),
          if (feature!.poiCategory.contains('address') == true)
            SizedBox(),
          Row(
            children: [
              Text('Προσβασιμότητα: '),
              Icon(
                feature!.accessibleFriendly ? Icons.accessible : Icons.not_accessible,
                color: feature!.accessibleFriendly ? Colors.green : Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Lat: ${feature?.latitude}   Lon: ${feature?.longitude}',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  ///TODO: navigate to mapbox directions
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Έναρξη'),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () {
                  ///TODO: navigate to mapbox directions
                },
                icon: const Icon(Icons.directions),
                label: const Text('Οδηγίες'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
