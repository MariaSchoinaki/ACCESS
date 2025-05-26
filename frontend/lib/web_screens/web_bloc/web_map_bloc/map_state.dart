part of 'map_bloc.dart';

abstract class MapState extends Equatable {
  const MapState();

  @override
  List<Object> get props => [];
}

class MapInitial extends MapState {
  const MapInitial();
}

class MapLoading extends MapState {
  const MapLoading();
}

class MapLoaded extends MapState {
  const MapLoaded();
}

class MapError extends MapState {
  final String message;
  const MapError(this.message);

  @override
  List<Object> get props => [message];
}
