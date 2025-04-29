import 'package:flutter/material.dart';
import '../models/mapbox_feature.dart';

/// A card widget designed to display information about a selected [MapboxFeature].
///
/// Shows details like the feature's name, address, categories, accessibility status,
/// and coordinates. It also includes placeholder buttons for starting navigation or
/// getting directions. If the provided [feature] is null, the card renders nothing.
class LocationInfoCard extends StatelessWidget {
  /// The map feature whose information will be displayed. Can be null.
  final MapboxFeature? feature;

  /// Creates a [LocationInfoCard].
  ///
  /// The [feature] parameter is required, but can be null. If null,
  /// an empty widget ([SizedBox.shrink]) is rendered.
  const LocationInfoCard({
    Key? key,
    required this.feature, // Note: required but nullable
  }) : super(key: key);

  @override
  /// Builds the visual representation of the location information card.
  ///
  /// Returns an empty widget if [feature] is null. Otherwise, displays
  /// feature details using null-safe operators and default text for missing data.
  Widget build(BuildContext context) {
    // Case 1: If feature is null, display nothing.
    if (feature == null) {
      return const SizedBox.shrink(); // Renders an empty box
    }

    // Get the current theme for styling.
    final theme = Theme.of(context);

    // Main container for the card content.
    return Container(
      // Apply padding around the content.
      padding: const EdgeInsets.all(16),
      // Style the card container.
      decoration: BoxDecoration(
        color: theme.cardColor, // Use cardColor for contrast or scaffoldBackgroundColor
        borderRadius: BorderRadius.circular(18), // Rounded corners
        boxShadow: [ // Optional: Add subtle shadow
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      // Arrange content vertically.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
        mainAxisSize: MainAxisSize.min, // Take up minimum vertical space
        children: [
          // Display feature name, using default text if null.
          Text(
            feature?.name ?? 'Άγνωστη Τοποθεσία', // Default text if name is null
            style: theme.textTheme.titleLarge, // Use large title style from theme
          ),
          const SizedBox(height: 4), // Spacing

          // Display full address, using default text if null.
          Text(
            feature?.fullAddress ?? 'Δεν βρέθηκε διεύθυνση', // Default text if address is null
            style: theme.textTheme.bodyMedium, // Use standard body style
          ),
          const SizedBox(height: 4), // Spacing

          // Display POI categories, only if available and not just 'address'.
          // Added check for null and empty list, and ignore if only 'address'
          if (feature?.poiCategory != null &&
              feature!.poiCategory.isNotEmpty &&
              !(feature!.poiCategory.length == 1 && feature!.poiCategory.first == 'address'))
            Padding( // Add some padding if categories are shown
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                // Join category list into a string. Safe due to checks above.
                'Categories: ${feature!.poiCategory.join(', ')}',
                style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: theme.hintColor), // Use body small italic greyed out
              ),
            ),

          const SizedBox(height: 8), // Spacing

          // Display accessibility information.
          Row(
            children: [
              Text(
                'Accessibility: ', // Label
                style: theme.textTheme.bodyMedium,
              ),
              Icon(
                // Choose icon based on accessibleFriendly flag (default to false).
                feature?.accessibleFriendly ?? false
                    ? Icons.accessible_forward // Use a more distinct icon
                    : Icons.not_accessible, // Icon for not accessible
                // Change color based on accessibility status.
                color: feature?.accessibleFriendly ?? false
                    ? Colors.green.shade700 // Darker green for accessible
                    : Colors.red.shade700,   // Darker red for not accessible
                size: 20, // Adjust size
              ),
              const SizedBox(width: 4),
              Text( // Add text description for clarity
                feature?.accessibleFriendly ?? false ? 'Accessible' : 'Not Accessible',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: feature?.accessibleFriendly ?? false
                        ? Colors.green.shade700
                        : Colors.red.shade700,
                    fontWeight: FontWeight.bold
                ),
              )
            ],
          ),
          const SizedBox(height: 4), // Spacing

          // Display coordinates, using default text if null and formatting.
          Text(
            'Lat: ${feature?.latitude?.toStringAsFixed(5) ?? 'N/A'}   Lon: ${feature?.longitude?.toStringAsFixed(5) ?? 'N/A'}',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.shade700), // Use body small greyed out
          ),
          const SizedBox(height: 12), // Spacing before buttons

          // Row containing action buttons.
          Row(
            mainAxisAlignment: MainAxisAlignment.start, // Align buttons to the start
            children: [
              // "Start" Button (placeholder action)
              ElevatedButton.icon(
                onPressed: () => _navigateToDirections(context), // Placeholder action
                icon: const Icon(Icons.play_arrow, size: 18),
                label: const Text('Start'), // English label
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: theme.textTheme.labelMedium, // Adjust text style
                ),
              ),
              const SizedBox(width: 10), // Spacing between buttons
              // "Directions" Button (placeholder action)
              ElevatedButton.icon(
                onPressed: () => _navigateToDirections(context), // Placeholder action
                icon: const Icon(Icons.directions, size: 18),
                label: const Text('Directions'), // English label
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: theme.textTheme.labelMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Placeholder method intended for initiating navigation or showing directions
  /// to the selected [feature]'s location.
  ///
  /// This method should be implemented to use the [feature]'s coordinates
  /// (latitude/longitude) to launch an external navigation app (like Google Maps,
  /// Apple Maps) or display directions within the application's map interface.
  /// Requires the [feature] passed to the widget to be non-null.
  ///
  /// - [context]: The build context, potentially used for showing SnackBars or dialogs.
  void _navigateToDirections(BuildContext context) {
    // Ensure feature is not null before proceeding.
    if (feature == null) {
      print("Attempted to navigate but feature was null.");
      return;
    }
    // TODO: Implement navigation logic using feature!.latitude and feature!.longitude.

    print('Navigate/Directions button pressed for: ${feature?.name ?? 'N/A'}');
    print('Coordinates: ${feature?.latitude}, ${feature?.longitude}');
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Directions functionality not implemented yet.'))
    );
  }
}