import 'dart:async';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart'; // For Location
import 'package:geocoding/geocoding.dart'; // For address from coordinates

// --- Firebase Imports ---
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
// --- /Firebase Imports ---

part 'report_obstacle_event.dart';
part 'report_obstacle_state.dart';

class ReportObstacleBloc extends Bloc<ReportObstacleEvent, ReportObstacleState> {
  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  ReportObstacleBloc() : super(ReportObstacleState.initial()) {
    on<LoadInitialDataRequested>(_onLoadInitialData);
    on<DescriptionChanged>(_onDescriptionChanged);
    on<ObstacleTypeSelected>(_onObstacleTypeSelected);
    on<AccessibilityRatingSelected>(_onAccessibilityRatingSelected);
    on<PickImageRequested>(_onPickImageRequested);
    on<RemoveImageRequested>(_onRemoveImageRequested);
    on<SelectLocationOnMapRequested>(_onSelectLocationOnMapRequested);
    on<LocationUpdated>(_onLocationUpdated);
    on<SubmitReportRequested>(_onSubmitReportRequested);
    on<ErrorHandler>(_onErrorHandler);
  }

  // --- Handlers ---

  Future<void> _onLoadInitialData(LoadInitialDataRequested event, Emitter<ReportObstacleState> emit) async {
    emit(state.copyWith(
        locationStatus: LocationStatus.loading,
        // Clean old location from previous state
        userLocationGetter: () => null,
        latitudeGetter: () => null,
        longitudeGetter: () => null));
    try {
      // 1. Check and request location permission
      PermissionStatus locationPermission = await Permission.locationWhenInUse.request();

      if (locationPermission.isGranted || locationPermission.isLimited) { // isLimited for iOS 14+
        // 2. Get current location
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high).timeout(const Duration(seconds: 15)); // Timeout

        // 3. Convert coordinates to address (optional, but useful for display)
        String locationString;
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
              position.latitude, position.longitude);
          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            locationString = "${place.street ?? ''} ${place.locality ?? ''}, ${place.postalCode ?? ''} ${place.country ?? ''}".trim();
            // Check if result is useful, otherwise fallback
            if (locationString.isEmpty || locationString == ',') {
              locationString = "Lat: ${position.latitude.toStringAsFixed(5)}, Lon: ${position.longitude.toStringAsFixed(5)}";
            }
          } else {
            locationString = "Lat: ${position.latitude.toStringAsFixed(5)}, Lon: ${position.longitude.toStringAsFixed(5)}";
          }
        } catch (e) {
          print("Geocoding error: $e");
          locationString = "Lat: ${position.latitude.toStringAsFixed(5)}, Lon: ${position.longitude.toStringAsFixed(5)}";
        }

        // 4. Update state with address AND coordinates
        emit(state.copyWith(
          userLocationGetter: () => locationString,
          latitudeGetter: () => position.latitude, // Save Lat
          longitudeGetter: () => position.longitude, // Save Lon
          locationStatus: LocationStatus.loaded,
        ));
      } else {
        // User did not grant permission
        emit(state.copyWith(
          locationStatus: LocationStatus.error,
          errorMessageGetter: () => 'Location permission is required.',
        ));
      }
    } on TimeoutException catch (_) {
      emit(state.copyWith(
          locationStatus: LocationStatus.error,
          errorMessageGetter: () => 'Could not get location in time.'));
    } catch (e) {
      // Other errors (e.g., GPS disabled, network error)
      print("Error getting location: $e");
      emit(state.copyWith(
        locationStatus: LocationStatus.error,
        errorMessageGetter: () => 'Could not get location: ${e.toString()}',
      ));
    }
  }

  void _onDescriptionChanged(DescriptionChanged event, Emitter<ReportObstacleState> emit) {
    emit(state.copyWith(description: event.description));
  }

  void _onObstacleTypeSelected(ObstacleTypeSelected event, Emitter<ReportObstacleState> emit) {
    emit(state.copyWith(selectedObstacleType: event.type));
  }

  void _onAccessibilityRatingSelected(AccessibilityRatingSelected event, Emitter<ReportObstacleState> emit) {
    emit(state.copyWith(accessibilityRating: event.rating));
  }

  Future<void> _onPickImageRequested(PickImageRequested event, Emitter<ReportObstacleState> emit) async {
    // Check and request permission depending on source
    Permission? permission;
    if (event.source == ImageSource.camera) {
      permission = Permission.camera;
    } else {
      permission = Permission.photos; // For iOS / Android 13+
      if (Platform.isAndroid) {
        // You may also need to check storage permission for old Androids (< API 33)
        try {
          final androidInfo = await DeviceInfoPlugin().androidInfo;
          final sdkInt = androidInfo.version.sdkInt;
          print("Android SDK Version: $sdkInt");
          if (sdkInt < 33) {
            permission = Permission.storage;
            print("Android SDK < 33 detected. Requesting Permission.storage instead of Photos.");
          } else {
            print("Android SDK >= 33. Using Permission.photos.");
          }
        } catch (e) {
          print("Error getting Android device info: $e. Proceeding with Permission.photos.");
          permission = Permission.photos;
        }
      }
    }

    PermissionStatus status = await permission.request();
    print("--- _onPickImageRequested started for source: ${event.source} ---"); // DEBUG
    if (status.isGranted || status.isLimited) {
      print("Permission granted. Trying to pick image..."); // DEBUG
      try {
        print("Trying to pick image..."); // DEBUG
        final pickedFile = await _imagePicker.pickImage(
            source: event.source
        );
        if (pickedFile != null) {
          print("In != null"); // DEBUG
          print("Image path: ${pickedFile.path}"); // DEBUG
          emit(state.copyWith(
              pickedImageGetter: () => File(pickedFile.path),
              errorMessageGetter: () => null // Clear any previous image error
          ));
        } else {
          print("User canceled image picking");
          emit(state.copyWith(errorMessageGetter: () => null)); // Clear error if existed
        }
      } catch (e) {
        print("Error picking image: $e");
        emit(state.copyWith(
            errorMessageGetter: () => 'Error picking image: ${e.toString()}'));
      }
    } else {
      print("Permission denied");
      emit(state.copyWith(
          errorMessageGetter: () => 'Permission required for ${event.source == ImageSource.camera ? "camera" : "gallery"}.'));
      // Optionally: open app settings
      // openAppSettings();
    }
  }

  void _onRemoveImageRequested(RemoveImageRequested event, Emitter<ReportObstacleState> emit) {
    emit(state.copyWith(
        pickedImageGetter: () => null, // Remove image
        errorMessageGetter: () => null // Clear any image error
    ));
  }

  Future<void> _onSelectLocationOnMapRequested(SelectLocationOnMapRequested event, Emitter<ReportObstacleState> emit) async {
    // ---- TODO: Navigation Logic to Map Screen ----
    // Here you should navigate to the map screen.
    // The map screen should return BOTH address/description AND coordinates (latitude, longitude).
    //
    // FLOW EXAMPLE:
    // 1. emit(state.copyWith(triggerMapNavigation: true))
    // 2. In UI, BlocListener listens for triggerMapNavigation == true
    // 3. Listener calls:
    //    final result = await Navigator.push<Map<String, dynamic>>(context, MaterialPageRoute(builder: (_) => MapSelectionScreen()));
    // 4. emit(state.copyWith(triggerMapNavigation: false)) // Reset flag
    // 5. If result != null:
    //    add(LocationUpdated(result['address'], result['latitude'], result['longitude']));

    // Temporary simulation (to avoid breaking the flow):
    print("⚠️ TODO: Navigate to Map Selection Screen and await result (address, lat, lon).");
    emit(state.copyWith(
        locationStatus: LocationStatus.loading // Show loading while waiting
    ));
    await Future.delayed(Duration(milliseconds: 500)); // Small delay
    // Simulate that user selected a location and returned
    const simulatedLocationString = "Location from Map (Simulation)";
    const simulatedLat = 37.9715; // Example Coordinates
    const simulatedLon = 23.7257;
    add(const LocationUpdated(simulatedLocationString, simulatedLat, simulatedLon));
  }

  // Updated to also accept coordinates
  void _onLocationUpdated(LocationUpdated event, Emitter<ReportObstacleState> emit) {
    emit(state.copyWith(
        userLocationGetter: () => event.locationString,
        latitudeGetter: () => event.latitude, // Update Lat
        longitudeGetter: () => event.longitude, // Update Lon
        locationStatus: LocationStatus.loaded
    ));
  }

  Future<void> _onSubmitReportRequested( SubmitReportRequested event, Emitter<ReportObstacleState> emit) async {

    // --- Step 1:  // Validate mandatory fields ---
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      emit(state.copyWith(submissionStatus: SubmissionStatus.failure, errorMessageGetter: () => 'Πρέπει να είστε συνδεδεμένος για να υποβάλετε αναφορά.'));
      return;
    }
    //Check if there is a location set (with coordinates)
    if (state.latitude == null || state.longitude == null) {
      emit(state.copyWith(submissionStatus: SubmissionStatus.failure, errorMessageGetter: () => 'Παρακαλώ ορίστε τοποθεσία (τρέχουσα ή από χάρτη).'));
      return;
    }
    if (state.selectedObstacleType == null) {
      emit(state.copyWith(submissionStatus: SubmissionStatus.failure, errorMessageGetter: () => 'Παρακαλώ επιλέξτε τύπο εμποδίου.'));
      return;
    }
    if (state.accessibilityRating == null) {
      emit(state.copyWith(submissionStatus: SubmissionStatus.failure, errorMessageGetter: () => 'Παρακαλώ επιλέξτε βαθμό προσβασιμότητας.'));
      return;
    }

    if (state.pickedImage == null) {
      emit(state.copyWith(submissionStatus: SubmissionStatus.failure, errorMessageGetter: () => 'Παρακαλώ προσθέστε μια φωτογραφία του εμποδίου.'));
      return;
    }

    emit(state.copyWith(
        submissionStatus: SubmissionStatus.submitting,
        errorMessageGetter: () => null // Clean previous errors
    ));

    String? imageUrl; //  Store image url

    try {
      // --- Step 2: Upload image Firebase Storage ---
      final imageFile = state.pickedImage;
      if (imageFile != null && imageFile.existsSync()) {
        print("Uploading image to Firebase Storage...");
        final String imageId = DateTime.now().millisecondsSinceEpoch.toString();
        final String storagePath = 'report_images/${currentUser.uid}/$imageId.jpg';
        final Reference storageRef = _storage.ref().child(storagePath);
        final UploadTask uploadTask = storageRef.putFile(imageFile);
        final TaskSnapshot snapshot = await uploadTask.timeout(const Duration(seconds: 60));
        imageUrl = await snapshot.ref.getDownloadURL();
        print("Image uploaded successfully: $imageUrl");
      }

      // --- Step 3: Preparing entry for Firestore ---
      final Map<String, dynamic> reportData = {
        'userId': currentUser.uid,
        'userEmail': currentUser.email,
        'locationDescription': state.userLocation ?? "Δεν δόθηκε περιγραφή",
        'coordinates': GeoPoint(state.latitude!, state.longitude!),
        'obstacleType': state.selectedObstacleType!,
        'accessibility': state.accessibilityRating!,
        'description': state.description.isNotEmpty ? state.description : null,
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      };

      // --- Step 4: Store date in Firestore ---
      print("Saving report data to Firestore...");
      await _firestore.collection('reports').add(reportData).timeout(const Duration(seconds: 30));

      print("Report saved successfully!");
      emit(state.copyWith(
        submissionStatus: SubmissionStatus.success,
        // description: '',
        // pickedImageGetter: () => null,
        // selectedObstacleType: null,
        // accessibilityRating: null,
      ));
      await Future.delayed(const Duration(seconds: 1));
      emit(state.copyWith(submissionStatus: SubmissionStatus.initial));


    } on FirebaseException catch (e) {
      print("Firebase error during submission: ${e.code} - ${e.message}");
      emit(state.copyWith(
          submissionStatus: SubmissionStatus.failure,
          errorMessageGetter: () => 'Σφάλμα Firebase: ${e.message ?? e.code}'));
    } on TimeoutException catch (_) {
      emit(state.copyWith(submissionStatus: SubmissionStatus.failure, errorMessageGetter: () => 'Η ενέργεια άργησε να ολοκληρωθεί (timeout).'));
    } catch (e) {
      print("Error submitting report: $e");
      emit(state.copyWith(
        submissionStatus: SubmissionStatus.failure,
        errorMessageGetter: () => 'Παρουσιάστηκε ένα σφάλμα: ${e.toString()}',
      ));
    }
  }

  void _onErrorHandler(ErrorHandler event, Emitter<ReportObstacleState> emit) {
    emit(state.copyWith(submissionStatus: SubmissionStatus.initial));
  }
}

