import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

///Bloc Imports
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/map_bloc/map_bloc.dart';
import '../blocs/search_bloc/search_bloc.dart';

import '../models/mapbox_feature.dart';

///Services Imports

///Widget and Theme Imports
import '../widgets/bottom_bar.dart';
import '../widgets/location_card.dart';
import '../widgets/zoom_controls.dart';
import '../widgets/start_stop_tracking_button.dart';
import '../widgets/main_map_area.dart';

/// The main "home" display of the app.
///
/// Displays the main interface map, the search bar (via [Mainmaparea]),
/// the location information card, map control details and mode
/// Route Log. Interacts with [Mapbloc] and [Searchbloc] for
/// Managing the status of the map, searches and recording.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

/// the state for [homepage] widget.
///
/// manages the condition associated with user's interactions, such as
/// the location option through search or prolonged press
/// controls the search field ([_searchcontroller] and handles callbacks from
/// Interacts with the map. She also monitors her life cycle changes
/// application through [Widgetsbindingobserver].
class _HomePageState extends State<HomePage> with WidgetsBindingObserver {

  /// Saves the representation of a string (Lat, lon) of the current selected
  /// Location, mainly used to control the location/visibility of Overlay Widgets.
  String location = '';
  /// Holds detailed location information selected either through search
  /// either by reverse geo categorization from prolonged tap. Used by [locationinfocard].
  MapboxFeature? selectedFeature;

  /// Controller for the search text of the search text, passes on [Mainmaparea].
  final TextEditingController _searchController = TextEditingController();

  /// Home camera settings for the map during first loading.
  final mapbox.CameraOptions initialCameraOptions = mapbox.CameraOptions(
    center: mapbox.Point(coordinates: mapbox.Position(23.7325, 37.9908)),
    zoom: 14.0,
  );

  /// It handles the gesture of long tap to the map provided by [Mainmaparea].
  ///
  /// updates local status [location] with coordinates, activates [Mapbloc]
  /// to add index (marker) and activates [Searchbloc] to find
  /// of the address corresponding to the coordinates (reverse geo -geotoryisation).
  ///
  /// - [GestureContext]: Provides details of the gesture, including coordinates.
  /// - [BuildContext]: Buildcontext from the Widget tree where blocs can be accessed.
  void _onLongTap(mapbox.MapContentGestureContext gestureContext, BuildContext buildContext) {
    final lat = gestureContext.point.coordinates.lat.toDouble();
    final lng = gestureContext.point.coordinates.lng.toDouble();
    // Check if widget still exists before calling Setstate
    if (!mounted) return;
    setState(() { location = '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}'; });
    // Use Homepage's context to access blocs
    context.read<MapBloc>().add(AddMarker(lat, lng));
    context.read<SearchBloc>().add(RetrieveNameFromCoordinatesEvent(lat, lng));
  }

  /// It handles the tap gesture (tap) to the map provided by [Mainmaparea].
  ///
  /// cleans the currently selected location ([Location], [SelectedFeature]),
  /// cleans the text on the search bar and activates [Mapbloc]
  /// to remove any indicators (simple TAP index and class indicators),
  /// only IF the user taps on an empty space on the map.
  ///
  ///
  /// - [GestureContext]: Provides details of the gesture.
  /// - [BuildContext]: Buildcontext from the Widget tree where blocs can be accessed.
  Future<void> _onTap(mapbox.MapContentGestureContext gestureContext, BuildContext buildContext) async {
    final mapController = context.read<MapBloc>().state.mapController;
    if (!mounted || mapController == null) {
      print("_onTap: Widget not mounted or controller is null. Skipping.");
      return;
    }

    try {
      final screenPoint = gestureContext.touchPosition;
      print("_onTap: Tap detected at screen coordinates: (${screenPoint.x}, ${screenPoint.y})");

      final geometry = mapbox.RenderedQueryGeometry.fromScreenCoordinate(screenPoint);
      final options = mapbox.RenderedQueryOptions(layerIds: null, filter: null);

      print("_onTap: Querying rendered features...");
      final List<mapbox.QueriedRenderedFeature?>? features = await mapController.queryRenderedFeatures(geometry, options);

      if (features == null || features.isEmpty) {
        print("_onTap: Empty space tapped. Clearing selection.");
        if (!mounted) return;

        setState(() { location = ''; selectedFeature = null; });
        _searchController.clear();

        context.read<MapBloc>().add(DeleteMarker());
        context.read<MapBloc>().add(ClearCategoryMarkers());
      } else {
        print("_onTap: Annotation/Feature tapped. Letting specific listener handle.");
      }

    } catch (e) {
      print("Error during map query or state update in _onTap: $e");
    }
  }

