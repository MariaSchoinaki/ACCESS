import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:html' as html;

part 'map_event.dart';
part 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  MapBloc() : super(const MapInitial()) {
    on<LoadMap>((event, emit) async {
      emit(const MapLoading());
      try {
        await Future.delayed(const Duration(milliseconds: 100));
        emit(const MapLoaded());
      } catch (e) {
        emit(MapError("Failed to load map: $e"));
      }
    });



    on<AddCustomMarker>((event, emit) {
      if (event.coordinates.length != 2) {
        emit(MapError("Invalid coordinates"));
        return;
      }

      final markerJs = '''
        new mapboxgl.Marker()
          .setLngLat([${event.coordinates[0]}, ${event.coordinates[1]}])
          .addTo(map);
      ''';

      final iframe = html.document.getElementById('map-iframe') as html.IFrameElement?;
      iframe?.contentWindow?.postMessage({
        'type': 'executeCode',
        'code': markerJs
      }, '*');
    });
  }
}