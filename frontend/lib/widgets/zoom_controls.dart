// zoom_controls.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/map_bloc/map_bloc.dart';
import '../theme/app_colors.dart';

class ZoomControls extends StatelessWidget {
  const ZoomControls({Key? key}) : super(key: key);

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
