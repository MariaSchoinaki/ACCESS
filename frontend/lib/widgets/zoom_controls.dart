import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/map_bloc/map_bloc.dart';
import '../theme/app_colors.dart';

/// Interactive zoom and location controls for map navigation
///
/// Provides:
/// - Current location button
/// - Zoom in/out buttons
/// - Themed floating action buttons
///
/// Requires:
/// - [MapBloc] in widget tree for event handling
class ZoomControls extends StatelessWidget {
  const ZoomControls({Key? key}) : super(key: key);

  /// Builds the vertical control panel
  ///
  /// Returns:
  /// [Column] with:
  /// - Location button (triggers [GetCurrentLocation] event)
  /// - Zoom in button (triggers [ZoomIn] event)
  /// - Zoom out button (triggers [ZoomOut] event)
  ///
  /// Styling:
  /// - Uses [Theme.hoverColor] for background
  /// - [AppColors.white] for icons
  /// - 10px spacing between buttons
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        FloatingActionButton(
          heroTag: "location",
          mini: true,
          onPressed: () => context.read<MapBloc>().add(GetCurrentLocation()),
          backgroundColor: theme.hoverColor,
          foregroundColor: AppColors.white,
          child: const Icon(Icons.my_location),
        ),
        const SizedBox(height: 10),
        FloatingActionButton(
          heroTag: "zoomIn",
          mini: true,
          onPressed: () => context.read<MapBloc>().add(ZoomIn()),
          backgroundColor: theme.hoverColor,
          foregroundColor: AppColors.white,
          child: const Icon(Icons.add),
        ),
        const SizedBox(height: 10),
        FloatingActionButton(
          heroTag: "zoomOut",
          mini: true,
          onPressed: () => context.read<MapBloc>().add(ZoomOut()),
          backgroundColor: theme.hoverColor,
          foregroundColor: AppColors.white,
          child: const Icon(Icons.remove),
        ),
      ],
    );
  }
}