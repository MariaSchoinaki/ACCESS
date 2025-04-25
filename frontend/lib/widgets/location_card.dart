// location_info_card.dart
import 'package:flutter/material.dart';

class LocationInfoCard extends StatelessWidget {
  final String addressName;
  final String location;

  const LocationInfoCard({
    Key? key,
    required this.addressName,
    required this.location,
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
            addressName,
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            'Lat: ${location.split(',')[0]}   Lon: ${location.split(',')[1]}',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.play_arrow),
                label: const Text('Έναρξη'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
