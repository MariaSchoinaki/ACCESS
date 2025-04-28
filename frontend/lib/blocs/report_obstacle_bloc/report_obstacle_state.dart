// =========================================================================
//                            State Definition
// =========================================================================
part of 'report_obstacle_bloc.dart';

enum SubmissionStatus { initial, submitting, success, failure }
enum LocationStatus { initial, loading, loaded, error }

class ReportObstacleState extends Equatable {
  final String description;
  final File? pickedImage;
  final String? selectedObstacleType;
  final String? accessibilityRating;
  final SubmissionStatus submissionStatus;
  final String? userLocation;
  final double? latitude;
  final double? longitude;
  final LocationStatus locationStatus;
  final String? errorMessage;

  const ReportObstacleState({
    this.description = '',
    this.pickedImage,
    this.selectedObstacleType,
    this.accessibilityRating,
    this.submissionStatus = SubmissionStatus.initial,
    this.userLocation,
    this.latitude,
    this.longitude,
    this.locationStatus = LocationStatus.initial,
    this.errorMessage,
  });

  // Factory constructor for initial
  factory ReportObstacleState.initial() {
    return const ReportObstacleState();
  }

  ReportObstacleState copyWith({
    String? description,
    ValueGetter<File?>? pickedImageGetter,
    String? selectedObstacleType,
    String? accessibilityRating,
    SubmissionStatus? submissionStatus,
    ValueGetter<String?>? userLocationGetter,
    ValueGetter<double?>? latitudeGetter, // it can be null
    ValueGetter<double?>? longitudeGetter,
    LocationStatus? locationStatus,
    ValueGetter<String?>? errorMessageGetter,
  }) {
    return ReportObstacleState(
      description: description ?? this.description,
      pickedImage: pickedImageGetter != null ? pickedImageGetter() : this.pickedImage,
      selectedObstacleType: selectedObstacleType ?? this.selectedObstacleType,
      accessibilityRating: accessibilityRating ?? this.accessibilityRating,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      userLocation: userLocationGetter != null ? userLocationGetter() : this.userLocation,
      latitude: latitudeGetter != null ? latitudeGetter() : this.latitude,
      longitude: longitudeGetter != null ? longitudeGetter() : this.longitude,
      locationStatus: locationStatus ?? this.locationStatus,
      errorMessage: errorMessageGetter != null ? errorMessageGetter() : this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    description,
    pickedImage,
    selectedObstacleType,
    accessibilityRating,
    submissionStatus,
    userLocation,
    latitude,
    longitude,
    locationStatus,
    errorMessage,
  ];
}
