import 'dart:convert';

import 'package:access/models/navigation_step.dart';
import 'package:access/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

///Bloc Imports
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/favourites_bloc/favourites_cubit.dart';
import '../blocs/map_bloc/map_bloc.dart';
import '../blocs/search_bloc/search_bloc.dart';

import '../models/mapbox_feature.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/bbox.dart';
import '../utils/nearFeatures.dart';
import '../utils/nearest_step.dart';
///Services Imports

///Widget and Theme Imports
import '../widgets/bottom_bar.dart';
import '../widgets/directionsCard.dart';
import '../widgets/location_card.dart';
import '../widgets/navLocCard.dart';
import '../widgets/search_bar.dart' as SB;
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
  MapboxFeature? feature;
  List<NavigationStep> routeInstructions = [];
  bool isNavigating = true;
  double sheetExtent = 0.3;

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
    if (!mounted || mapController == null || context.read<MapBloc>().state.isNavigating) {
      return;
    }

    try {
      
      final screenPoint = gestureContext.touchPosition;
      final state = context.read<MapBloc>().state;
      await Future.delayed(Duration(milliseconds: 1000));
      if (state.lastEvent is ClusterMarkerClicked) {
        print("yeahhh");
        return;
      }
      if (context.read<MapBloc>().state.featureMap.isNotEmpty) {
        await Future.delayed(Duration(milliseconds: 500));
        if (context.read<MapBloc>().state is MapAnnotationClicked){
          return;
        }
      }
      final features = await queryNearbyFeatures(screenPoint, 5, context); // 5 pixel radius

      if (features.isNotEmpty) {
        print("Βρέθηκαν: ${features.length}");
        for (var f in features) {
          print("Layer: ${f.queriedFeature.feature['properties']}");
        }
      } else {
        print("Τίποτα");
      }
      if (features.isEmpty) {
        print("_onTap: Empty space tapped. Clearing selection.");
        if (!mounted) return;

        setState(() { location = ''; selectedFeature = null; });
        _searchController.clear();
        context.read<MapBloc>().add(RemoveAlternativeRoutes());
        context.read<MapBloc>().add(DeleteMarker());
        context.read<MapBloc>().add(ClearCategoryMarkers());
      } else {
            final feature = features.first;
            final rawProps = feature?.queriedFeature.feature['properties'];
            final Map<String, dynamic> properties = Map<String, dynamic>.from(rawProps as Map);

            var geometry = feature?.queriedFeature.feature['geometry'];
            geometry =  Map<String, dynamic>.from(geometry as Map);
            final coords = geometry['coordinates'];

            List<double> coordinates = [];
            if (coords is List) {
            coordinates = coords
            .whereType<num>()
            .map((c) => c.toDouble())
            .toList();
            }
            final category = properties['maki'] ?? 'Άγνωστη κατηγορία';
            final bboxString = await getBbox(context);

            print(bboxString);
            if(category != 'Άγνωστη κατηγορία')
              context.read<SearchBloc>().add(SearchForPoiClicked(category, properties, coordinates, bbox: bboxString));
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

  Widget _buildClusterReportsDialog(BuildContext context, List<Map<String, dynamic>> reports) {
    return AlertDialog(
      title: Text('Αναφορές (${reports.length})'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.6,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: reports.length,
          itemBuilder: (context, index) {
            final report = reports[index];
            return ListTile(
              title: Text(report['locationDescription'] ?? 'Χωρίς περιγραφή'),
              subtitle: Text('${report['timestamp']}\nΣυντεταγμένες: ${report['latitude']}, ${report['longitude']}'),
              onTap: () => _showReportDetails(context, report),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            context.read<MapBloc>().add(HideClusterReports());
          },
          child: Text('Κλείσιμο'),
        )
      ],
    );
  }

  void _showReportDetails(BuildContext context, Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: AlertDialog(
            title: Text(report['obstacleType'] ?? 'Άγνωστος τύπος'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (report['imageUrl'] != null && report['imageUrl'].isNotEmpty)
                    AspectRatio(
                      aspectRatio: 16/9,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          report['imageUrl'],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    report['description'] ?? 'Δεν υπάρχει περιγραφή',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.location_on, report['locationDescription']),
                  _buildInfoRow(Icons.access_time, report['timestamp']),
                  _buildInfoRow(Icons.accessible, report['accessibility']),
                  if (report['userEmail'] != null)
                    _buildInfoRow(Icons.person, report['userEmail']),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Κλείσιμο'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }


  @override
  /// Builds HomePage's main UI structure.
  ///
  /// regulates [Bloclistener] for [Searchbloc] and [Mapbloc] to handle status changes
  /// and side effects (such as snackbars display or local status update based on bloc events).
  /// places the main elements UI ([Mainmaparea], [LocationInfocard], [Zoomcontrolswidget],
  /// [Startstoptrackingbutton]) within a [stack].
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocListener<SearchBloc, SearchState>(
        listener: (context, state) {
          // Handles status changes from Searchbloc, informing UI accordingly
          /// for search box
          if (state is CoordinatesLoaded) {
            selectedFeature = state.feature;
            //feature = state.feature;
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
          if (state is PoiFound){
            print("POI FOUND");
            selectedFeature = state.feature1;
            feature = state.feature2;
            setState(() { location = selectedFeature!.name; });
            print("POI FOUND: ${selectedFeature!.fullAddress}");
            context.read<MapBloc>().add(AddMarker(selectedFeature!.latitude, selectedFeature!.longitude));
          }
        },
        // Listener for Mapbloc bugs that do not handle children Widgets
        child: BlocListener<MapBloc, MapState>(
          listener: (context, mapState) async {

            if (mapState.showClusterReports && mapState.clusterReports != null) {
              _showClusterReports(context, mapState.clusterReports!);

              context.read<MapBloc>().add(HideClusterReports());
            }

            if (mapState.trackingStatus == MapTrackingStatus.error && mapState.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(mapState.errorMessage!), backgroundColor: Colors.red)
              );
            }
            if (routeInstructions != mapState.routeSteps) {
              setState(() {
                routeInstructions = mapState.routeSteps;
              });
            }
            if (mapState is MapAnnotationClicked) {
              print("UI Listener: Detected MapAnnotationClicked with ID: ${mapState.mapboxId}");
              feature = mapState.feature;
              context.read<SearchBloc>().add(RetrieveCoordinatesEvent(mapState.mapboxId));
            }
            final event = mapState.lastEvent;
            if (event is ShowRouteRatingDialogRequested) {
              if (event.trackedRoute.length < 2) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Η διαδρομή είναι πολύ μικρή για βαθμολόγηση.',
                    ),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              final rating = await showRatingDialog(context, event.trackedRoute);

              if (rating != null) {
                context.read<MapBloc>().add(RateAndSaveRouteRequested(route: event.trackedRoute, rating: rating));
              }
              context.read<MapBloc>().add(ShowedMessage());
            }
          },
          child: BlocListener<FavoritesCubit, FavoritesState>(
            listener: (context, state) {
              if (state is FavoritesLoaded) {
                final mapBloc = context.read<MapBloc>();
                if (mapBloc.state.isMapReady) {
                  mapBloc.add(RenderFavoriteAnnotations(state.favorites));
                } else {
                  mapBloc.pendingEvents.add(RenderFavoriteAnnotations(state.favorites));
                }
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

                SafeArea(
                  child: Stack(
                    children: [
                      if (routeInstructions.isEmpty)
                        SB.SearchBar(searchController: _searchController),
                      if (routeInstructions.isNotEmpty)
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          child: DirectionsCard(
                            steps: routeInstructions,
                          ),
                        ),
                    ],
                  ),
                ),
                /// Widgets
                /// Location Info Card
                if (location.isNotEmpty && selectedFeature != null)
                  if(routeInstructions.isEmpty)
                    DraggableScrollableSheet(
                      initialChildSize: 0.3,
                      minChildSize: 0.2,
                      maxChildSize: 0.8,
                      builder: (context, scrollController) {
                        scrollController.addListener(() {
                          final extent = scrollController.position.extentInside /
                              scrollController.position.viewportDimension;
                          if (sheetExtent != extent) {
                            setState(() {
                              sheetExtent = extent;
                            });
                          }
                        });
                        return Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          child: SingleChildScrollView(
                            controller: scrollController,
                            child: LocationInfoCard(
                              feature: selectedFeature,
                              feature2: feature,
                            ),
                          ),
                        );
                      },
                    ),
                if(routeInstructions.isNotEmpty)
                  DraggableScrollableSheet(
                    initialChildSize: 0.3,
                    minChildSize: 0.2,
                    maxChildSize: 0.8,
                    builder: (context, scrollController) {
                      scrollController.addListener(() {
                        final extent = scrollController.position.extentInside /
                            scrollController.position.viewportDimension;
                        if (sheetExtent != extent) {
                          setState(() {
                            sheetExtent = extent;
                          });
                        }
                      });
                      return Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: NavigationInfoBar(title: selectedFeature!.name),
                        ),
                      );
                    },
                  ),
                /// Zoom Controls
                if(location.isEmpty || routeInstructions.isNotEmpty || sheetExtent < 0.5)
                  Positioned(
                    right: 16, bottom: (location.isNotEmpty) ? 250 : 80,
                    child: Opacity(
                      opacity: (sheetExtent < 0.5) ? 1.0 : 0.0,
                      child: const ZoomControls(),
                    ),
                  ),
                  /// Start/Stop Tracking Button
                  Positioned(
                    right: 16, bottom: (location.isNotEmpty) ? 190 : 20,
                    child: Opacity(
                      opacity: (sheetExtent < 0.5) ? 1.0 : 0.0,
                      child: const StartStopTrackingButton(),
                    ),
                  )
              ],
            ),
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MapBloc>().add(LoadClusters());
    });
  }

  void _showClusterReports(BuildContext context, List<Map<String, dynamic>> reports) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Αναφορές (${reports.length})'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return ListTile(
                title: Text(report['locationDescription'] ?? 'Χωρίς περιγραφή'),
                subtitle: Text('${report['timestamp']}\nΣυντεταγμένες: ${report['latitude']}, ${report['longitude']}'),
                onTap: () => _showReportDetails(context, report),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Κλείσιμο'),
          )
        ],
      ),
    );
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