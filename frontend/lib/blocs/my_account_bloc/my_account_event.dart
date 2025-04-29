part of 'my_account_bloc.dart';

/// Base abstract class for all events related to the My Account feature.
/// Extends [Equatable] to allow for value comparison between event instances.
abstract class MyAccountEvent extends Equatable {
  /// Creates a const [MyAccountEvent]. Extending classes should call this.
  const MyAccountEvent();
}

/// Event dispatched to trigger the loading of the current user's
/// profile data from the data source (e.g., Firestore).
class LoadUserProfile extends MyAccountEvent {

  /// Returns an empty list as this event carries no specific data fields
  /// for equality comparison.
  @override
  List<Object?> get props => [];
}

/// Event dispatched when the user initiates the sign-out process.
class SignOutRequested extends MyAccountEvent {
  /// Returns an empty list as this event carries no specific data fields
  /// for equality comparison.
  @override
  List<Object?> get props => [];
}

/// Event dispatched to update specific user profile information.
class UpdateUserInfo extends MyAccountEvent {
  /// The new date of birth to be updated (optional).
  /// If null, this field might not be updated.
  final String? dateOfBirth;
  /// The new disability type to be updated (optional).
  /// If null, this field might not be updated.
  final String? disabilityType;

  /// Creates an [UpdateUserInfo] event.
  ///
  /// Takes optional [dateOfBirth] and [disabilityType] strings.
  const UpdateUserInfo({this.dateOfBirth, this.disabilityType});

  /// Returns a list containing the [dateOfBirth] and [disabilityType]
  /// for equality comparison.
  @override
  List<Object?> get props => [dateOfBirth, disabilityType];
}