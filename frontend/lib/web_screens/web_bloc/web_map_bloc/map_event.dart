part of 'map_bloc.dart';

abstract class MapEvent extends Equatable {
  const MapEvent();

  @override
  List<Object> get props => [];
}

class LoadMap extends MapEvent {
  const LoadMap();
}

class AddCustomMarker extends MapEvent {
  final List<double> coordinates;
  const AddCustomMarker(this.coordinates);
}

class LoadClusters extends MapEvent {
  final List<List<dynamic>> clusters;
  const LoadClusters(this.clusters);
}