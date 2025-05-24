part of '../map_bloc.dart';

extension MapBlocRatings on MapBloc {

  Future<void> _onRateAndSaveRouteRequested(RateAndSaveRouteRequested event,
      Emitter<MapState> emit) async {
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
}