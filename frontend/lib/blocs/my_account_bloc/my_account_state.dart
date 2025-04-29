part of 'my_account_bloc.dart';

/// Base abstract class for all states related to the My Account feature.
abstract class MyAccountState {}

/// Represents the initial state of the My Account feature,
/// typically before any data has been loaded or requested.
class MyAccountInitial extends MyAccountState {}

/// Represents the state when the application is actively loading
/// the user's account data (e.g., from Firestore or an API).
class MyAccountLoading extends MyAccountState {}

/// Represents the state when the user's account data has been successfully loaded.
class MyAccountLoaded extends MyAccountState {
  /// The user's email address (usually considered non-nullable when loaded).
  final String email;
  /// The URL of the user's profile photo, if available.
  final String? photoUrl;
  /// The user's date of birth as a string, if available.
  final String? dateOfBirth;
  /// The type of disability specified by the user, if available.
  final String? disabilityType;

  /// Creates a [MyAccountLoaded] state instance.
  ///
  /// Requires the [email] and optionally takes [photoUrl], [dateOfBirth],
  /// and [disabilityType].
  MyAccountLoaded({
    required this.email,
    this.photoUrl,
    this.dateOfBirth,
    this.disabilityType,
  });
}

/// Represents a state indicating that specific user account details
/// (date of birth and disability type) have just been updated successfully.
/// This might be used to trigger specific UI feedback after an update action.
class MyAccountUpdated extends MyAccountState {
  /// The newly updated date of birth.
  final String dateOfBirth;
  /// The newly updated disability type.
  final String disabilityType;

  /// Creates a [MyAccountUpdated] state instance.
  MyAccountUpdated({
    required this.dateOfBirth,
    required this.disabilityType,
  });

  // Note: This state includes 'props' but doesn't extend Equatable.
  // If equality comparison is needed, it should extend Equatable.
  // Otherwise, this override might not function as expected or is unnecessary.
  List<Object?> get props => [
    dateOfBirth,
    disabilityType,
  ];
}

/// Represents the state when the user has successfully signed out
/// from their account.
class MyAccountSignedOut extends MyAccountState {}

/// Represents an error state within the My Account feature.
///
/// This state occurs if there's an issue loading data, updating data,
/// or during sign-out.
class MyAccountError extends MyAccountState {
  /// A message describing the error that occurred.
  final String message;

  /// Creates a [MyAccountError] state instance with an error [message].
  MyAccountError(this.message);
}