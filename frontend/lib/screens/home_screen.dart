///General Imports
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

///Bloc Imports
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/map_bloc/map_bloc.dart';
import '../blocs/search_bloc/search_bloc.dart';

import '../models/mapbox_feature.dart';
///Services Imports
import '../services/search_service.dart';

///Widget and Theme Imports
import 'package:access/theme/app_colors.dart';
import '../widgets/bottom_bar.dart';
import '../widgets/location_card.dart';
import '../widgets/zoom_controls.dart';
import '../widgets/search_bar.dart' as SB;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String location = '';
  MapboxFeature? selectedFeature;

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
    widgetContext.read<MapBloc>().add(AddMarker(lat, lng));
    widgetContext.read<SearchBloc>().add(RetrieveNameFromCoordinatesEvent(lat, lng));
  }

  _onTap(mapbox.MapContentGestureContext context, BuildContext widgetContext) {
    setState(() {
      location = '';
    });
    _searchController.clear();
    widgetContext.read<MapBloc>().add(DeleteMarker());
  }

  void _onSearchResultReceived(double latitude, double longitude) {
    setState(() {
      location = '${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}';
    });
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
        body: BlocListener<SearchBloc, SearchState>(
          listener: (context, state) {

            ///for search
            if (state is CoordinatesLoaded) {
              selectedFeature = state.feature;
              final latitude = selectedFeature?.latitude;
              final longitude = selectedFeature?.longitude;

              _onSearchResultReceived(latitude!, longitude!);
              context.read<MapBloc>().add(FlyTo(latitude, longitude));
              context.read<MapBloc>().add(AddMarker(latitude, longitude));
            } else if (state is CoordinatesError) {
              print("Error: ${state.message}");
            }
            ///for geocoding
            if (state is NameLoaded) {
              print('Name Loaded: ${state.feature.fullAddress}');
              setState(() {
                selectedFeature = state.feature;
              });
              _searchController.text = selectedFeature!.fullAddress;
            } else if (state is NameError) {
              print('Error: ${state.message}');
            }

          },
          child: BlocBuilder<MapBloc, MapState>(
            builder: (context, mapState) {
              return Stack(
                children: [
                  Column(
                    children: [
                      SB.SearchBar(searchController: _searchController),
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
                                      puckBearingEnabled: true
                                  )
                              );
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  if (location.isNotEmpty )
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: -10,
                      child: LocationInfoCard(
                        feature: selectedFeature,
                      ),
                    ),

                  //zoom
                  Positioned(
                    right: 16,
                    bottom: (location.isNotEmpty) ? 200 : 80,
                    child: ZoomControls(),
                  ),
                ],
              );
            },
          ),
        ),
        bottomNavigationBar: const BottomNavBar(),
      ),
    );
  }
}
