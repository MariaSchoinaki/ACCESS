// map_event.dart
import 'package:equatable/equatable.dart';

abstract class MapEvent extends Equatable {
  const MapEvent();

  @override
  List<Object> get props => [];
}

class LoadMap extends MapEvent {
  const LoadMap();
}
