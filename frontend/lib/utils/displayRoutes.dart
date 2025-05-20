import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import '../blocs/map_bloc/map_bloc.dart';
import '../models/mapbox_feature.dart';
import '../services/map_service.dart';

/// Fetches and displays route(s) using MapService and dispatches events to MapBloc.
void fetchAndDisplayRoute(BuildContext context, {required bool alternatives,required MapboxFeature? feature}) async {

  if (feature == null) {
    print("Attempted to navigate but feature was null.");
    return;
  }

  try {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    ).timeout(const Duration(seconds: 10));

    final mapService = MapService();

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

      setFollow(false);
      if(context.mounted) {
        if (alternativeRoutes.isNotEmpty) {
          context
              .read<MapBloc>()
              .add(DisplayAlternativeRoutesFromJson(alternativeRoutes));
        } else {
          print('No alternative routes found.');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Δεν βρέθηκαν διαδρομές.')),
          );
        }
      }
    } else {
      setFollow(true);
      // Send only the first route as JSON
      if(context.mounted) {
        context.read<MapBloc>().add(DisplayRouteFromJson(responseJson));
      }
    }
  } catch (e) {
    print("Navigation error: $e");
    if(context.mounted){
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Δεν φορτώθηκαν οι οδηγίες. Ξαναπροσπάθησε αργότερα!')),
      );
    }
  }
}

var follow = false;

void setFollow(bool follow){
  follow = follow;
}

bool getFollow(){
  return follow;
}