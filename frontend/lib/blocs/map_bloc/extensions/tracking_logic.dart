part of '../map_bloc.dart';

extension MapBlocLocation on MapBloc {

  Future<void> startLocationListening({required Function(geolocator.Position) onPositionUpdate}) async {
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
    }
  }

  Future<void> stopLocationListening() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
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
}
