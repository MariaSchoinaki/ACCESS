import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import '../blocs/map_bloc/map_bloc.dart';
import '../blocs/map_bloc/map_event.dart';
import '../blocs/map_bloc/map_state.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final mapbox.CameraOptions initialCameraOptions = mapbox.CameraOptions(
    center: mapbox.Point(coordinates: mapbox.Position(23.7325, 37.9908)),
    zoom: 14.0,
    bearing: 0,
    pitch: 0,
  );

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MapBloc()..add(RequestLocationPermission()),
      child: Scaffold(
        body: BlocBuilder<MapBloc, MapState>(
          builder: (context, state) {
            return Stack(
              children: [
                Column(
                  children: [
                    Container(
                      color: const Color(0xFFF5F5F5),
                      padding: const EdgeInsets.fromLTRB(16, 50, 16, 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                        ),
                        child: const TextField(
                          decoration: InputDecoration(
                            hintText: 'Αναζήτηση...',
                            prefixIcon: Icon(Icons.search),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(12),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: mapbox.MapWidget(
                        key: const ValueKey("mapWidget"),
                        cameraOptions: initialCameraOptions,
                        styleUri: mapbox.MapboxStyles.MAPBOX_STREETS,
                        onMapCreated: (controller) {
                          context.read<MapBloc>().add(InitializeMap(controller));
                        },
                      ),
                    ),
                  ],
                ),
                Positioned(
                  right: 16,
                  bottom: 100,
                  child: Column(
                    children: [
                      FloatingActionButton(
                        heroTag: "location",
                        mini: true,
                        onPressed: () => context.read<MapBloc>().add(GetCurrentLocation()),
                        child: const Icon(Icons.my_location),
                      ),
                      const SizedBox(height: 10),
                      FloatingActionButton(
                        heroTag: "zoomIn",
                        mini: true,
                        onPressed: () => context.read<MapBloc>().add(ZoomIn()),
                        child: const Icon(Icons.add),
                      ),
                      const SizedBox(height: 10),
                      FloatingActionButton(
                        heroTag: "zoomOut",
                        mini: true,
                        onPressed: () => context.read<MapBloc>().add(ZoomOut()),
                        child: const Icon(Icons.remove),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: const [
                        Icon(Icons.home, color: Colors.black),
                        Icon(Icons.person, color: Colors.black),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
