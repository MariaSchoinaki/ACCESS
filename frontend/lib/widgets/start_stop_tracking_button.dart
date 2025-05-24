import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart' as geolocator;
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
      buildWhen:
          (previous, current) =>
              previous.isTracking != current.isTracking ||
              previous.trackingStatus != current.trackingStatus,
      builder: (context, mapState) {

        return FloatingActionButton(
          // Use different heroTags based on state to avoid Flutter errors
          heroTag:
              mapState.isTracking ? "stop_tracking_fab" : "start_tracking_fab",
          mini: true, // Mini size
          tooltip:
              mapState.isTracking
                  ? 'Παύση Καταγραφής'
                  : 'Έναρξη Καταγραφής',
          onPressed: () async {
            // Read the most recent state
            final currentState = context.read<MapBloc>().state;

            if (currentState.trackingStatus == MapTrackingStatus.loading) {
              return; // Exit if it's loading
            }

            if (currentState.isTracking) {
              final routeData = List<geolocator.Position>.from(
                currentState.trackedRoute,
              );

              if (routeData.length < 2) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Η διαδρομή είναι πολύ μικρή για βαθμολόγηση.',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
                context.read<MapBloc>().add(StopTrackingRequested());
                return;
              }

              final double? selectedRating = await showRatingDialog(
                context,
                routeData,
              );

              if (selectedRating != null) {
                context.read<MapBloc>().add(
                  RateAndSaveRouteRequested(
                    rating: selectedRating,
                    route: routeData,
                  ),
                );
              } else {
                context.read<MapBloc>().add(StopTrackingRequested());
              }
            } else {
              context.read<MapBloc>().add(StartTrackingRequested());
            }
          },
          // Change background color based on tracking state
          backgroundColor:
              mapState.isTracking
                  ? Colors
                      .red
                      .shade700 // Red when tracking
                  : Colors.blueAccent.shade200,
          foregroundColor: Colors.white, // Icon color
          // Change the child widget based on tracking status and state
          child:
              mapState.trackingStatus == MapTrackingStatus.loading
                  ? const SizedBox(
                    // Show loading indicator
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                  : Icon(mapState.isTracking ? Icons.stop : Icons.play_arrow),
        );
      },
    );
  }
}
/// --- Dialogue function  ---
Future<double?> showRatingDialog(
  BuildContext context,
  List<geolocator.Position> routeData,
) async {
  return showDialog<double?>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: const Text('Βαθμολόγησε τη Διαδρομή'),
        content: const Text('Πόσο προσβάσιμη ήταν η διαδρομή;'),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: <Widget>[
          _buildRatingButton(
            dialogContext,
            'Πολύ Προσβάσιμη',
            Colors.green,
            1,
          ),
          _buildRatingButton(
            dialogContext,
            'Μέτρια Προσβάσιμη',
            Colors.orange,
            0.5,
          ),
          _buildRatingButton(
            dialogContext,
            'Δύσκολα Προσβάσιμη',
            Colors.red,
            0,
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      );
    },
  );
}

/// Auxiliary widget for scoring buttons
Widget _buildRatingButton(
  BuildContext dialogContext,
  String tooltip,
  Color color,
  double ratingValue,
) {
  return Tooltip(
    message: tooltip,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(15),
      ),
      child: const SizedBox.shrink(),
      onPressed: () {
        Future.delayed(Duration.zero, () {
          if (Navigator.of(dialogContext).canPop()) {
            Navigator.pop(
              dialogContext,
              ratingValue,
            );
          }
        });
      },
    ),
  );
}
