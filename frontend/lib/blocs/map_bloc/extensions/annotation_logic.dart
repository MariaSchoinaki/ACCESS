part of '../map_bloc.dart';

extension MapBlocAnnotations on MapBloc {
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
}