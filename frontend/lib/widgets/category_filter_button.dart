import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import '../blocs/map_bloc/map_bloc.dart';
import '../blocs/search_bloc/search_bloc.dart';


/// A reusable button widget for category filtering in the search bar.
///
/// Displays a label and dispatches a [FilterByCategoryPressed] event
/// with the associated [categoryKey] when pressed.
class CategoryFilterButton extends StatelessWidget {
  /// The text label displayed on the button.
  final String label;
  /// The internal key representing the category (e.g., 'coffee', 'restaurant').
  /// This value is passed to the [FilterByCategoryPressed] event.
  final String categoryKey;

  /// Creates a CategoryFilterButton.
  const CategoryFilterButton({
    Key? key,
    required this.label,
    required this.categoryKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme data

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        // Use the same styling as the original buttons
        backgroundColor: theme.cardColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        // You might want to adjust padding or other style properties here if needed
      ),
      onPressed: () async {
        print('Selected category: $label (key: $categoryKey)');
        // --- Get map limits ---
        String? bboxString; // initialization of bbox string

        // Get Map Controller from Mapbloc State
        // it can find the Mapbloc provided above (from the widget tree).
        final mapController = context.read<MapBloc>().state.mapController;

        if (mapController == null) {
          print("CategoryFilterButton Error: Map controller is null!");
          // Send the event without bbox if the controller was not found
          context.read<SearchBloc>().add(FilterByCategoryPressed(categoryKey));
          return;
        }

        try {
          print('[$label Button] Getting current camera state...');
          final mapbox.CameraState currentCameraState = await mapController.getCameraState();
          print('[$label Button] Current CameraState received.');

          // Calculate the limits for the current camera
          // Make Cameraopations from Camerastate
          final mapbox.CameraOptions currentCameraOptions = mapbox.CameraOptions(
            center: currentCameraState.center,
            padding: currentCameraState.padding,
            zoom: currentCameraState.zoom,
            bearing: currentCameraState.bearing,
            pitch: currentCameraState.pitch,
          );

          final mapbox.CoordinateBounds? bounds = await mapController.coordinateBoundsForCamera(currentCameraOptions);

          //Format the string
          if (bounds != null) {
            // Access to Coordinatebounds' Properties coordinates
            final minLng = bounds.southwest.coordinates.lng;
            final minLat = bounds.southwest.coordinates.lat;
            final maxLng = bounds.northeast.coordinates.lng;
            final maxLat = bounds.northeast.coordinates.lat;
            bboxString = '$minLng,$minLat,$maxLng,$maxLat';
            print('[$label Button] Calculated BBOX: $bboxString');
          } else {
            print('[$label Button] Could not get map bounds (getVisibleCoordinateBounds returned null).');
          }
        } catch (e) {
          print("[$label Button] Error getting map bounds: $e");
        }
        // Dispatch the event to the SearchBloc using the provided categoryKey and bboxString
        context.read<SearchBloc>().add(FilterByCategoryPressed(categoryKey, bbox: bboxString));
      },
      // Use the provided label for the button's text
      child: Text(label),
    );
  }
}