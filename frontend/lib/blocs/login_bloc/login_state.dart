part of 'login_bloc.dart';

enum LoginStatus { initial, loading, success, failure }

class LoginState extends Equatable {
  final String email;
  final String password;
  final LoginStatus status;
  final String error;

  const LoginState({
    this.email = '',
    this.password = '',
    this.status = LoginStatus.initial,
    this.error = '',
  });

  bool get isEmailValid => EmailValidator.validate(email);
  bool get isPasswordValid => password.isNotEmpty;
  bool get isFormValid => isEmailValid && isPasswordValid;

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

  @override
  List<Object?> get props => [email, password, status, error];
}
