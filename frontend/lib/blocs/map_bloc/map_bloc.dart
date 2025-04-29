import 'dart:async'; // Για StreamSubscription
import 'dart:convert';
import 'dart:math';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart'; // Για ValueGetter
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:permission_handler/permission_handler.dart';
import '../../models/mapbox_feature.dart';

part 'map_event.dart';
part 'map_state.dart';

/// Bloc that manages all map-related events and state using Mapbox
class MapBloc extends Bloc<MapEvent, MapState> {
  late mapbox.PointAnnotationManager? _annotationManager;
  late mapbox.PointAnnotationManager? _categoryAnnotationManager;

  StreamSubscription<geolocator.Position>? _positionSubscription;
  final geolocator.GeolocatorPlatform _geolocator = geolocator.GeolocatorPlatform.instance;

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
    on<ClearCategoryMarkers>(_onClearCategoryMarkers);
    //on<FetchMapRoutes>(...);

    on<StartTrackingRequested>(_onStartTrackingRequested);
    on<StopTrackingRequested>(_onStopTrackingRequested);
    on<_LocationUpdated>(_onLocationUpdated);
  }

  Future<void> _onRequestLocationPermission(RequestLocationPermission event, Emitter<MapState> emit) async {
    await Permission.locationWhenInUse.request();
  }

  Future<void> _onInitializeMap(InitializeMap event, Emitter<MapState> emit) async {
    emit(state.copyWith(mapController: event.mapController));
    _annotationManager = await state.mapController?.annotations.createPointAnnotationManager();
    _categoryAnnotationManager = await state.mapController?.annotations.createPointAnnotationManager();
    add(GetCurrentLocation());
  }

  Future<void> _onGetCurrentLocation(GetCurrentLocation event, Emitter<MapState> emit) async {
    try {
      var status = await Permission.locationWhenInUse.status;
      if (!status.isGranted && !status.isLimited) {
        print("GetCurrentLocation: Permission not granted. Requesting...");
        status = await Permission.locationWhenInUse.request();
        if (!status.isGranted && !status.isLimited) {
          print("GetCurrentLocation: Permission denied after request.");
          emit(state.copyWith(errorMessageGetter: () => 'Απαιτείται άδεια τοποθεσίας.'));
          return;
        }
      }

      final position = await _geolocator.getCurrentPosition();
      final point = mapbox.Point(coordinates: mapbox.Position(position.longitude, position.latitude));

      state.mapController?.flyTo(
        mapbox.CameraOptions(center: point, zoom: 16.0),
        mapbox.MapAnimationOptions(duration: 1000),
      );
      emit(state.copyWith(zoomLevel: 16.0));

      //
      // await state.mapController?.style.addSource(...);

    } catch (e) {
      print("Error getting current location: $e");
      emit(state.copyWith(errorMessageGetter: () => 'Αδυναμία λήψης τρέχουσας τοποθεσίας: $e'));
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
    final point = mapbox.Point(coordinates: mapbox.Position(event.longitude, event.latitude));
    state.mapController?.flyTo(
      mapbox.CameraOptions(center: point, zoom: 16.0),
      mapbox.MapAnimationOptions(duration: 1000),
    );
    // emit(state.copyWith(zoomLevel: 16.0));
  }

  Future<void> _onAddMarker(AddMarker event, Emitter<MapState> emit) async {
    final map = state.mapController;
    if (map == null || _annotationManager == null) return;
    try {
      final bytes = await rootBundle.load('assets/images/pin.png');
      final imageData = bytes.buffer.asUint8List();
      final point = mapbox.Point(coordinates: mapbox.Position(event.longitude, event.latitude));
      await _annotationManager!.deleteAll();
      await _annotationManager!.create(
        mapbox.PointAnnotationOptions(
          geometry: point, iconSize: 0.5, image: imageData, iconAnchor: mapbox.IconAnchor.BOTTOM,
        ),
      );
    } catch (e) {
      print("Error adding marker: $e");
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
      final List<mapbox.PointAnnotationOptions> optionsList = [];
      double? minLat, maxLat, minLng, maxLng;

      for (final feature in event.features) {
        final point = mapbox.Point(coordinates: mapbox.Position(feature.longitude, feature.latitude));
        optionsList.add(mapbox.PointAnnotationOptions(
          geometry: point, iconSize: 0.4, image: imageData, iconAnchor: mapbox.IconAnchor.BOTTOM, textField: feature.name,
        ));

        final lat = feature.latitude; final lng = feature.longitude;
        minLat = minLat == null ? lat : min(minLat, lat); maxLat = maxLat == null ? lat : max(maxLat, lat);
        minLng = minLng == null ? lng : min(minLng, lng); maxLng = maxLng == null ? lng : max(maxLng, lng);
      }
      final createdAnnotations = await _categoryAnnotationManager!.createMulti(optionsList);

      emit(state.copyWith(categoryAnnotations: Set.from(createdAnnotations))); // Ενημερωμένο

      if (event.shouldZoomToBounds && minLat != null && maxLat != null && minLng != null && maxLng != null) {
        final southwest = mapbox.Point(coordinates: mapbox.Position(minLng, minLat));
        final northeast = mapbox.Point(coordinates: mapbox.Position(maxLng, maxLat));
        final bounds = mapbox.CoordinateBounds(southwest: southwest, northeast: northeast, infiniteBounds: false); // infiniteBounds=false είναι πιο λογικό
        final cameraOptions = await map.cameraForCoordinateBounds(
          bounds, mapbox.MbxEdgeInsets(top: 50.0, left: 50.0, bottom: 50.0, right: 50.0,), 0.0, 0.0, null, null,);
        if (cameraOptions != null) {
          map.flyTo(cameraOptions, mapbox.MapAnimationOptions(duration: 1000));
        }
      }
    } catch (e) {
      print("Error adding category markers: $e");
    }
  }

  Future<void> _onClearCategoryMarkers(ClearCategoryMarkers event, Emitter<MapState> emit) async {
    await _categoryAnnotationManager?.deleteAll();
    emit(state.copyWith(categoryAnnotations: {}));
  }

  Future<void> _onStartTrackingRequested(
      StartTrackingRequested event, Emitter<MapState> emit) async {
    // 1. Check for permission
    final permissionStatus = await Permission.locationWhenInUse.request();

    if (permissionStatus.isGranted || permissionStatus.isLimited) {
      // 2. Preparation & Start Stream
      emit(state.copyWith(
        trackingStatus: MapTrackingStatus.loading,
        trackedRoute: [], // cleaning
        currentTrackedPositionGetter: () => null,
        isTracking: false, // We make sure it's not already true
        errorMessageGetter: () => null,
      ));

      await _stopTrackingLogic(); // Stop any previous subscription

      const locationSettings = geolocator.LocationSettings(
        accuracy: geolocator.LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters
      );

      try {
        _positionSubscription = _geolocator
            .getPositionStream(locationSettings: locationSettings)
            .handleError((error) {
          print("Error in location stream: $error");
          add(StopTrackingRequested());
          emit(state.copyWith(
              trackingStatus: MapTrackingStatus.error,
              isTracking: false, // Stopped due to error
              errorMessageGetter: () => 'Σφάλμα ροής τοποθεσίας: $error'));
        })
            .listen((geolocator.Position position) {
          add(_LocationUpdated(position)); // We send an event for each new position
        });

        emit(state.copyWith(
          isTracking: true,
          trackingStatus: MapTrackingStatus.tracking,
        ));
        print("Tracking started...");
      } catch (e) {
        print("Error starting location stream: $e");
        await _stopTrackingLogic();
        emit(state.copyWith(
            trackingStatus: MapTrackingStatus.error,
            isTracking: false,
            errorMessageGetter: () => 'Αδυναμία έναρξης παρακολούθησης: $e'));
      }

    } else {
      // Permission was not given
      print("Location permission denied for tracking.");
      emit(state.copyWith(
          trackingStatus: MapTrackingStatus.error,
          errorMessageGetter: () => 'Απαιτείται άδεια τοποθεσίας για την έναρξη καταγραφής.'));
    }
  }

  void _onLocationUpdated(_LocationUpdated event, Emitter<MapState> emit) {
    if (!state.isTracking) return; // We ignore updates if we don't do tracking

    final updatedRoute = List<geolocator.Position>.from(state.trackedRoute)
      ..add(event.newPosition);

    emit(state.copyWith(
      currentTrackedPositionGetter: () => event.newPosition,
      trackedRoute: updatedRoute,
      // trackingStatus: MapTrackingStatus.tracking,
    ));
    // print("Tracked route points: ${updatedRoute.length}");
  }

  Future<void> _onStopTrackingRequested(
      StopTrackingRequested event, Emitter<MapState> emit) async {
    await _stopTrackingLogic();
    emit(state.copyWith(
      isTracking: false,
      trackingStatus: MapTrackingStatus.stopped,
    ));
    print("Tracking stopped. Final points: ${state.trackedRoute.length}");
    ///TODO: send/save the state.trackedRoute
  }

  Future<void> _stopTrackingLogic() async {
    print("Stopping location subscription...");
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  // Cleaning Subscription when bloc is destroyed
  @override
  Future<void> close() {
    print("Closing MapBloc, cancelling subscription...");
    _positionSubscription?.cancel();
    return super.close();
  }

}