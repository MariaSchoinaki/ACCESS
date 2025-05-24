part of '../map_bloc.dart';

extension MapBlocZoom on MapBloc {
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

      if (state.isNavigating) {
        final bool nowFollowing = !state.isCameraFollowing;

        if (nowFollowing) {
          startCompassListener();
          _changeCamera(0, true);
        } else {
          _compassSubscription.cancel();
          _changeCamera(0, false);
        }

        emit(state.copyWith(isCameraFollowing: nowFollowing));
      } else {
        state.mapController?.flyTo(
          mapbox.CameraOptions(center: point, zoom: 16.0),
          mapbox.MapAnimationOptions(duration: 1000),
        );
      }


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

  Future<void> _onStartTrackingRequested(StartTrackingRequested event, Emitter<MapState> emit) async {
    emit(state.copyWith(
      trackedRoute: [],
      isTracking: true,
      trackingStatus: MapTrackingStatus.loading,
    ));

    await stopLocationListening();
    await startLocationListening(
      onPositionUpdate: (position) {
        if (!state.isTracking) return;
        final updatedRoute = List<geolocator.Position>.from(state.trackedRoute)
          ..add(position);
        emit(state.copyWith(trackedRoute: updatedRoute,
            currentTrackedPositionGetter: () => position));
      },
    );
    emit(state.copyWith(trackingStatus: MapTrackingStatus.tracking));
  }

  Future<void> _onStopTrackingRequested(StopTrackingRequested event, Emitter<MapState> emit) async {
    await _stopTrackingLogic();
    emit(state.copyWith(
      isTracking: false,
      trackingStatus: MapTrackingStatus.stopped,
    ));
    print("Tracking stopped (without rating). Final points: ${state.trackedRoute
        .length}");
  }

  Future<void> _stopTrackingLogic() async {
    print("Stopping location subscription...");
    await _positionSubscription?.cancel();
    _positionSubscription = null;
  }
}