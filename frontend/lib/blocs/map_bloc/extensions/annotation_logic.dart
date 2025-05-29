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
          iconAnchor: mapbox.IconAnchor.BOTTOM,
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
          print("Annotation ID: ${createdAnnotations[i]!.id}");
          print("Feature ID: ${event.features[i].id}");
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

  Future<void> _onRenderFavoriteAnnotations(RenderFavoriteAnnotations event, Emitter<MapState> emit) async {
    while (_favoritesAnnotationManager == null) {
      if (state.mapController == null) {
        await Future.delayed(Duration(milliseconds: 100));
        continue;
      }
      _favoritesAnnotationManager = await state.mapController!.annotations
          .createPointAnnotationManager(id: 'favorites-layer');
    }
    if (_favoritesAnnotationManager == null) return;


    final bytes = await rootBundle.load('assets/images/star.png');
    final imageData = bytes.buffer.asUint8List();
    List<mapbox.PointAnnotationOptions> optionsList = [];

    final annotations = event.favorites.entries.map((entry) {
      final data = entry.value as Map<String, dynamic>;
      final lat = data['location']['lat'] as double;
      final lng = data['location']['lng'] as double;

      return mapbox.PointAnnotationOptions(
        geometry: mapbox.Point(coordinates: mapbox.Position(lng, lat)),
        iconSize: 0.1,
        image: imageData,
        iconAnchor: mapbox.IconAnchor.CENTER,
      );
    }).toList();

    await _favoritesAnnotationManager!.deleteAll();
    await _favoritesAnnotationManager!.createMulti(annotations);
  }

  Future<void> _onLoadClusters(LoadClusters event, Emitter<MapState> emit) async {
    try {
      final url = 'http://10.0.2.2:9090/setreport';
      final response = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final dynamic rawData = json.decode(response.body);
        final clusters = _processClusters(rawData);

        if (clusters.isNotEmpty) {
          emit(state.copyWith(clusters: clusters));
          _addClusterMarkers(clusters);
        } else {
          debugPrint('Δεν βρέθηκαν clusters');
        }
      } else {
        debugPrint('Σφάλμα server: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      debugPrint('Σφάλμα δικτύου: $e');
    } on TimeoutException catch (_) {
      debugPrint('Timeout - Ο server δεν απάντησε');
    } catch (e) {
      debugPrint('Γενικό σφάλμα: $e');
    }
  }

  List<List<Map<String, dynamic>>> _processClusters(dynamic rawClusters) {
    try {
      final List clustersList = rawClusters as List;
      return clustersList.map<List<Map<String, dynamic>>>((dynamic cluster) {

        final List reportsList = cluster as List;
        return reportsList.map<Map<String, dynamic>>((dynamic report) {

          final Map<String, dynamic> reportMap = report as Map<String, dynamic>;

          return {
            'id': reportMap['id'] as String? ?? '',
            'timestamp': _formatTimestamp(reportMap['timestamp'] as String? ?? ''),
            'latitude': (reportMap['latitude'] as num?)?.toDouble() ?? 0.0,
            'longitude': (reportMap['longitude'] as num?)?.toDouble() ?? 0.0,
            'obstacleType': reportMap['obstacleType'] as String? ?? '',
            'locationDescription': reportMap['locationDescription'] as String? ?? '',
            'imageUrl': reportMap['imageUrl'] as String? ?? '',
            'accessibility': reportMap['accessibility'] as String? ?? '',
            'description': reportMap['description'] as String? ?? '',
            'userId': reportMap['userId'] as String? ?? '',
            'userEmail': reportMap['userEmail'] as String? ?? '',
          };
        }).toList();
      }).toList();
    } catch (e) {
      debugPrint('Σφάλμα επεξεργασίας clusters: $e');
      return [];
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
    } catch (e) {
      return timestamp;
    }
  }

  Future<void> _addClusterMarkers(List<List<Map<String, dynamic>>> clusters) async {
    if (_clusterAnnotationManager == null) {
      if (state.mapController == null) return;

      _clusterAnnotationManager = await state.mapController!.annotations
          .createPointAnnotationManager(id: 'clusters-layer');
    }

    if (_clusterAnnotationManager == null) return;

    final bytes = await rootBundle.load('assets/images/report_pin.png');
    final imageData = bytes.buffer.asUint8List();

    List<mapbox.PointAnnotationOptions> optionsList = [];
    for (var cluster in clusters) {
      if (cluster.isNotEmpty) {
        final firstReport = cluster[0];
        optionsList.add(
          mapbox.PointAnnotationOptions(
            geometry: mapbox.Point(
              coordinates: mapbox.Position(
                firstReport['longitude'] as double,
                firstReport['latitude'] as double,
              ),
            ),
            iconSize: 0.5,
            image: imageData,
            iconAnchor: mapbox.IconAnchor.BOTTOM,
          ),
        );
      }
    }

    await _clusterAnnotationManager!.deleteAll();
    final annotations = await _clusterAnnotationManager!.createMulti(optionsList);

    _clusterAnnotationManager!.addOnPointAnnotationClickListener((annotation) {
      final clusterIndex = annotations.indexOf(annotation);
      if (clusterIndex >= 0 && clusterIndex < clusters.length) {
        add(ClusterMarkerClicked(clusters[clusterIndex]));
      }
    } as mapbox.OnPointAnnotationClickListener);
  }

  void _onClusterMarkerClicked(ClusterMarkerClicked event, Emitter<MapState> emit) {
    emit(state.copyWith(
      showClusterReports: true,
      clusterReports: event.reports,
    ));
  }

  void _onHideClusterReports(HideClusterReports event, Emitter<MapState> emit) {
    emit(state.copyWith(
      showClusterReports: false,
      clusterReports: null,
    ));
  }

}
