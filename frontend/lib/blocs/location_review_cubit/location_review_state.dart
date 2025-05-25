part of 'location_review_cubit.dart';


abstract class LocationCommentsState {}

class LocationCommentsInitial extends LocationCommentsState {}

class LocationCommentsLoading extends LocationCommentsState {}

class LocationCommentsLoaded extends LocationCommentsState {
  final List<Comment> comments;

  LocationCommentsLoaded(this.comments);
}

class LocationCommentsError extends LocationCommentsState {
  final String error;

  LocationCommentsError(this.error);
}
