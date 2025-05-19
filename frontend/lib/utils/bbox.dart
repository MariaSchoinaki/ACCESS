
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

import '../blocs/map_bloc/map_bloc.dart';

Future<String> getBbox(BuildContext context) async {
  final mapController = context.read<MapBloc>().state.mapController;
  if (mapController == null) {
    print("_onTap: Widget not mounted or controller is null. Skipping.");
    return '';
  }

  String bboxString = '';
  try{
    final mapbox.CameraState currentCameraState = await mapController.getCameraState();

    // Calculate the limits for the current camera
    // Make Cameraopations from Camerastate
    final mapbox.CameraOptions currentCameraOptions = mapbox.CameraOptions(
      center: currentCameraState.center,
      padding: currentCameraState.padding,
      zoom: currentCameraState.zoom,
      bearing: currentCameraState.bearing,
      pitch: currentCameraState.pitch,
    );

    final mapbox.CoordinateBounds? bounds = await mapController.coordinateBoundsForCamera(currentCameraOptions);

    //Format the string
    if (bounds != null) {
      // Access to Coordinatebounds' Properties coordinates
      final minLng = bounds.southwest.coordinates.lng;
      final minLat = bounds.southwest.coordinates.lat;
      final maxLng = bounds.northeast.coordinates.lng;
      final maxLat = bounds.northeast.coordinates.lat;
      bboxString = '$minLng,$minLat,$maxLng,$maxLat';
      return bboxString;
    } else {
      print('[ Button] Could not get map bounds (getVisibleCoordinateBounds returned null).');
    }
  } catch (e) {
    print("[Button] Error getting map bounds: $e");
  }
  return bboxString;
}