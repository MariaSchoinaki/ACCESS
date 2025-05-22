import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/map_bloc/map_bloc.dart';

class NavigationInfoBar extends StatelessWidget {
  final String title;

  const NavigationInfoBar({
    required this.title,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mapState = context.watch<MapBloc>().state;
    final duration = mapState.routeSteps[mapState.currentStepIndex].duration;
    final distance = mapState.routeSteps[mapState.currentStepIndex].distance;

    return Positioned(
      left: 0,
      right: 0,
      bottom: -10,
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),

            // Duration, Distance, Arrival Time
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${duration?.round()} min',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${distance?.round()} m' ,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Άφιξη: ${_calculateArrivalTime(duration)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                context.read<MapBloc>().add(StopNavigationRequested());
              },
            ),
          ],
        ),
      ),
    );
  }

  String _calculateArrivalTime(double? durationMinutes) {
    final now = DateTime.now();
    final arrival = now.add(Duration(minutes: durationMinutes!.round()));
    final formatted = '${arrival.hour.toString().padLeft(2, '0')}:${arrival.minute.toString().padLeft(2, '0')}';
    return formatted;
  }
}
