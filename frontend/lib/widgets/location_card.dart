import 'package:flutter/material.dart';
import '../models/mapbox_feature.dart';

class LocationInfoCard extends StatelessWidget {
  final MapboxFeature? feature; // Μπορεί να είναι null

  const LocationInfoCard({
    Key? key,
    required this.feature, // Προσοχή: Το 'required' με nullable τιμή
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Περίπτωση 1: Αν το feature είναι null, μην εμφανίσεις τίποτα
    if (feature == null) {
      return const SizedBox.shrink(); // ή Container()
    }

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
          // Περίπτωση 2: Χρήση null-safe operator (?.)
          Text(
            feature?.name ?? 'Άγνωστη τοποθεσία', // Προεπιλογή αν είναι null
            style: theme.textTheme.titleLarge,
          ),
          Text(
            feature?.fullAddress ?? 'Δεν υπάρχει διεύθυνση',
            style: theme.textTheme.titleSmall,
          ),
          // Περίπτωση 3: Έλεγχος για null πριν την πρόσβαση σε λίστα
          if (feature?.poiCategory?.contains('address') == false)
            Text(
              feature!.poiCategory.join(', '), // Εδώ είμαστε σίγουροι ότι δεν είναι null
              style: theme.textTheme.titleSmall,
            ),
          // Απλοποιημένο κενό Widget
          const SizedBox(),
          Row(
            children: [
              const Text('Προσβασιμότητα: '),
              Icon(
                feature?.accessibleFriendly ?? false // Προεπιλογή false
                    ? Icons.accessible
                    : Icons.not_accessible,
                color: feature?.accessibleFriendly ?? false
                    ? Colors.green
                    : Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Lat: ${feature?.latitude ?? 'N/A'}   Lon: ${feature?.longitude ?? 'N/A'}',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ElevatedButton.icon(
                onPressed: () => _navigateToDirections(context),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Έναρξη'),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () => _navigateToDirections(context),
                icon: const Icon(Icons.directions),
                label: const Text('Οδηγίες'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToDirections(BuildContext context) {
    if (feature == null) return;
    // TODO: Χρήση feature!.latitude και feature!.longitude εδώ
  }
}