part of 'sign_up_bloc.dart';

/// Base class for all sign-up related events
abstract class SignUpEvent extends Equatable {
  const SignUpEvent();

  @override
  List<Object> get props => [];
}

/// Event triggered when the user updates their email
class SignUpEmailChanged extends SignUpEvent {
  /// The updated email string
  final String email;

  const SignUpEmailChanged(this.email);

  @override
  List<Object> get props => [email];
}

/// Event triggered when the user updates their password
class SignUpPasswordChanged extends SignUpEvent {
  /// The updated password string
  final String password;

  const SignUpPasswordChanged(this.password);

  @override
  List<Object> get props => [password];
}

/// Event triggered when the user updates the confirm password field
class SignUpConfirmPasswordChanged extends SignUpEvent {
  /// The updated confirm password string
  final String confirmPassword;

  const SignUpConfirmPasswordChanged(this.confirmPassword);

  @override
  List<Object> get props => [confirmPassword];
}

/// Event triggered when the user submits the sign-up form
class SignUpSubmitted extends SignUpEvent {}

/// Event triggered when the user requests to sign up with Google
class SignUpWithGoogleRequested extends SignUpEvent {}

/// Event triggered to show a snackbar message during the sign-up process
class SignUpSnackBarShow extends SignUpEvent {}
