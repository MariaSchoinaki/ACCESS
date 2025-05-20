import 'dart:convert'; // Για jsonEncode
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import '../blocs/map_bloc/map_bloc.dart';
import '../utils/displayRoutes.dart';
import 'search_bar.dart' as SB;

/// Type of Callback Function for TAP events on the map.
typedef MapTapCallback = void Function(mapbox.MapContentGestureContext context);
/// Type of Callback Function for prolonged press events on the map.
typedef MapLongTapCallback = void Function(mapbox.MapContentGestureContext context);

/// A widget displacing the main area of the map, including
/// a search bar at the top and the mapbox map below.
///
/// Handles the initialization of Map Controller, loading the map style,
/// the addition of the necessary Source and Layer for the appearance of the route
/// recorded by the user, and updating the route line reactive
/// Based on [Mapbloc] status changes.
/// Interaction events with the map (tap, long-tap) are promoted to parental
/// Widget via the Callbacks provided.
class MainMapArea extends StatefulWidget {
  /// [TextedingController] used by the search bar.
  final TextEditingController searchController;
  /// The initial camera settings when loading the map.
  final mapbox.CameraOptions initialCameraOptions;
  /// The Mapbox style URI to be used.
  final String styleUri;
  /// Callback function called when the user taps on the map.
  final MapTapCallback? onMapTap;
  /// Callback function called when the user does long-paress on the map.
  final MapLongTapCallback? onMapLongTap;

  /// Creates a [Mainmaparea] widget.
  ///
  /// requires a [SearchController] for search bar, [InitialCameraopations]
  /// and one [styleuri] for the map.
  /// Optional Callbacks [onmaptap] and [onmaplongtap] can be provided.
  const MainMapArea({
    super.key,
    required this.searchController, // Require controller
    required this.initialCameraOptions,
    required this.styleUri,
    this.onMapTap,
    this.onMapLongTap,
  });

  @override
  State<MainMapArea> createState() => _MainMapAreaState();
}

/// The state for [Mainmaparea] widget.
class _MainMapAreaState extends State<MainMapArea> {

  /// Flag to watch if the source Geojson and Linelayer for the route
  /// have successfully added to the map style.
  bool _routeLayerAndSourceAdded = false;

  /// ID for the Geojson source used to display the recorded route.
  static const String ROUTE_SOURCE_ID = 'user-tracked-route-source';
  /// ID for the linelayer used for the style and appearance of the recorded route.
  static const String ROUTE_LAYER_ID = 'user-tracked-route-layer';

  /// It is called when the controller of the mapbox map is created.
  ///
  /// Originizes [Mapbloc] with Controller (if not already defined)
  /// and adjusts the parameters of the map's location component.
  Future<void> _onMapCreated(mapbox.MapboxMap controller) async {

    // Check if widget is still on the tree
    if (!mounted) return;
    print("[MainMapArea] Map Created");

    // Access to Mapbloc through the current widget context
    final mapBloc = context.read<MapBloc>();
    // Sent Controller to Bloc only if not already
    if (mapBloc.state.mapController == null) {
      print("[MainMapArea] Sending InitializeMap event to Bloc.");
      mapBloc.add(InitializeMap(controller));
    } else {
      print("[MainMapArea] Bloc already has a map controller.");
    }

    /// Set a new projection
    mapbox.StyleProjection newProjection = mapbox.StyleProjection(
        name: mapbox.StyleProjectionName.mercator
    );
    await controller.style.setProjection(newProjection);
    /// change logo settings
    controller.logo.updateSettings(mapbox.LogoSettings(enabled: false));

    /// Setting the Location Puck (User Location Indication)
    controller.location.updateSettings(
      mapbox.LocationComponentSettings(
          enabled: true, pulsingEnabled: false, showAccuracyRing: true, puckBearingEnabled: true),
    );
  }

