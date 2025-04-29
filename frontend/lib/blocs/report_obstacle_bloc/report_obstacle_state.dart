part of 'report_obstacle_bloc.dart'; // Declares this file is part of report_obstacle_bloc.dart

/// Defines the possible states during the submission of a report.
enum SubmissionStatus {
  /// Initial state, before any submission attempt.
  initial,
  /// The submission is currently in progress.
  submitting,
  /// The submission completed successfully.
  success,
  /// The submission failed.
  failure
}

/// Defines the possible states for loading the user's location.
enum LocationStatus {
  /// Initial state, before attempting to get the location.
  initial,
  /// The location fetching is in progress.
  loading,
  /// The location was fetched successfully.
  loaded,
  /// Failed to fetch the location.
  error
}

/// Represents the state of the report obstacle screen.
///
/// Contains all the information entered by the user (description, image, obstacle type, rating),
/// the submission status, user's location details, and any error messages.
class ReportObstacleState extends Equatable {
  /// The description of the obstacle entered by the user.
  final String description;
  /// The image file potentially picked by the user. Null if no image has been picked.
  final File? pickedImage;
  /// The type of obstacle selected by the user (e.g., "Stairs", "Blocked Ramp").
  final String? selectedObstacleType;
  /// The accessibility rating given by the user.
  final String? accessibilityRating;
  /// The current status of the report submission process.
  final SubmissionStatus submissionStatus;
  /// The user's location represented as an address string, if available.
  final String? userLocation;
  /// The latitude coordinate of the user's current location.
  final double? latitude;
  /// The longitude coordinate of the user's current location.
  final double? longitude;
  /// The current status of the location fetching process.
  final LocationStatus locationStatus;
  /// An error message, if an error occurred (e.g., during submission or location fetching).
  final String? errorMessage;

  /// The main constructor for the state.
  const ReportObstacleState({
    this.description = '', // Default value for description
    this.pickedImage,
    this.selectedObstacleType,
    this.accessibilityRating,
    this.submissionStatus = SubmissionStatus.initial, // Default submission status
    this.userLocation,
    this.latitude,
    this.longitude,
    this.locationStatus = LocationStatus.initial, // Default location status
    this.errorMessage,
  });

  /// Factory constructor to create the initial state.
  ///
  /// Returns a [ReportObstacleState] with all values set to their defaults.
  factory ReportObstacleState.initial() {
    return const ReportObstacleState();
  }

  /// Creates a copy of the current [ReportObstacleState] instance
  /// but with the provided values replacing the existing ones.
  ///
  /// Uses [ValueGetter] for nullable fields to allow explicitly setting them to null.
  ReportObstacleState copyWith({
    String? description,
    ValueGetter<File?>? pickedImageGetter, // Uses ValueGetter to allow clearing (set to null)
    String? selectedObstacleType,
    String? accessibilityRating,
    SubmissionStatus? submissionStatus,
    ValueGetter<String?>? userLocationGetter, // Uses ValueGetter
    ValueGetter<double?>? latitudeGetter,     // Uses ValueGetter
    ValueGetter<double?>? longitudeGetter,    // Uses ValueGetter
    LocationStatus? locationStatus,
    ValueGetter<String?>? errorMessageGetter, // Uses ValueGetter
  }) {
    return ReportObstacleState(
      // Use the provided value if it exists, otherwise keep the current value (this.value).
      description: description ?? this.description,
      // If a ValueGetter was provided, call the function to get the value (which could be null), otherwise keep the current one.
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

  /// Specifies the properties used by Equatable to determine if two
  /// [ReportObstacleState] instances are equal.
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