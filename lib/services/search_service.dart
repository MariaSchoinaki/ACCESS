import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer';


class SearchService {
  final String _accessToken = 'token';//String.fromEnvironment("token");


  Future<List<MapboxFeature>> searchPlace(String query) async {
    final url = Uri.parse('https://api.mapbox.com/geocoding/v5/mapbox.places/$query.json?access_token=$_accessToken');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final features = data['features'] as List;
      print(features.toString());
      return features.map((e) => MapboxFeature.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load search results');
    }
  }
}

class MapboxFeature {
  final String id;
  final String name;
  final double latitude;
  final double longitude;

  MapboxFeature({required this.id, required this.name, required this.latitude, required this.longitude});

  factory MapboxFeature.fromJson(Map<String, dynamic> json) {
    final coordinates = json['geometry']['coordinates'];
    return MapboxFeature(
      id: json['id'],
      name: json['place_name'],
      latitude: coordinates[1],
      longitude: coordinates[0],
    );
  }
}