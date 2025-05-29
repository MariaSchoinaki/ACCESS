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
    final currentStep = mapState.currentStepIndex;
    final steps = mapState.routeSteps;
    final totals = _getRemainingDurationAndDistance(mapState.routeSteps, currentStep);
    final total_duration = totals['durationMinutes'];
    final total_distance = totals['distanceMeters'];

    return Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 48),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '${total_duration?.round()} min',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${total_distance?.round()} m',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Άφιξη: ${_calculateArrivalTime(total_duration)}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    context.read<MapBloc>().add(StopNavigationRequested());
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Steps
            const Text(
              'Οδηγίες:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 450,  // Δώσε ύψος που να ταιριάζει στο design σου
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: steps.length,
                itemBuilder: (context, index) {
                  final step = steps[index];
                  final instruction = step.instruction ?? 'Χωρίς οδηγία';

                  return ListTile(
                    leading: Text('•',
                        style: TextStyle(
                            fontSize: 20,
                            color: index == currentStep
                                ? Colors.blue
                                : theme.textTheme.bodyMedium?.color)),
                    title: Text(
                      instruction,
                      style: TextStyle(
                        fontWeight: index == currentStep
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: index == currentStep
                            ? Colors.blue
                            : theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
    );
  }

  String _calculateArrivalTime(double? durationSeconds) {
    if (durationSeconds == null) return 'Άγνωστη ώρα';
    final now = DateTime.now();
    final durationMinutes = durationSeconds / 60;
    final arrival = now.add(Duration(minutes: durationMinutes.round()));
    final formatted = '${arrival.hour.toString().padLeft(2, '0')}:${arrival.minute.toString().padLeft(2, '0')}';
    return formatted;
  }

  Map<String, double> _getRemainingDurationAndDistance(List steps, int currentIndex) {
    double remainingDuration = 0;
    double remainingDistance = 0;

    for (int i = currentIndex; i < steps.length; i++) {
      remainingDuration += steps[i].duration ?? 0;
      remainingDistance += steps[i].distance ?? 0;
    }

    final remainingMinutes = remainingDuration / 60;

    return {
      'durationMinutes': remainingMinutes,
      'distanceMeters': remainingDistance,
    };
  }

}
