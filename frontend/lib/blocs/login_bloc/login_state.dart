part of 'login_bloc.dart';

/// Represents the status of the login process
enum LoginStatus { initial, loading, success, failure }

/// The state class for the Login BLoC
class LoginState extends Equatable {
  /// The email input by the user
  final String email;

  /// The password input by the user
  final String password;

  /// The current status of the login flow (initial, loading, success, failure)
  final LoginStatus status;

  /// An error message shown in case of failure
  final String error;

  /// Constructs a [LoginState] with default or provided values
  const LoginState({
    this.email = '',
    this.password = '',
    this.status = LoginStatus.initial,
    this.error = '',
  });

  /// Returns true if the email is valid using the [EmailValidator]
  bool get isEmailValid => EmailValidator.validate(email);

  /// Returns true if the password field is not empty
  bool get isPasswordValid => password.isNotEmpty;

  /// Returns true if both email and password are valid
  bool get isFormValid => isEmailValid && isPasswordValid;

  /// Creates a new copy of the current state with updated fields
  LoginState copyWith({
    String? email,
    String? password,
    LoginStatus? status,
    String? error,
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }

  /// Returns a list of properties to compare for equality
  @override
  List<Object?> get props => [email, password, status, error];
}
