part of '../map_bloc.dart';

extension MapBlocNavigation on MapBloc {
  Future<void> _onStartNavigation(StartNavigationRequested event, Emitter<MapState> emit,) async {
    print("got inn");
    final responseJson = await _fetchRoute(event.feature, event.alternatives);
    final routeObject = responseJson?['route'];
    final route = getRoute(routeObject);
    final List<NavigationStep> routeSteps = route!['routeSteps'];
    await _remove();
    final fixedLineCoordinates = route['coordinates'];
    await _addLine(fixedLineCoordinates, 0, 0);
    emit(state.copyWith(isNavigating: true, currentStepIndex: 0, isCameraFollowing: true, isOffRoute: false, trackedRoute: [], routeSteps: routeSteps));

    await stopLocationListening();
    startCompassListener();
    await startLocationListening(onPositionUpdate: (position) => add(NavigationPositionUpdated(position, event.feature)));
  }


  Future<void> _updateNavigationStep(int newStepIndex, Emitter<MapState> emit) async {
    print("Trying to update step: $newStepIndex");
    print("Current step in state: ${state.currentStepIndex}");

    if (!state.isNavigating || newStepIndex == state.currentStepIndex) return;

    emit(state.copyWith(currentStepIndex: newStepIndex));
    print("Updated step to: $newStepIndex");

    if (state.isVoiceEnabled && newStepIndex < state.routeSteps.length) {
      await flutterTts.speak(state.routeSteps[newStepIndex].instruction);
    }
  }

  Future<void> _onStopNavigation(StopNavigationRequested event, Emitter<MapState> emit,) async {
    add(ShowRouteRatingDialogRequested(state.trackedRoute));
    emit(state.copyWith(
      isNavigating: false,
      routeSteps: [],
      currentStepIndex: 0,
      isCameraFollowing: false,
      lastEvent: null
    ));
    add(RemoveAlternativeRoutes());
    _changeCamera(0, false);
    _compassSubscription.cancel();
  }

  Future<void> _onNavigationPositionUpdated(NavigationPositionUpdated event, Emitter<MapState> emit,) async {
    if (!state.isNavigating || state.routeSteps.isEmpty) return;

    final currentPosition = mapbox.Point(
      coordinates: mapbox.Position(
        event.position.longitude,
        event.position.latitude,
      ),
    );

    int closestStepIndex = 0;
    double minDistance = double.infinity;

    for (int i = 0; i < state.routeSteps.length; i++) {
      final stepPoint = state.routeSteps[i].location;
      final dist = distanceBetweenPoints(currentPosition, stepPoint);
      if (dist < minDistance) {
        minDistance = dist;
        closestStepIndex = i;
      }
    }

    const double offRouteThreshold = 10.0;
    if (minDistance > offRouteThreshold) {
      if(!state.isOffRoute) {
        emit(state.copyWith(isOffRoute: true));
        print("User is off-route! $minDistance meters away");

        final responsejson = await _fetchRoute(event.feature, false);

        if (responsejson != null) {
          const sourceId = 'route-source';
          const layerId = 'route-layer';
          await state.mapController?.style
              .removeStyleLayer(layerId)
              .catchError((_) {});
          await state.mapController?.style
              .removeStyleSource(sourceId)
              .catchError((_) {});
          final routeObject = responsejson['route'];
          final route = getRoute(routeObject);
          final List<NavigationStep> routeSteps = route!['routeSteps'];
          await _remove();
          final fixedLineCoordinates = route['coordinates'];
          await _addLine(fixedLineCoordinates, 0, 0);
          final instruction = "Έχετε αφήσει την πορεία σας. Επιστρέφω σε"
              "${state.routeSteps[closestStepIndex].instruction}";

          if (state.isVoiceEnabled) {
            await flutterTts.speak(instruction);
          }
        } else {
          print("Αδυναμία εύρεσης νέας διαδρομής.");
          if (state.isVoiceEnabled) {
            await flutterTts.speak(
                "Αδυναμία να βρεθεί μια νέα διαδρομή. Προσπαθήστε να επιστρέψετε στην προηγούμενη κατεύθυνση.");
          }
        }
      }
      return;
    }else{
      if (state.isOffRoute) {
        emit(state.copyWith(isOffRoute: false));
        if (state.isVoiceEnabled) {
          await flutterTts.speak("");
        }
      }
    }

    final lastStep = state.routeSteps.last;
    final destinationDistance = distanceBetweenPoints(currentPosition, lastStep.location);

    const double destinationThreshold = 5.0;

    if (destinationDistance <= destinationThreshold) {
      print("User reached destination, stopping navigation...");

      add(StopNavigationRequested());

      if (state.isVoiceEnabled) {
        await flutterTts.speak("Έχετε φτάσει στον προορισμό σας.");
      }
    }

    await _updateNavigationStep(closestStepIndex, emit);
    final updatedTrackedRoute = List<geolocator.Position>.from(state.trackedRoute)
      ..add(event.position);

    emit(state.copyWith(trackedRoute: updatedTrackedRoute));
  }
}
