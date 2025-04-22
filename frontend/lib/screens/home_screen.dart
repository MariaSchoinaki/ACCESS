import 'package:access/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import '../blocs/map_bloc/map_bloc.dart';
import '../blocs/map_bloc/map_event.dart';
import '../blocs/map_bloc/map_state.dart';
import '../blocs/search_bloc/search_bloc.dart';
import '../blocs/search_bloc/search_event.dart';
import '../blocs/search_bloc/search_state.dart';
import '../services/search_service.dart';
import '../widgets/bottom_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String location = '';
  final TextEditingController _searchController = TextEditingController();
  mapbox.MapboxMap? mapboxMap;

  final mapbox.CameraOptions initialCameraOptions = mapbox.CameraOptions(
    center: mapbox.Point(coordinates: mapbox.Position(23.7325, 37.9908)),
    zoom: 14.0,
    bearing: 0,
    pitch: 0,
  );

  _onLongTap(mapbox.MapContentGestureContext context, BuildContext widgetContext) {
    final lat = context.point.coordinates.lat.toDouble();
    final lng = context.point.coordinates.lng.toDouble();

    setState(() {
      location = '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';
    });
    _searchController.text = location;
    widgetContext.read<MapBloc>().add(AddMarker(lat, lng));
  }

  _onTap(mapbox.MapContentGestureContext context, BuildContext widgetContext) {
    setState(() {
      location = '';
    });
    _searchController.clear();
    widgetContext.read<MapBloc>().add(DeleteMarker());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => MapBloc()..add(RequestLocationPermission())),
        BlocProvider(create: (_) => SearchBloc(searchService: SearchService())),
      ],
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: theme.scaffoldBackgroundColor,
        body: BlocBuilder<MapBloc, MapState>(
          builder: (context, state) {
            return Stack(
              children: [
                Column(
                  children: [
                    Container(
                      color: theme.scaffoldBackgroundColor,
                      padding: const EdgeInsets.fromLTRB(16, 50, 16, 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: theme.hintColor, blurRadius: 6)
                          ],
                        ),
                        child: BlocBuilder<SearchBloc, SearchState>(
                          builder: (context, state) {
                            return Column(
                              children: [
                                TextField(
                                  controller: _searchController,
                                  onSubmitted: (value) {
                                    context.read<SearchBloc>().add(SearchQueryChanged(value));
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'Αναζήτηση...',
                                    prefixIcon: Icon(Icons.search, color: theme.iconTheme.color),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(12),
                                    hintStyle: theme.inputDecorationTheme.hintStyle,
                                  ),
                                ),
                                if (state is SearchLoading)
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                if (state is SearchLoaded)
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: state.results.length,
                                    itemBuilder: (context, index) {
                                      final result = state.results[index];
                                      return ListTile(
                                        title: Text(result.name, style: theme.textTheme.bodyMedium),
                                        onTap: () {
                                          _searchController.text = result.name;
                                          FocusScope.of(context).unfocus();
                                          context.read<SearchBloc>().add(SearchQueryChanged(""));
                                          context.read<MapBloc>().add(FlyTo(result.latitude, result.longitude));
                                          context.read<MapBloc>().add(AddMarker(result.latitude, result.longitude));
                                        },
                                      );
                                    },
                                  ),
                                if (state is SearchError)
                                  Text('Error: ${state.message}', style: theme.textTheme.bodyMedium),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    Expanded(
                      child: mapbox.MapWidget(
                        key: const ValueKey("mapWidget"),
                        cameraOptions: initialCameraOptions,
                        styleUri: mapbox.MapboxStyles.MAPBOX_STREETS,
                        onTapListener: (gestureContext) => _onTap(gestureContext, context),
                        onLongTapListener: (gestureContext) => _onLongTap(gestureContext, context),
                        onMapCreated: (controller) {
                          context.read<MapBloc>().add(InitializeMap(controller));
                          setState(() {
                            mapboxMap = controller;
                            mapboxMap?.location.updateSettings(
                              mapbox.LocationComponentSettings(
                                enabled: true,
                                pulsingEnabled: false,
                                showAccuracyRing: true,
                                puckBearingEnabled: true,
                              ),
                            );
                          });
                        },
                      ),
                    ),
                  ],
                ),

                if (location.isNotEmpty)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: -12,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lat: ${location.split(',')[0]}   Lon: ${location.split(',')[1]}',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.directions),
                                label: const Text('Directions'),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Start'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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
                  ),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: const BottomNavBar(),
      ),
    );
  }
}
