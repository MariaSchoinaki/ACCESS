///General Imports
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:geolocator/geolocator.dart' as geolocator;

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

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  String location = '';
  MapboxFeature? selectedFeature;

  bool _routeLayerAndSourceAdded = false;
  static const String ROUTE_SOURCE_ID = 'user-tracked-route-source';
  static const String ROUTE_LAYER_ID = 'user-tracked-route-layer';

  final TextEditingController _searchController = TextEditingController();
  mapbox.MapboxMap? mapboxMap;

  final mapbox.CameraOptions initialCameraOptions = mapbox.CameraOptions(
    center: mapbox.Point(coordinates: mapbox.Position(23.7325, 37.9908)),
    zoom: 14.0,
  );

  /// Map Interaction Callbacks
  void _onLongTap(mapbox.MapContentGestureContext context, BuildContext widgetContext) {
    final lat = context.point.coordinates.lat.toDouble();
    final lng = context.point.coordinates.lng.toDouble();

    // Ενημέρωσε το τοπικό state για το info card
    setState(() {
      location = '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';
    });
    // Στείλε events στον MapBloc και SearchBloc
    widgetContext.read<MapBloc>().add(AddMarker(lat, lng));
    widgetContext.read<SearchBloc>().add(RetrieveNameFromCoordinatesEvent(lat, lng));
  }

  void _onTap(mapbox.MapContentGestureContext context, BuildContext widgetContext) {
    try {
      // Καθάρισε τοπικό state και search bar
      setState(() {
        location = '';
        selectedFeature = null; // Καθάρισε και το feature
      });
      _searchController.clear();
      // Στείλε events για καθαρισμό markers
      widgetContext.read<MapBloc>().add(DeleteMarker()); // Καθαρίζει το απλό marker
      widgetContext.read<MapBloc>().add(ClearCategoryMarkers()); // Καθαρίζει τα category markers
    } catch (e) {
      print("Error on tap: $e");
      ScaffoldMessenger.of(widgetContext).showSnackBar(
          SnackBar(content: Text('Σφάλμα κατά το πάτημα: ${e.toString()}')));
    }
  }

  /// Callback for when the map style is loaded
  Future<void> _onStyleLoaded(mapbox.StyleLoadedEventData data) async {
    // Add the source and layer for the tracked route ONCE
    if (!mounted || _routeLayerAndSourceAdded) return;

    print("Map style loaded. Checking/Adding route source and layer...");
    if (mapboxMap != null) {
      final sourceExists = await mapboxMap?.style.styleSourceExists(ROUTE_SOURCE_ID);
      if (sourceExists == false) {
        try {
          // Add empty GeoJSON source initially
          await mapboxMap?.style.addSource(mapbox.GeoJsonSource(
            id: ROUTE_SOURCE_ID,
            data: '{"type": "FeatureCollection", "features": []}', // Start empty
          ));
          print("Route source added: $ROUTE_SOURCE_ID");

          // Add line layer linked to the source
          await mapboxMap?.style.addLayer(mapbox.LineLayer(
            id: ROUTE_LAYER_ID,
            sourceId: ROUTE_SOURCE_ID,
            lineColor: Colors.blue.value, // Customize color
            lineWidth: 4.0,             // Customize width
            lineOpacity: 0.8,           // Customize opacity
            lineJoin: mapbox.LineJoin.ROUND,
            lineCap: mapbox.LineCap.ROUND,
          ));
          print("Route layer added: $ROUTE_LAYER_ID");

          if(mounted){ setState(() { _routeLayerAndSourceAdded = true; }); }
        } catch (e) {
          print("Error adding route source/layer: $e");
          if(mounted){ setState(() { _routeLayerAndSourceAdded = false; }); }
        }
      } else {
        print("Route source already exists.");
        if(mounted && !_routeLayerAndSourceAdded){ setState(() { _routeLayerAndSourceAdded = true; }); }
      }
    }
  }

  /// Callback to inform coordinates by search result
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
            /// --- Logic for Search Bloc ---
            if (state is CoordinatesLoaded) {
              selectedFeature = state.feature;
              final latitude = selectedFeature?.latitude;
              final longitude = selectedFeature?.longitude;
              if (latitude != null && longitude != null) {
                _onSearchResultReceived(latitude, longitude);
                context.read<MapBloc>().add(FlyTo(latitude, longitude));
                context.read<MapBloc>().add(AddMarker(latitude, longitude));
              }
            } else if (state is CoordinatesError) {
              print("Search Error: ${state.message}");
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Σφάλμα αναζήτησης: ${state.message}'), backgroundColor: Colors.orange));
            }
            if (state is NameLoaded) {
              print('Name Loaded: ${state.feature.fullAddress}');
              setState(() {
                selectedFeature = state.feature;
              });
              _searchController.text = selectedFeature!.fullAddress;
            } else if (state is NameError) {
              print('Geocoding Error: ${state.message}');
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Σφάλμα εύρεσης ονόματος: ${state.message}'), backgroundColor: Colors.orange));
            }
            if (state is CategoryResultsLoaded) {
              context.read<MapBloc>().add(AddCategoryMarkers(state.features, shouldZoomToBounds: true));
            }
            /// --- /Logic for Search Bloc ---
          },
          child: BlocConsumer<MapBloc, MapState>(
            listenWhen: (previous, current) {
              return previous.trackedRoute != current.trackedRoute ||
                  previous.isTracking != current.isTracking ||
                  previous.trackingStatus != current.trackingStatus ||
                  previous.errorMessage != current.errorMessage;
            },
            listener: (context, mapState) async {

              /// --- Update map source when route changes ---
              if (mapboxMap != null && _routeLayerAndSourceAdded) {
                print("Listener triggered for route update. Points: ${mapState.trackedRoute.length}");
                final List<List<double>> coordinates = mapState.trackedRoute
                    .map((pos) => [pos.longitude, pos.latitude])
                    .toList();

                String geoJsonData;
                // Designed a line only if there is a tracking and there are at least 2 points
                if (mapState.isTracking && coordinates.length >= 2) {
                  geoJsonData = jsonEncode({
                    "type": "FeatureCollection",
                    "features": [{
                      "type": "Feature",
                      "geometry": {"type": "LineString", "coordinates": coordinates,}
                    }]
                  });
                } else {
                  // Empty Geojson to clear the line
                  geoJsonData = '{"type": "FeatureCollection", "features": []}';
                }
                try {
                  print("Attempting to update route source using setStyleSourceProperty...");
                  await mapboxMap?.style.setStyleSourceProperty(
                      ROUTE_SOURCE_ID,
                      'data',
                      geoJsonData
                  );
                  print("Route source updated successfully using setStyleSourceProperty.");
                } catch (e) {
                  print("Error updating route source with setStyleSourceProperty: $e");
                }
              }
            },
            builder: (context, mapState) {
              return Stack(
                children: [
                  // --- Map and Search Bar ---
                  Column(
                    children: [
                      SB.SearchBar(searchController: _searchController),
                      Expanded(
                        child: mapbox.MapWidget(
                          key: const ValueKey("mapWidget"),
                          cameraOptions: initialCameraOptions,
                          styleUri: "mapbox://styles/el03/cm9vbhxcb005901si1bp370nc",
                          textureView: true, // Important for rendering annotations over the map
                          onTapListener: (gestureContext) => _onTap(gestureContext, context),
                          onLongTapListener: (gestureContext) => _onLongTap(gestureContext, context),
                          onStyleLoadedListener: _onStyleLoaded,
                          onMapCreated: (controller) {
                            // We send the controller to Mapbloc Only one time
                            //to avoid problems if widget is rebuilt
                            if (context.read<MapBloc>().state.mapController == null) {
                              context.read<MapBloc>().add(InitializeMap(controller));
                            }
                            controller.location.updateSettings(
                                mapbox.LocationComponentSettings(
                                    enabled: true,
                                    pulsingEnabled: false,
                                    showAccuracyRing: true,
                                    puckBearingEnabled: true
                                )
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  /// --- /Map and Search Bar ---

                  /// --- Location Info Card (Όπως πριν) ---
                  if (location.isNotEmpty && selectedFeature != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 10, // Ίσως λίγο πιο πάνω από τον πάτο
                      child: LocationInfoCard(
                        feature: selectedFeature,
                      ),
                    ),
                  /// --- /Location Info Card ---

                  /// Zoom Controls
                  Positioned(
                    right: 16,
                    bottom: (location.isNotEmpty) ? 200 : 80,
                    child: ZoomControls(),
                  ),
                  /// Zoom Controls


                  /// BUTTON START/STOP
                  Positioned(
                    right: 16,
                    bottom: (location.isNotEmpty) ? 150 : 35,
                    child: FloatingActionButton(
                      // Different Herotag depending on the condition to avoid errors
                      heroTag: mapState.isTracking ? "stop_tracking_fab" : "start_tracking_fab",
                      mini: true, // Μικρό μέγεθος
                      tooltip: mapState.isTracking ? 'Παύση Καταγραφής' : 'Έναρξη Καταγραφής', // Tooltip
                      onPressed: () {
                        // Do not do anything if it loads to start tracking
                        if (mapState.trackingStatus == MapTrackingStatus.loading) return;
                        if (mapState.isTracking) {
                          context.read<MapBloc>().add(StopTrackingRequested());
                        } else {
                          context.read<MapBloc>().add(StartTrackingRequested());
                        }
                      },
                      // Changed color based on status
                      backgroundColor: mapState.isTracking
                          ? Colors.red.shade700 // red when it records
                          : theme.colorScheme.secondary,
                      foregroundColor: Colors.white,
                      child: mapState.trackingStatus == MapTrackingStatus.loading
                          ? const SizedBox( // Loading indicator
                        width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                          : Icon(mapState.isTracking
                          ? Icons.stop
                          : Icons.play_arrow
                      ),
                    ),
                  )
                ],
              );
            },
          ),
        ),
        bottomNavigationBar: const BottomNavBar(),
      ),
    );
  }

  // --- Lifecycle Methods ---
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }
// --- Lifecycle Methods ---

}