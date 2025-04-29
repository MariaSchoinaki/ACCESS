part of 'report_obstacle_bloc.dart'; // Declares this file is part of report_obstacle_bloc.dart

/// Base class for all events related to the obstacle reporting feature.
/// Uses [Equatable] to allow for value comparison between event instances.
abstract class ReportObstacleEvent extends Equatable {
  const ReportObstacleEvent();

  @override
  List<Object?> get props => []; // Default empty list for events without specific properties
}

/// Event triggered to load any initial data needed for the report screen,
/// such as fetching the user's current location automatically.
class LoadInitialDataRequested extends ReportObstacleEvent {}

/// Event triggered when the user changes the text in the description input field.
class DescriptionChanged extends ReportObstacleEvent {
  /// The updated description text.
  final String description;

  /// Creates an event carrying the new description.
  const DescriptionChanged(this.description);

  @override List<Object?> get props => [description]; // Include description in equality comparison
}

/// Event triggered when the user selects a type of obstacle from a list or dropdown.
class ObstacleTypeSelected extends ReportObstacleEvent {
  /// The selected obstacle type identifier (e.g., a string key or display name).
  final String type;

  /// Creates an event carrying the selected obstacle type.
  const ObstacleTypeSelected(this.type);

  @override List<Object?> get props => [type]; // Include type in equality comparison
}

/// Event triggered when the user selects an accessibility rating.
class AccessibilityRatingSelected extends ReportObstacleEvent {
  /// The selected accessibility rating identifier.
  final String rating;

  /// Creates an event carrying the selected rating.
  const AccessibilityRatingSelected(this.rating);

  @override List<Object?> get props => [rating]; // Include rating in equality comparison
}

/// Event triggered when the user requests to pick an image.
class PickImageRequested extends ReportObstacleEvent {
  /// The source from which to pick the image (e.g., camera or gallery).
  final ImageSource source;

  /// Creates an event specifying the image source.
  const PickImageRequested(this.source);

  @override List<Object?> get props => [source]; // Include source in equality comparison
}

/// Event triggered when the user requests to remove the currently selected image.
class RemoveImageRequested extends ReportObstacleEvent {}

/// Event triggered when the user requests to select the obstacle's location manually on a map.
class SelectLocationOnMapRequested extends ReportObstacleEvent {}

/// Event triggered when the location (either automatically fetched or manually selected)
/// is determined and needs to be updated in the state.
class LocationUpdated extends ReportObstacleEvent {
  /// A string representation of the location (e.g., address).
  final String locationString;
  /// The latitude coordinate of the location.
  final double latitude;
  /// The longitude coordinate of the location.
  final double longitude;

  /// Creates an event carrying the updated location details.
  const LocationUpdated(this.locationString, this.latitude, this.longitude);

  @override List<Object?> get props => [locationString, latitude, longitude]; // Include location details in equality comparison
}

/// Event triggered when the user confirms and requests to submit the completed obstacle report.
class SubmitReportRequested extends ReportObstacleEvent {}

/// A generic event potentially used to signal or handle specific error scenarios
/// that might need distinct handling within the BLoC.
class ErrorHandler extends ReportObstacleEvent {}