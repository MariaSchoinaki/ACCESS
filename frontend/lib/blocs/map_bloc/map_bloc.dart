import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/mapbox_feature.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/navigation_step.dart';
import '../../utils/nearest_step.dart';
import '../../utils/point_annotation_click_listener.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_tts/flutter_tts.dart';

part 'map_event.dart';
part 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  late mapbox.PointAnnotationManager? _annotationManager;
  late mapbox.PointAnnotationManager? _categoryAnnotationManager;
  late List<mapbox.PointAnnotation?> createdAnnotations;
  StreamSubscription<geolocator.Position>? _positionSubscription;

  final geolocator.GeolocatorPlatform _geolocator = geolocator.GeolocatorPlatform.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterTts flutterTts = FlutterTts();

  MapBloc() : super(MapState.initial()) {
    on<RequestLocationPermission>(_onRequestLocationPermission);
    on<InitializeMap>(_onInitializeMap);
    on<GetCurrentLocation>(_onGetCurrentLocation);
    on<ZoomIn>(_onZoomIn);
    on<ZoomOut>(_onZoomOut);
    on<FlyTo>(_onFlyTo);
    on<AddMarker>(_onAddMarker);
    on<DeleteMarker>(_onDeleteMarker);
    on<AddCategoryMarkers>(_onAddCategoryMarkers);
    on<_AnnotationClickedInternal>(_onAnnotationClickedInternal);
    on<ClearCategoryMarkers>(_onClearCategoryMarkers);

    on<StartTrackingRequested>(_onStartTrackingRequested);
    on<StopTrackingRequested>(_onStopTrackingRequested);
    on<_LocationUpdated>(_onLocationUpdated);
    on<RateAndSaveRouteRequested>(_onRateAndSaveRouteRequested);
    on<DisplayRouteFromJson>(_onDisplayRouteFromJson);
    on<DisplayAlternativeRoutesFromJson>(_onDisplayAlternativeRoutesFromJson);

    on<ShareLocationRequested>(_onShareLocation);
    on<LaunchPhoneDialerRequested>(_onLaunchPhoneDialer);
    on<StartNavigationRequested>(_onStartNavigation);
    on<StopNavigationRequested>(_onStopNavigation);
    on<ToggleVoiceInstructions>((event, emit) {
      emit(state.copyWith(isVoiceEnabled: !state.isVoiceEnabled));
    });

  }

  Future<void> _onRequestLocationPermission(RequestLocationPermission event, Emitter<MapState> emit) async {
    await Permission.locationWhenInUse.request();
  }

  Future<void> initTTS() async {
    await flutterTts.setLanguage("en-US");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1.0);
  }

  Future<void> _onInitializeMap(InitializeMap event, Emitter<MapState> emit) async {
    emit(state.copyWith(mapController: event.mapController));
    _annotationManager = await state.mapController?.annotations.createPointAnnotationManager(id: 'tapped-layer');
    _categoryAnnotationManager = await state.mapController?.annotations.createPointAnnotationManager(id: 'categories-layer');

    if (_categoryAnnotationManager != null) {
      _categoryAnnotationManager!.addOnPointAnnotationClickListener(
          PointAnnotationClickListener(
              onAnnotationClick: (mapbox.PointAnnotation annotation) {
                final String internalId = annotation.id;
                final String? mapboxId = state.annotationIdMap[internalId];
                final MapboxFeature? feature = state.featureMap[mapboxId];
                //annotation.iconImage = 'assets/images/blue_pin.png';
                //annotation.iconSize = 0.8;
                if (mapboxId != null && mapboxId.isNotEmpty) {
                  add(_AnnotationClickedInternal(mapboxId, feature!));
                } else {
                  print("!!! MapBloc: mapboxId not found in map or is empty for internal ID $internalId, SKIPPING event add.");
                }
              }));
      print("[MapBloc] Annotation click listener added.");
    }

    add(GetCurrentLocation());
    initTTS();
  }

  Future<void> _onGetCurrentLocation(GetCurrentLocation event, Emitter<MapState> emit) async {
    try {
      var status = await Permission.locationWhenInUse.status;
      if (!status.isGranted && !status.isLimited) {
        print("GetCurrentLocation: Permission not granted. Requesting...");
        status = await Permission.locationWhenInUse.request();
        if (!status.isGranted && !status.isLimited) {
          print("GetCurrentLocation: Permission denied after request.");
          emit(state.copyWith(
              errorMessageGetter: () => 'Απαιτείται άδεια τοποθεσίας.'));
          return;
        }
      }

      final position = await _geolocator.getCurrentPosition();
      final point = mapbox.Point(
          coordinates: mapbox.Position(position.longitude, position.latitude));

      state.mapController?.flyTo(
        mapbox.CameraOptions(center: point, zoom: 16.0),
        mapbox.MapAnimationOptions(duration: 1000),
      );
      emit(state.copyWith(zoomLevel: 16.0));
    } catch (e) {
      print("Error getting current location: $e");
      emit(state.copyWith(
          errorMessageGetter: () => 'Αδυναμία λήψης τρέχουσας τοποθεσίας: $e'));
    }
  }

  Future<void> _onZoomIn(ZoomIn event, Emitter<MapState> emit) async {
    final currentZoom = await state.mapController?.getCameraState();
    final newZoom = (currentZoom?.zoom ?? state.zoomLevel) + 1;
    state.mapController?.flyTo(
      mapbox.CameraOptions(zoom: newZoom),
      mapbox.MapAnimationOptions(duration: 500),
    );
    emit(state.copyWith(zoomLevel: newZoom));
  }

  Future<void> _onZoomOut(ZoomOut event, Emitter<MapState> emit) async {
    final currentZoom = await state.mapController?.getCameraState();
    final newZoom = (currentZoom?.zoom ?? state.zoomLevel) - 1;
    state.mapController?.flyTo(
      mapbox.CameraOptions(zoom: newZoom),
      mapbox.MapAnimationOptions(duration: 500),
    );
    emit(state.copyWith(zoomLevel: newZoom));
  }

  Future<void> _onFlyTo(FlyTo event, Emitter<MapState> emit) async {
    final point = mapbox.Point(
        coordinates: mapbox.Position(event.longitude, event.latitude));
    state.mapController?.flyTo(
      mapbox.CameraOptions(center: point, zoom: 16.0),
      mapbox.MapAnimationOptions(duration: 1000),
    );
  }

  Future<void> _onAddMarker(AddMarker event, Emitter<MapState> emit) async {
    final map = state.mapController;
    if (map == null || _annotationManager == null) return;
    if(state is! MapAnnotationClicked) {
      try {
        final bytes = await rootBundle.load('assets/images/pin.png');
        final imageData = bytes.buffer.asUint8List();
        final point = mapbox.Point(
            coordinates: mapbox.Position(event.longitude, event.latitude));

        await _annotationManager!.deleteAll();
        await _annotationManager!.create(
          mapbox.PointAnnotationOptions(
            geometry: point,
            iconSize: 0.5,
            image: imageData,
            iconAnchor: mapbox.IconAnchor.BOTTOM,
          ),
        );
      } catch (e) {
        print("Error adding marker: $e");
      }
    }
  }

  Future<void> _onDeleteMarker(DeleteMarker event, Emitter<MapState> emit) async {
    await _annotationManager?.deleteAll();
  }

  Future<void> _onAddCategoryMarkers(AddCategoryMarkers event, Emitter<MapState> emit) async {
    final map = state.mapController;
    if (map == null || _categoryAnnotationManager == null) return;

    try {
      final bytes = await rootBundle.load('assets/images/pin.png');
      final imageData = bytes.buffer.asUint8List();
      List<mapbox.PointAnnotationOptions> optionsList = [];
      double? minLat, maxLat, minLng, maxLng;

      for (final feature in event.features) {
        var point = mapbox.Point(
            coordinates: mapbox.Position(feature.longitude, feature.latitude));
        optionsList.add(mapbox.PointAnnotationOptions(
          geometry: point,
          iconSize: 0.4,
          image: imageData,
          iconAnchor: mapbox.IconAnchor.BOTTOM_LEFT,
          textField: feature.name,
          textSize: 10,
          textMaxWidth: 15,
        ));


        final lat = feature.latitude;
        final lng = feature.longitude;
        minLat = minLat == null ? lat : min(minLat, lat);
        maxLat = maxLat == null ? lat : max(maxLat, lat);
        minLng = minLng == null ? lng : min(minLng, lng);
        maxLng = maxLng == null ? lng : max(maxLng, lng);
      }
      await _categoryAnnotationManager!.deleteAll();
      createdAnnotations = await _categoryAnnotationManager!.createMulti(optionsList);

      final Map<String, String> idMap = {};
      final Map<String, MapboxFeature> featureMap = {};
      if (createdAnnotations.length == event.features.length) {
        for (int i = 0; i < createdAnnotations.length; i++) {
          final internalId = createdAnnotations[i]!.id;
          final String correctMapboxId = event.features[i].id;
          final MapboxFeature feature = event.features[i];
          if (correctMapboxId.isNotEmpty) {
            idMap[internalId] = correctMapboxId;
            featureMap[correctMapboxId] = feature;
            print("Mapping internal ID: $internalId -> mapboxId: $correctMapboxId"); // Debug
          }
        }
      } else {
        print("Warning: Mismatch between created annotations and input features count.");
      }

      emit(state.copyWith(categoryAnnotations: Set.from(createdAnnotations), annotationIdMap: idMap, featureMap: featureMap));


      if (event.shouldZoomToBounds && minLat != null && maxLat != null &&
          minLng != null && maxLng != null) {
        final southwest = mapbox.Point(
            coordinates: mapbox.Position(minLng, minLat));
        final northeast = mapbox.Point(
            coordinates: mapbox.Position(maxLng, maxLat));
        final bounds = mapbox.CoordinateBounds(
            southwest: southwest, northeast: northeast, infiniteBounds: false);

        final cameraOptions = await map.cameraForCoordinateBounds(
          bounds,
          mapbox.MbxEdgeInsets(top: 50.0, left: 50.0, bottom: 50.0, right: 50.0),
          0.0, 0.0, null, null,
        );

        if (cameraOptions != null) {
          map.flyTo(cameraOptions, mapbox.MapAnimationOptions(duration: 1000));
        }
      }
    } catch (e) {
      print("Error adding category markers: $e");
    }
  }

  void _onAnnotationClickedInternal(_AnnotationClickedInternal event, Emitter<MapState> emit) {
    emit(MapAnnotationClicked(event.mapboxId, event.feature, state));
  }

  Future<void> _onClearCategoryMarkers(ClearCategoryMarkers event, Emitter<MapState> emit) async {
    await _categoryAnnotationManager?.deleteAll();
    emit(state.copyWith(categoryAnnotations: {}));
  }

  Future<void> _onStartTrackingRequested(StartTrackingRequested event, Emitter<MapState> emit) async {
    emit(state.copyWith(
      trackedRoute: [],
      isTracking: true,
      trackingStatus: MapTrackingStatus.loading,
    ));

    await stopLocationListening(); // αν έχει προηγούμενο
    await startLocationListening(
      emit: emit,
      onPositionUpdate: (position) {
        if (!state.isTracking) return;
        final updatedRoute = List<geolocator.Position>.from(state.trackedRoute)..add(position);
        emit(state.copyWith(trackedRoute: updatedRoute, currentTrackedPositionGetter: () => position));
      },
    );
    emit(state.copyWith(trackingStatus: MapTrackingStatus.tracking));
  }

  void _onLocationUpdated(_LocationUpdated event, Emitter<MapState> emit) {
    if (!state.isTracking) return;
    final updatedRoute = List<geolocator.Position>.from(state.trackedRoute)
      ..add(event.newPosition);
    emit(state.copyWith(
      currentTrackedPositionGetter: () => event.newPosition,
      trackedRoute: updatedRoute,
    ));
  }

  Future<void> _onStopTrackingRequested(StopTrackingRequested event, Emitter<MapState> emit) async {
    await _stopTrackingLogic();
    emit(state.copyWith(
      isTracking: false,
      trackingStatus: MapTrackingStatus.stopped,
    ));
    print("Tracking stopped (without rating). Final points: ${state.trackedRoute.length}");
  }

  Future<void> _onRateAndSaveRouteRequested(RateAndSaveRouteRequested event, Emitter<MapState> emit) async {
    await _stopTrackingLogic();

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print("User not logged in, cannot save rated route.");
      emit(state.copyWith(
        isTracking: false,
        trackingStatus: MapTrackingStatus.error,
        errorMessageGetter: () => 'User not logged in to save route.',
      ));
      return;
    }

    try {
      print("Saving rated route to Firestore for user ${currentUser.uid}...");

      final List<Map<String, dynamic>> routeForFirestore = event.route.map((
          pos) =>
      {
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'altitude': pos.altitude,
        'accuracy': pos.accuracy,
        'speed': pos.speed,
        'timestamp': pos.timestamp?.toIso8601String(),
      }).toList();

      final Map<String, dynamic> ratedRouteData = {
        'userId': currentUser.uid,
        'userEmail': currentUser.email,
        'rating': event.rating,
        'routePoints': routeForFirestore,
        'pointCount': event.route.length,
        'createdAt': FieldValue.serverTimestamp(),
        'needsUpdate': true,
      };

      await _firestore.collection('rated_routes').add(ratedRouteData);
      print("Rated route saved successfully!");

      emit(state.copyWith(
        isTracking: false,
        trackingStatus: MapTrackingStatus.stopped,
        errorMessageGetter: () => null,
      ));
    } catch (e) {
      print("Error saving rated route: $e");
      emit(state.copyWith(
        isTracking: false,
        trackingStatus: MapTrackingStatus.error,
        errorMessageGetter: () => 'Failed to save rated route: $e',
      ));
    }
  }

  Future<void> _stopTrackingLogic() async {
    print("Stopping location subscription...");
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  @override
  Future<void> close() {
    print("Closing MapBloc, cancelling subscription...");
    _positionSubscription?.cancel();
    return super.close();
  }

  Future<void> _onDisplayRouteFromJson(DisplayRouteFromJson event, Emitter<MapState> emit) async {
    try {
      final map = state.mapController;
      if (map == null) {
        emit(state.copyWith(errorMessageGetter: () => 'Map controller not ready'));
        return;
      }

      final routeObject = event.routeJson['route'];
      print(jsonEncode(event.routeJson));

      if (routeObject == null || routeObject['coordinates'] == null || routeObject['coordinates'] is! List) {
        emit(state.copyWith(errorMessageGetter: () => 'Route data is invalid'));
        return;
      }

      final coordinates = routeObject['coordinates'] as List;

      final fixedLineCoordinates = coordinates.map<List<double>>((c) {
        if (c is List && c.length >= 2) {
          return [c[1].toDouble(), c[0].toDouble()]; // lat, lng για Mapbox
        } else {
          throw Exception('Invalid coordinate format');
        }
      }).toList();

      // === Extract instructions from steps ===
      final instructionsList = routeObject['instructions'];

      final List<NavigationStep> routeSteps = [];

      if (instructionsList is List) {
        for (final step in instructionsList) {
          try {
            routeSteps.add(NavigationStep.fromJson(step as Map<String, dynamic>));
          } catch (_) {}
        }
      }

      final geojson = {
        "type": "FeatureCollection",
        "features": [
          {
            "type": "Feature",
            "geometry": {
              "type": "LineString",
              "coordinates": fixedLineCoordinates,
            },
            "properties": {}
          }
        ]
      };

      const sourceId = 'route-source';
      const layerId = 'route-layer';

      final style = map.style;

      // Remove old layers/sources if they exist
      await style.removeStyleLayer(layerId).catchError((_) {});
      await style.removeStyleSource(sourceId).catchError((_) {});

      // Add the new GeoJSON source
      await style.addSource(
        mapbox.GeoJsonSource(
          id: sourceId,
          data: jsonEncode(geojson),
        ),
      );

      // Add the line layer
      await style.addLayer(
        mapbox.LineLayer(
          id: layerId,
          sourceId: sourceId,
          lineColor: Colors.blue.value,
          lineWidth: 4.0,
          lineJoin: mapbox.LineJoin.ROUND,
          lineCap: mapbox.LineCap.ROUND,
        ),
      );

      print(routeSteps);
      emit(state.copyWith(
        errorMessageGetter: () => null,
        routeSteps: routeSteps,
      ));
      add(StartNavigationRequested());
    } catch (e) {
      emit(state.copyWith(errorMessageGetter: () => 'Error displaying route: $e'));
    }
  }

  Future<void> _onDisplayAlternativeRoutesFromJson(DisplayAlternativeRoutesFromJson event, Emitter<MapState> emit,) async {
    try {
      final map = state.mapController;
      if (map == null) {
        emit(state.copyWith(errorMessageGetter: () => 'Map controller not ready'));
        return;
      }

      final style = map.style;

      for (int i = 0; i < event.routes.length; i++) {
        final sourceId = 'alt-route-source-$i';
        final layerId = 'alt-route-layer-$i';
        await style.removeStyleLayer(layerId).catchError((_) {});
        await style.removeStyleSource(sourceId).catchError((_) {});
      }

      final List<int> routeColors = [
        Colors.blue.value,
        Colors.green.value,
        Colors.red.value,
        Colors.orange.value,
        Colors.purple.value,
      ];

      for (int i = 0; i < event.routes.length; i++) {
        final route = event.routes[i];

        final fixedRoute = route.map((point) {
          if (point.length >= 2) {
            return [point[1], point[0]]; // lng, lat
          }
          throw Exception('Invalid point format');
        }).toList();

        final geojson = {
          "type": "FeatureCollection",
          "features": [
            {
              "type": "Feature",
              "geometry": {
                "type": "LineString",
                "coordinates": fixedRoute,
              },
              "properties": {}
            }
          ]
        };

        final sourceId = 'alt-route-source-$i';
        final layerId = 'alt-route-layer-$i';

        await style.addSource(
          mapbox.GeoJsonSource(
            id: sourceId,
            data: jsonEncode(geojson),
          ),
        );

        await style.addLayer(
          mapbox.LineLayer(
            id: layerId,
            sourceId: sourceId,
            lineColor: routeColors[i % routeColors.length],
            lineWidth: 4.0,
            lineJoin: mapbox.LineJoin.ROUND,
            lineCap: mapbox.LineCap.ROUND,
          ),
        );
      }

      emit(state.copyWith(errorMessageGetter: () => null));
    } catch (e) {
      emit(state.copyWith(errorMessageGetter: () => 'Error displaying alternative routes: $e'));
    }
  }

  Future<void> _onShareLocation(ShareLocationRequested event, Emitter<MapState> emit,) async {
    try {
      final encodedLocation = Uri.encodeComponent(event.location);
      final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$encodedLocation';
      await launchUrl(Uri.parse(googleMapsUrl));
      emit(ActionCompleted());
    } catch (e) {
      emit(ActionFailed("Αποτυχία διαμοιρασμού τοποθεσίας"));
    }
  }

  Future<void> _onLaunchPhoneDialer(LaunchPhoneDialerRequested event, Emitter<MapState> emit,) async {
    try {
      final Uri launchUri = Uri(
        scheme: 'tel',
        path: event.phoneNumber,
      );
      await launchUrl(launchUri);
      emit(ActionCompleted());
    } catch (e) {
      emit(ActionFailed("Αποτυχία κλήσης τηλεφώνου"));
    }
  }

  Future<void> _onStartNavigation(StartNavigationRequested event, Emitter<MapState> emit,) async {
    emit(state.copyWith(isNavigating: true, currentStepIndex: 0));

    await stopLocationListening();
    startCompassListener();
    flutterTts.speak("run boy run");
    await startLocationListening(
      emit: emit,
      onPositionUpdate: (position) {
        if (!state.isNavigating || state.routeSteps.isEmpty) return;

        int closestStepIndex = 0;
        double minDistance = double.infinity;
        for (int i = 0; i < state.routeSteps.length; i++) {
          final stepPoint = state.routeSteps[i].location;
          final dist = distanceBetweenPoints(mapbox.Point(coordinates: mapbox.Position(position.longitude, position.latitude)), stepPoint);
          if (dist < minDistance) {
            minDistance = dist;
            closestStepIndex = i;
          }
        }
        _updateNavigationStep(closestStepIndex, emit);
      },
    );
  }

  Future<void> _updateNavigationStep(int newStepIndex, Emitter<MapState> emit) async {
    if (!state.isNavigating || newStepIndex == state.currentStepIndex) return;

    emit(state.copyWith(currentStepIndex: newStepIndex));

    if (state.isVoiceEnabled && newStepIndex < state.routeSteps.length) {
      await flutterTts.speak(state.routeSteps[newStepIndex].instruction);
    }
  }

  Future<void> _changeCamera(double heading) async {
    final point = await geolocator.Geolocator.getCurrentPosition();
    final pitch = state.isNavigating ? 60.0 : 0.0;
    final zoom = state.isNavigating ? 20.0 : 16.0;
    state.mapController?.easeTo(
      mapbox.CameraOptions(
        center: mapbox.Point(coordinates: mapbox.Position(point.longitude, point.latitude)),
        bearing: heading,
        zoom: zoom,
        pitch: pitch,
      ),
      mapbox.MapAnimationOptions(duration: 300),
    );
  }

  void startCompassListener() {
    FlutterCompass.events!.listen((event) {
      final double? heading = event.heading;
      if (heading == null) return;
      _changeCamera(heading);
    });
  }

  Future<void> _onStopNavigation(StopNavigationRequested event, Emitter<MapState> emit,) async {
    emit(state.copyWith(
      isNavigating: false,
      routeSteps: [],
      currentStepIndex: 0,
    ));
    const sourceId = 'route-source';
    const layerId = 'route-layer';
    await state.mapController?.style.removeStyleLayer(layerId).catchError((_) {});
    await state.mapController?.style.removeStyleSource(sourceId).catchError((_) {});
    final point = await geolocator.Geolocator.getCurrentPosition();
    _changeCamera(point.heading);
  }




  Future<void> startLocationListening({required Function(geolocator.Position) onPositionUpdate, required Emitter<MapState> emit,}) async {
    final permissionStatus = await Permission.locationWhenInUse.request();
    if (permissionStatus.isGranted || permissionStatus.isLimited) {
      const locationSettings = geolocator.LocationSettings(
        accuracy: geolocator.LocationAccuracy.high,
        distanceFilter: 5,
      );
      try {
        _positionSubscription = geolocator.Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).handleError((error) {
          print("Error in location stream: $error");
          _positionSubscription?.cancel();
          // Προαιρετικά: emit σφάλμα
        }).listen((position) {
          onPositionUpdate(position);
        });
        print("Location listening started...");
      } catch (e) {
        print("Error starting location stream: $e");
        _positionSubscription?.cancel();
      }
    } else {
      print("Location permission denied");
      // Προαιρετικά: emit σφάλμα
    }
  }

  Future<void> stopLocationListening() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

}