  /// Updates the local status [location] (string) when taken coordinates,
  /// usually from search result through [Searchbloc].
  ///
  /// - [Latitude]: The latitude of the location.
  /// - [Longitude]: The longitudinal length of the location.
  void _onSearchResultReceived(double latitude, double longitude) {
    if (!mounted) return;
    setState(() {
      location = '${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}';
    });
  }


  @override
  /// Builds HomePage's main UI structure.
  ///
  /// regulates [Bloclistener] for [Searchbloc] and [Mapbloc] to handle status changes
  /// and side effects (such as snackbars display or local status update based on bloc events).
  /// places the main elements UI ([Mainmaparea], [LocationInfocard], [Zoomcontrolswidget],
  /// [Startstoptrackingbutton]) within a [stack].
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocListener<SearchBloc, SearchState>(
        listener: (context, state) {
          // Handles status changes from Searchbloc, informing UI accordingly
          /// for search box
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
          }
          /// for geodecoding
          if (state is NameLoaded) {
            if (!mounted) return;
            setState(() { selectedFeature = state.feature; });
            _searchController.text = selectedFeature!.fullAddress;
          } else if (state is NameError) {
            print('Geocoding Error: ${state.message}');
          }
          if (state is CategoryResultsLoaded) {
            context.read<MapBloc>().add(AddCategoryMarkers(state.features, shouldZoomToBounds: true));
          }
        },
        // Listener for Mapbloc bugs that do not handle children Widgets
        child: BlocListener<MapBloc, MapState>(
          listener: (context, mapState){
            if (mapState.trackingStatus == MapTrackingStatus.error && mapState.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(mapState.errorMessage!), backgroundColor: Colors.red)
              );
            }

            if (mapState is MapAnnotationClicked) {
              print("UI Listener: Detected MapAnnotationClicked with ID: ${mapState.mapboxId}");
              context.read<SearchBloc>().add(RetrieveCoordinatesEvent(mapState.mapboxId));
            }
          },
          // Stack main layout contains the map and overlay widgets
          child: Stack(
            children: [
              MainMapArea(
                searchController: _searchController,
                initialCameraOptions: initialCameraOptions,
                styleUri: "mapbox://styles/el03/cm9vbhxcb005901si1bp370nc",
                onMapTap: (gestureContext) => _onTap(gestureContext, context),
                onMapLongTap: (gestureContext) => _onLongTap(gestureContext, context),
              ),

              /// Widgets
              /// Location Info Card
              if (location.isNotEmpty && selectedFeature != null)
                Positioned(
                  left: 0, right: 0, bottom: -10,
                  child: LocationInfoCard(feature: selectedFeature),
                ),
              /// Zoom Controls
              Positioned(
                right: 16, bottom: (location.isNotEmpty) ? 250 : 80,
                child: const ZoomControls(),
              ),
              /// Start/Stop Tracking Button
              Positioned(
                right: 16, bottom: (location.isNotEmpty) ? 190 : 20,
                child: const StartStopTrackingButton(),
              )
            ],
          ),
        ),
      ),
      /// Bottom Navigation Bar
      bottomNavigationBar: const BottomNavBar(),
    );
  }

  // --- Lifecycle Methods ---
  @override
  /// Initialize the situation and registes this object as an observer
  /// of application life cycle events.
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  /// Cleans resources when the widget is removed from the widgets tree.
  /// Writing the Life Circle Observer and release of Text Editing Controller.
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }
// --- /Lifecycle Methods ---

}