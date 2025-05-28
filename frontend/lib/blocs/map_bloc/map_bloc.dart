import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:geolocator/geolocator.dart' as geolocator;
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/mapbox_feature.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/navigation_step.dart';
import '../../services/map_service.dart';
import '../../utils/nearest_step.dart';
import '../../utils/point_annotation_click_listener.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_tts/flutter_tts.dart';

part 'map_event.dart';
part 'map_state.dart';
part 'extensions/tracking_logic.dart';
part 'extensions/zoom_controls.dart';
part 'extensions/navigation_logic.dart';
part 'extensions/display_routes.dart';
part 'extensions/annotation_logic.dart';
part 'extensions/camera_controls.dart';
part 'extensions/rating_routes.dart';
part 'extensions/little_actions.dart';


class MapBloc extends Bloc<MapEvent, MapState> {
  late mapbox.PointAnnotationManager? _annotationManager;
  late mapbox.PointAnnotationManager? _categoryAnnotationManager;
  late mapbox.PointAnnotationManager? _favoritesAnnotationManager;
  late List<mapbox.PointAnnotation?> createdAnnotations;
  StreamSubscription<geolocator.Position>? _positionSubscription;
  late StreamSubscription<CompassEvent> _compassSubscription;

  final geolocator.GeolocatorPlatform _geolocator = geolocator.GeolocatorPlatform.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<MapEvent> pendingEvents = [];
  final FlutterTts flutterTts = FlutterTts();
  final mapService = MapService();

  MapBloc() : super(MapState.initial()) {
    on<RequestLocationPermission>(_onRequestLocationPermission);
    on<InitializeMap>(_onInitializeMap);
    on<GetCurrentLocation>(_onGetCurrentLocation);
    on<ZoomIn>(_onZoomIn);
    on<ZoomOut>(_onZoomOut);
    on<FlyTo>(_onFlyTo);
    on<AddMarker>(_onAddMarker);
    on<DeleteMarker>(_onDeleteMarker);
    on<AddCategoryMarkers>(_onAddCategoryMarkers);
    on<_AnnotationClickedInternal>(_onAnnotationClickedInternal);
    on<RenderFavoriteAnnotations>(_onRenderFavoriteAnnotations);
    on<ClearCategoryMarkers>(_onClearCategoryMarkers);

    on<StartTrackingRequested>(_onStartTrackingRequested);
    on<StopTrackingRequested>(_onStopTrackingRequested);
    on<_LocationUpdated>(_onLocationUpdated);
    on<RateAndSaveRouteRequested>(_onRateAndSaveRouteRequested);
    on<DisplayAlternativeRoutes>(_onDisplayAlternativeRoutes);
    on<RemoveAlternativeRoutes>(_onRemoveAlternativeRoutes);

    on<ShareLocationRequested>(_onShareLocation);
    on<LaunchPhoneDialerRequested>(_onLaunchPhoneDialer);
    on<StartNavigationRequested>(_onStartNavigation);
    on<StopNavigationRequested>(_onStopNavigation);
    on<ToggleVoiceInstructions>((event, emit) {
      emit(state.copyWith(isVoiceEnabled: !state.isVoiceEnabled));
    });
    on<ShowedMessage>((event, emit){
      emit(state.copyWith(lastEvent: event));
    });

    on<NavigationPositionUpdated>(_onNavigationPositionUpdated);
    on<ShowRouteRatingDialogRequested>(_onShowRouteRatingDialogRequested);

  }

  Future<void> _onRequestLocationPermission(RequestLocationPermission event, Emitter<MapState> emit) async {
    await Permission.locationWhenInUse.request();
  }

  Future<void> initTTS() async {
    await flutterTts.setLanguage("el-GR");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1.0);
  }

  Future<void> _onInitializeMap(InitializeMap event, Emitter<MapState> emit) async {
    emit(state.copyWith(mapController: event.mapController));
    _annotationManager = await state.mapController?.annotations
        .createPointAnnotationManager(id: 'tapped-layer');
    _categoryAnnotationManager = await state.mapController?.annotations
        .createPointAnnotationManager(id: 'categories-layer');
    _favoritesAnnotationManager = await state.mapController?.annotations
        .createPointAnnotationManager(id: 'favorites-layer');
    for (var e in pendingEvents) {
      add(e); // ή handleEvent(e)
    }
    pendingEvents.clear();
    if (_categoryAnnotationManager != null) {
      _categoryAnnotationManager!.addOnPointAnnotationClickListener(
          PointAnnotationClickListener(
              onAnnotationClick: (mapbox.PointAnnotation annotation) {
                final String internalId = annotation.id;
                final String? mapboxId = state.annotationIdMap[internalId];
                final MapboxFeature? feature = state.featureMap[mapboxId];
                //annotation.iconImage = 'assets/images/blue_pin.png';
                //annotation.iconSize = 0.8;
                if (mapboxId != null && mapboxId.isNotEmpty) {
                  add(_AnnotationClickedInternal(mapboxId, feature!));
                } else {
                  print("!!! MapBloc: mapboxId not found in map or is empty for internal ID $internalId, SKIPPING event add.");
                }
              }));
      print("[MapBloc] Annotation click listener added.");
    }
    emit(state.copyWith(isMapReady: true));
    add(GetCurrentLocation());
    initTTS();
  }

  @override
  Future<void> close() {
    print("Closing MapBloc, cancelling subscription...");
    _positionSubscription?.cancel();
    return super.close();
  }

}
