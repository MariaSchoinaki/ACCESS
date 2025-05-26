import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'map_event.dart';
part 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  MapBloc() : super(const MapInitial()) {
    on<LoadMap>((event, emit) async {
      emit(const MapLoading());
      try {
        await Future.delayed(const Duration(milliseconds: 100)); // Simulate delay or setup
        emit(const MapLoaded());
      } catch (e) {
        emit(MapError("Failed to load map: $e"));
      }
    });
  }
}
