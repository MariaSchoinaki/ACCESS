part of 'sign_up_bloc.dart';

/// Enum representing the status of the sign-up process.
enum SignUpStatus {
  /// The initial (idle) state before any input.
  initial,

  /// Indicates that the form is currently being submitted.
  submitting,

  /// Indicates that the sign-up was successful.
  success,

  /// Indicates that the sign-up failed.
  failure,
}

/// Represents the state of the sign-up form, including input values,
/// form status, and validation logic.
class SignUpState extends Equatable {
  /// Creates a [SignUpState] instance with optional default values.
  const SignUpState({
    this.status = SignUpStatus.initial,
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.errorMessage = '',
  });

  /// The current status of the sign-up process.
  final SignUpStatus status;

  /// The email entered by the user.
  final String email;

  /// The password entered by the user.
  final String password;

  /// The password confirmation entered by the user.
  final String confirmPassword;

  /// The error message to display in case of a failure.
  final String errorMessage;

  /// Returns `true` if the entered email is valid.
  bool get isEmailValid => EmailValidator.validate(email);

  /// Returns `true` if the entered password is valid (at least 6 characters).
  bool get isPasswordValid => password.isNotEmpty && password.length >= 6;

  /// Returns `true` if the confirmation password matches the original password.
  bool get isConfirmPasswordValid => password == confirmPassword && confirmPassword.isNotEmpty;

  /// Returns `true` if all form fields are valid.
  bool get isFormValid => isEmailValid && isPasswordValid && isConfirmPasswordValid;

  /// Creates a copy of the current state with optional new values.
  SignUpState copyWith({
    SignUpStatus? status,
    String? email,
    String? password,
    String? confirmPassword,
    String? errorMessage,
  }) {
    return SignUpState(
      status: status ?? this.status,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, email, password, confirmPassword, errorMessage];
}