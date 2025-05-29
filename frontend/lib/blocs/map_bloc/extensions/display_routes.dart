part of '../map_bloc.dart';

extension MapBlocDisplay on MapBloc {
  Future<Map<String, dynamic>?> _fetchRoute(
    MapboxFeature feature,
    bool alternatives,
  ) async {
    if (feature == null) {
      print("Attempted to navigate but feature was null.");
      return null;
    }

    try {
      final position = await geolocator.Geolocator.getCurrentPosition(
        desiredAccuracy: geolocator.LocationAccuracy.high,
      ).timeout(const Duration(seconds: 10));

      // Call the API with `alternatives` query param
      final responseJson = await mapService.getRoutesJson(
        fromLat: position.latitude,
        fromLng: position.longitude,
        toLat: feature.latitude,
        toLng: feature.longitude,
        alternatives: alternatives,
      );

      print("Response JSON: $responseJson");
      if (alternatives) {
        // Extract all routes
        final List<List<List<double>>> alternativeRoutes = [];

        final routes = responseJson['routes'] as List<dynamic>?;

        if (routes != null) {
          for (var route in routes) {
            final coordinates = route['coordinates'] as List<dynamic>?;
            if (coordinates != null) {
              alternativeRoutes.add(
                coordinates.map<List<double>>((point) {
                  if (point is List && point.length >= 2) {
                    return [point[0].toDouble(), point[1].toDouble()];
                  } else {
                    throw Exception('Unexpected point format: $point');
                  }
                }).toList(),
              );
            }
          }
        }
      }
      return responseJson;
    } catch (e) {
      print("Navigation error: $e");
    }
    return null;
  }

  Map<dynamic, dynamic>? getRoute(dynamic routeObject) {
    if (routeObject == null ||
        routeObject['coordinates'] == null ||
        routeObject['coordinates'] is! List) {
      emit(state.copyWith(errorMessageGetter: () => 'Route data is invalid'));
      return null;
    }

    final coordinates = routeObject['coordinates'] as List;

    final fixedLineCoordinates =
        coordinates.map<List<double>>((c) {
          if (c is List && c.length >= 2) {
            return [c[1].toDouble(), c[0].toDouble()]; // lat, lng για Mapbox
          } else {
            throw Exception('Invalid coordinate format');
          }
        }).toList();

    // === Extract instructions from steps ===
    final instructionsList = routeObject['instructions'];
    final accessibilityScore = routeObject['accessibilityScore'];
    final colorHex = routeObject['color'];
    final List<NavigationStep> routeSteps = [];

    if (instructionsList is List) {
      for (final step in instructionsList) {
        try {
          routeSteps.add(NavigationStep.fromJson(step as Map<String, dynamic>));
        } catch (_) {}
      }
    }
    return {
      'coordinates': fixedLineCoordinates,
      'routeSteps': routeSteps,
      'accessibilityScore': accessibilityScore,
      'color': colorHex,
    };
  }

  Future<void> _displayRoute(
    Map<String, dynamic> responseJson,
    Emitter<MapState> emit,
  ) async {
    try {
      final map = state.mapController;
      if (map == null) {
        emit(
          state.copyWith(errorMessageGetter: () => 'Map controller not ready'),
        );
        return;
      }

      final routeObject = responseJson['route'];
      final route = getRoute(routeObject);
      final List<NavigationStep> routeSteps = route!['routeSteps'];
      final fixedLineCoordinates = route['coordinates'];
      final accessibilityScore = route['accessibilityScore'];
      final colorHex = route['color'];
      await _remove();
      await _addLine(fixedLineCoordinates, 0, null);

      print(routeSteps);
      emit(
        state.copyWith(errorMessageGetter: () => null, routeSteps: routeSteps),
      );
    } catch (e) {
      emit(
        state.copyWith(errorMessageGetter: () => 'Error displaying route: $e'),
      );
    }
  }

  Future<void> _onDisplayAlternativeRoutes(
    DisplayAlternativeRoutes event,
    Emitter<MapState> emit,
  ) async {
    try {
      final map = state.mapController;
      if (map == null) {
        emit(
          state.copyWith(errorMessageGetter: () => 'Map controller not ready'),
        );
        return;
      }
      final route = await _fetchRoute(event.feature, true);
      final routes = route!['routes'] as List<dynamic>?;
      var alternativeRoutes = [];
      await _remove();

      for (int i = 0; i < routes!.length; i++) {
        final route = routes[i];
        final r = getRoute(route);
        final coordinates = r!['coordinates'];
        final List<NavigationStep> routeSteps = r['routeSteps'];
        final accessibilityScore = r['accessibilityScore'];
        await _addLine(coordinates, i, accessibilityScore);
        alternativeRoutes.add(r);
      }
      emit(
        state.copyWith(
          errorMessageGetter: () => null,
          alternativeRoutes: alternativeRoutes,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          errorMessageGetter: () => 'Error displaying alternative routes: $e',
        ),
      );
    }
  }

  Future<void> _addLine(
        List<dynamic> fixedRoute,
        int i,
        double? accessibilityScore,
        ) async {
      final style = state.mapController?.style;

      final sourceId = 'alt-route-source-$i';
      final layerId = 'alt-route-layer-$i';
      print("Adding line with color: $accessibilityScore");
      final List<int> routeColors = [
        Colors.blue.value,
        Colors.green.value,
        Colors.red.value,
        Colors.orange.value,
        Colors.purple.value,
      ];

      fixedRoute = fixedRoute.map((coord) => [coord[1], coord[0]]).toList();
      final geojson = {
        "type": "FeatureCollection",
        "features": [
          {
            "type": "Feature",
            "geometry": {"type": "LineString", "coordinates": fixedRoute},
            "properties": {},
          },
        ],
      };

      print(fixedRoute);

      await style?.addSource(
      mapbox.GeoJsonSource(id: sourceId, data: jsonEncode(geojson)),
    );
    print(makeColor(accessibilityScore!).toARGB32());
    await style?.addLayer(
      mapbox.LineLayer(
        id: layerId,
        sourceId: sourceId,
        lineColor: makeColor(accessibilityScore!).toARGB32(),
        lineWidth: 4.0,
        lineJoin: mapbox.LineJoin.ROUND,
        lineCap: mapbox.LineCap.ROUND,
      ),
    );
  }

  Future<void> _onRemoveAlternativeRoutes(
    RemoveAlternativeRoutes event,
    Emitter<MapState> emit,
  ) async {
    await _remove();
  }

  Future<void> _remove() async {
    final style = state.mapController?.style;
    if (style == null) return;

    int i = 0;
    while (true) {
      final layerId = 'alt-route-layer-$i';
      final sourceId = 'alt-route-source-$i';
      bool removedAnything = false;

      if ((await style.styleLayerExists(layerId))) {
        print("Removing layer: $layerId");
        await style.removeStyleLayer(layerId);
        removedAnything = true;
      }

      if ((await style.styleSourceExists(sourceId))) {
        print("Removing source: $sourceId");
        await style.removeStyleSource(sourceId);
        removedAnything = true;
      }

      if (!removedAnything) break;
      i++;
    }
  }

  Color makeColor(double accessibilityScore) {
    if (accessibilityScore == null) return Colors.blue;
    if (accessibilityScore < 0.4) return Colors.red;
    if (accessibilityScore < 0.7) return Colors.yellow;
    if (accessibilityScore >= 0.7) return Colors.green;
    return Colors.red;
  }
}
