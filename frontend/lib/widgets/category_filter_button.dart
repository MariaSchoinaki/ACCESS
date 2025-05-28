import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import '../blocs/map_bloc/map_bloc.dart';
import '../blocs/search_bloc/search_bloc.dart';
import '../utils/bbox.dart';


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

  /// Optional icon to display next to the label.
  final IconData? icon;

  /// Creates a CategoryFilterButton.
  const CategoryFilterButton({
    super.key,
    required this.label,
    required this.categoryKey,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context); // Get theme data

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        // Use the same styling as the original buttons
        backgroundColor: theme.cardColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        // You might want to adjust padding or other style properties here if needed
      ),
      onPressed: () async {
        print('Selected category: $label (key: $categoryKey)');
        // --- Get map limits ---


        // Get Map Controller from Mapbloc State
        // it can find the Mapbloc provided above (from the widget tree).
        final mapController = context.read<MapBloc>().state.mapController;

        if (mapController == null) {
          print("CategoryFilterButton Error: Map controller is null!");
          // Send the event without bbox if the controller was not found
          context.read<SearchBloc>().add(FilterByCategoryPressed(categoryKey));
          return;
        }
        final bboxString = await getBbox(context); // initialization of bbox string

        // Dispatch the event to the SearchBloc using the provided categoryKey and bboxString
        context.read<SearchBloc>().add(FilterByCategoryPressed(categoryKey, bbox: bboxString));
      },
      // Use the provided label for the button's text
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 6),
          ],
          Text(label),
        ],
      ),
    );
  }
}