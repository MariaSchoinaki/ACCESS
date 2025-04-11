import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:permission_handler/permission_handler.dart';
import 'map_event.dart';
import 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {

  late mapbox.PointAnnotationManager? _annotationManager;

  MapBloc() : super(MapState()) {
    on<RequestLocationPermission>((event, emit) async {
      await Permission.locationWhenInUse.request();
    });

    on<InitializeMap>((event, emit) async {
      emit(state.copyWith(mapController: event.mapController));
      _annotationManager = await state.mapController?.annotations.createPointAnnotationManager();
      add(GetCurrentLocation());
    });

    on<GetCurrentLocation>((event, emit) async {
      final position = await geolocator.Geolocator.getCurrentPosition();

      final point = mapbox.Point(
        coordinates: mapbox.Position(position.longitude, position.latitude),
      );

      state.mapController?.flyTo(
        mapbox.CameraOptions(center: point, zoom: 16.0),
        mapbox.MapAnimationOptions(duration: 1000),
      );

      await state.mapController?.style.addSource(
        mapbox.GeoJsonSource(
          id: 'user-location-source',
          data: jsonEncode({
            "type": "FeatureCollection",
            "features": [
              {
                "type": "Feature",
                "geometry": {
                  "type": "Point",
                  "coordinates": [position.longitude, position.latitude],
                },
              }
            ],
          }),
        ),
      );

      /**
      await state.mapController?.style.addLayer(
        mapbox.CircleLayer(
          id: 'user-location-layer',
          sourceId: 'user-location-source',
          circleColor: 4281558371,
          circleRadius: 8,
          circleStrokeColor: 0,
          circleStrokeWidth: 2,
        ),
      );*/
    });

    on<ZoomIn>((event, emit) async {
      final currentZoom = await state.mapController?.getCameraState();
      final newZoom = (currentZoom?.zoom ?? state.zoomLevel) + 1;
      state.mapController?.flyTo(
        mapbox.CameraOptions(zoom: newZoom),
        mapbox.MapAnimationOptions(duration: 500),
      );
      emit(state.copyWith(zoomLevel: newZoom));
    });

    on<ZoomOut>((event, emit) async {
      final currentZoom = await state.mapController?.getCameraState();
      final newZoom = (currentZoom?.zoom ?? state.zoomLevel) - 1;
      state.mapController?.flyTo(
        mapbox.CameraOptions(zoom: newZoom),
        mapbox.MapAnimationOptions(duration: 500),
      );
      emit(state.copyWith(zoomLevel: newZoom));
    });

    on<FlyTo>((event, emit) async {
      final point = mapbox.Point(
        coordinates: mapbox.Position(event.longitude, event.latitude),
      );

      state.mapController?.flyTo(
        mapbox.CameraOptions(center: point, zoom: 16.0),
        mapbox.MapAnimationOptions(duration: 1000),
      );
    });

    on<AddMarker>((event, emit) async {
      final map = state.mapController;
      if (map == null) return;



      final bytes = await rootBundle.load('assets/images/pin.png');
      final imageData = bytes.buffer.asUint8List();

      final point = mapbox.Point(
        coordinates: mapbox.Position(event.longitude, event.latitude),
      );


      await _annotationManager?.deleteAll();

      await _annotationManager?.create(
        mapbox.PointAnnotationOptions(
          geometry: point,
          iconSize: 0.5,
          image: imageData,
          iconAnchor: mapbox.IconAnchor.BOTTOM,
        ),
      );
    });

    on<DeleteMarker>((event, emit) async {
      await _annotationManager?.deleteAll();
    });
  }
}