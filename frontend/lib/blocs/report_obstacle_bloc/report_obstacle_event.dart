// =========================================================================
//                            Event Definitions
// =========================================================================
// (Αυτό το κομμάτι συνήθως βρίσκεται στο report_obstacle_event.dart)
// Το βάζω εδώ για πληρότητα στο copy-paste.

part of 'report_obstacle_bloc.dart';

abstract class ReportObstacleEvent extends Equatable {
  const ReportObstacleEvent();

  @override
  List<Object?> get props => [];
}

class LoadInitialDataRequested extends ReportObstacleEvent {}

class DescriptionChanged extends ReportObstacleEvent {
  final String description;
  const DescriptionChanged(this.description);
  @override List<Object?> get props => [description];
}

class ObstacleTypeSelected extends ReportObstacleEvent {
  final String type;
  const ObstacleTypeSelected(this.type);
  @override List<Object?> get props => [type];
}

class AccessibilityRatingSelected extends ReportObstacleEvent {
  final String rating;
  const AccessibilityRatingSelected(this.rating);
  @override List<Object?> get props => [rating];
}

class PickImageRequested extends ReportObstacleEvent {
  final ImageSource source;
  const PickImageRequested(this.source);
  @override List<Object?> get props => [source];
}

class RemoveImageRequested extends ReportObstacleEvent {}

class SelectLocationOnMapRequested extends ReportObstacleEvent {}

class LocationUpdated extends ReportObstacleEvent {
  final String locationString;
  final double latitude;
  final double longitude;
  const LocationUpdated(this.locationString, this.latitude, this.longitude);
  @override List<Object?> get props => [locationString, latitude, longitude];
}

class SubmitReportRequested extends ReportObstacleEvent {}

class ErrorHandler extends ReportObstacleEvent {}