  /// It is called when the map style is fully loaded.
  ///
  /// adds the Geojson source and the linelayer required for the design
  /// of the user's route, ensuring that it is done only once.
  Future<void> _onStyleLoaded(mapbox.StyleLoadedEventData data) async {
    if (!mounted) { print("[MainMapArea] _onStyleLoaded: Not mounted, skipping."); return; }
    if (_routeLayerAndSourceAdded) { print("[MainMapArea] _onStyleLoaded: Already added, skipping."); return; }

    print("[MainMapArea] Style loaded. Flag is false. Getting controller from BLoC state...");
    final controllerFromState = context.read<MapBloc>().state.mapController;

    if (controllerFromState != null) {
      print("[MainMapArea] Controller from state is NOT null. Checking if source exists...");
      try {
        final sourceExists = await controllerFromState.style.styleSourceExists(ROUTE_SOURCE_ID);
        print("[MainMapArea] Source exists check returned: $sourceExists");

        if (sourceExists == false) {
          print("[MainMapArea] Source does NOT exist. Trying to add source...");
          // Add Geojson source (initially empty)
          await controllerFromState.style.addSource(mapbox.GeoJsonSource(
            id: ROUTE_SOURCE_ID, data: '{"type": "FeatureCollection", "features": []}',
          ));
          print("[MainMapArea] Route source ADDED successfully.");

          print("[MainMapArea] Trying to add layer...");
          await controllerFromState.style.addLayer(mapbox.LineLayer(
            id: ROUTE_LAYER_ID, sourceId: ROUTE_SOURCE_ID,
            lineColor: Colors.blue.value, lineWidth: 4.0, lineOpacity: 0.8,
            lineJoin: mapbox.LineJoin.ROUND, lineCap: mapbox.LineCap.ROUND,
          ));
          print("[MainMapArea] Route layer ADDED successfully.");

          // Flag update that the addition was completed
          if (mounted) {
            print("[MainMapArea] Setting _routeLayerAndSourceAdded = true");
            setState(() { _routeLayerAndSourceAdded = true; });
          }
        } else {
          print("[MainMapArea] Source already exists. Setting flag true.");
          if (mounted && !_routeLayerAndSourceAdded) {
            setState(() { _routeLayerAndSourceAdded = true; });
          }
        }
      } catch (e) {
        print("[MainMapArea] !!! CAUGHT ERROR adding source/layer: $e");
        // Error handling when adding Source/Layer
        if (mounted) { setState(() { _routeLayerAndSourceAdded = false; }); }
      }
    } else {
      print("[MainMapArea] Controller from BLoC state IS NULL when style loaded.");
    }
  }


  @override
  /// It builds the Widget structure by including a [bloclistener] to update
  /// of the route line and a [column] containing the search bar and the map.
  Widget build(BuildContext context) {
    // We use bloclistener here to update the source of the map
    // When the route is changed to Mapbloc State, without renewing the entire Mapwidget.
    return BlocListener<MapBloc, MapState>(
      listenWhen: (previous, current) {
        // Listen only when the route or tracking state is changing that affects the line
        return previous.trackedRoute != current.trackedRoute ||
            previous.isTracking != current.isTracking;
      },
      listener: (context, mapState) async {
        final currentMapController = mapState.mapController;
        // Read local flag for whether the layer has been added
        final bool layerAdded = _routeLayerAndSourceAdded;

        final style = await currentMapController?.style;
        final layers = await style?.getStyleLayers();
        for (final layer in layers!) {
          print('Layer ID: ${layer?.id}');
        }
        print("[MainMapArea Listener] Check: Controller ${currentMapController == null ? 'NULL' : 'OK'}, LayerAdded: $layerAdded");

        // Go ahead only if there is controller and layer/source have been added
        if (currentMapController != null && layerAdded) {
          print("[MainMapArea Listener] State changed. isTracking: ${mapState.isTracking}, Points: ${mapState.trackedRoute.length}");
          // Convert Position List to Coordinate List [LNG, LAT] for Geojson
          final List<List<double>> coordinates = mapState.trackedRoute
              .map((pos) => [pos.longitude, pos.latitude])
              .toList();
          String geoJsonData;
          // Create Geojson Linestring only if there is a tracking and there are at least 2 points
          if (mapState.isTracking && coordinates.length >= 2) {
            geoJsonData = jsonEncode({
              "type": "FeatureCollection",
              "features": [{"type": "Feature", "geometry": {"type": "LineString", "coordinates": coordinates,}}]
            });
            print("[MainMapArea Listener] Generated GeoJSON with ${coordinates.length} points.");
          } else {
            // Else, send a geojson blank to clear the line
            geoJsonData = '{"type": "FeatureCollection", "features": []}';
            print("[MainMapArea Listener] Generated empty GeoJSON.");
          }
          try{
            // Informed Geojsonsource's 'Data' property
            print("[MainMapArea Listener] Attempting setStyleSourceProperty...");
            await currentMapController.style.setStyleSourceProperty(ROUTE_SOURCE_ID, 'data', geoJsonData);
            print("[MainMapArea Listener] setStyleSourceProperty finished.");
          } catch(e) {
            // Error handling while updating Source
            print("[MainMapArea Listener] !!! Error updating source: $e");
          }
        } else {
          if(currentMapController == null) print("[MainMapArea Listener] Skipping source update (controller from state is NULL).");
          if(!layerAdded) print("[MainMapArea Listener] Skipping source update (layer not added yet).");
        }
      },
      child: Column(
        children: [
          // The search bar, uses the controller given as a parameter
          //SB.SearchBar(searchController: widget.searchController),
          // Mapbox Map, gets the rest of the height available
          Expanded(
            child: mapbox.MapWidget(
              key: const ValueKey("mapWidget"),
              cameraOptions: widget.initialCameraOptions,
              viewport: getFollow() ? mapbox.FollowPuckViewportState(
                zoom: 16.0,
                bearing: mapbox.FollowPuckViewportStateBearingHeading(),
                pitch: 45.0,
              ) : mapbox.IdleViewportState(),
              styleUri: widget.styleUri,
              textureView: true,
              onTapListener: widget.onMapTap,
              onLongTapListener: widget.onMapLongTap,
              onStyleLoadedListener: _onStyleLoaded,
              onMapCreated: _onMapCreated,
            ),
          ),
        ],
      ),
    );
  }
}