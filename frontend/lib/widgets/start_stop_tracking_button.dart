import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/map_bloc/map_bloc.dart';

/// A Floating Action Button (FAB) widget that allows the user
/// to start or stop location tracking
/// by interacting with the [MapBloc].
///
/// This button dynamically changes its icon (Play/Stop) and background color
/// based on the current tracking state ([MapState.isTracking]). It also
/// displays a loading indicator when the status is [MapTrackingStatus.loading].
class StartStopTrackingButton extends StatelessWidget {
  /// Creates a const [StartStopTrackingButton].
  const StartStopTrackingButton({super.key});

  @override
  /// Builds the Floating Action Button based on the current [MapState].
  ///
  /// Uses a [BlocBuilder] to listen to [MapBloc] state changes and update
  /// the FAB's appearance (icon, color, tooltip) and `onPressed` behavior
  /// accordingly.
  Widget build(BuildContext context) {
    return BlocBuilder<MapBloc, MapState>(
      // buildWhen optimizes rebuilding only when tracking status/state changes
      buildWhen: (previous, current) =>
      previous.isTracking != current.isTracking ||
          previous.trackingStatus != current.trackingStatus,
      builder: (context, mapState) {
        final theme = Theme.of(context);

        return FloatingActionButton(
          // Use different heroTags based on state to avoid Flutter errors
          heroTag: mapState.isTracking ? "stop_tracking_fab" : "start_tracking_fab",
          mini: true, // Mini size
          tooltip: mapState.isTracking ? 'Παύση Καταγραφής' : 'Έναρξη Καταγραφής', // Tooltip
          onPressed: () {
            // Do nothing if the tracking status is currently loading
            if (mapState.trackingStatus == MapTrackingStatus.loading) return;

            // Dispatch the appropriate event to MapBloc based on current state
            if (mapState.isTracking) {
              // If already tracking, send request to Stop.
              context.read<MapBloc>().add(StopTrackingRequested());
            } else {
              // Otherwise, send request to Start.
              context.read<MapBloc>().add(StartTrackingRequested());
            }
          },
          // Change background color based on tracking state
          backgroundColor: mapState.isTracking
              ? Colors.red.shade700 // Red when tracking
              : Colors.blueAccent.shade200, // Το δευτερεύον χρώμα σου αλλιώς
          foregroundColor: Colors.white, // Icon color
          // Change the child widget based on tracking status and state
          child: mapState.trackingStatus == MapTrackingStatus.loading
              ? const SizedBox( // Show loading indicator
            width: 20, height: 20,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          )
              : Icon(mapState.isTracking
              ? Icons.stop
              : Icons.play_arrow
          ),
        );
      },
    );
  }
}