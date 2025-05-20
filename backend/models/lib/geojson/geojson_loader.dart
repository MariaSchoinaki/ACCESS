import 'dart:convert';
import 'dart:io';

import 'geojson_models.dart';

/// Loads a GeoJSON file from [path] and returns the parsed FeatureCollection.
Future<GeoJsonFeatureCollection> loadGeoJson(String path) async {
  final file = File(path);
  final data = jsonDecode(await file.readAsString());
  return GeoJsonFeatureCollection.fromJson(data);
}
