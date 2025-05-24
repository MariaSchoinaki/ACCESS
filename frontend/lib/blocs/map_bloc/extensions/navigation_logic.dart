part of '../map_bloc.dart';

extension MapBlocNavigation on MapBloc {
  Future<void> _onStartNavigation(StartNavigationRequested event, Emitter<MapState> emit,) async {
    final responseJson = await _fetchRoute(event.feature, event.alternatives);
    await _displayRoute(responseJson!, emit);
    emit(state.copyWith(isNavigating: true, currentStepIndex: 0, isCameraFollowing: true, isOffRoute: false));

    await stopLocationListening();
    startCompassListener();
    flutterTts.speak("run boy run");
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
    emit(state.copyWith(
      isNavigating: false,
      routeSteps: [],
      currentStepIndex: 0,
      isCameraFollowing: false,
    ));
    const sourceId = 'route-source';
    const layerId = 'route-layer';
    await state.mapController?.style.removeStyleLayer(layerId).catchError((_) {});
    await state.mapController?.style.removeStyleSource(sourceId).catchError((_) {});
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
          await _displayRoute(responsejson, emit);

          final instruction = "You have left your course. Return to "
              "${state.routeSteps[closestStepIndex].instruction}";

          if (state.isVoiceEnabled) {
            await flutterTts.speak(instruction);
          }
        } else {
          print("Αδυναμία εύρεσης νέας διαδρομής.");
          if (state.isVoiceEnabled) {
            await flutterTts.speak(
                "Inability to find a new route. Try to go back to the previous direction.");
          }
        }
      }
      return;
    }else{
      if (state.isOffRoute) {
        emit(state.copyWith(isOffRoute: false));
        if (state.isVoiceEnabled) {
          await flutterTts.speak("welcome back bitches");
        }
      }
    }

    await _updateNavigationStep(closestStepIndex, emit);
  }
}
