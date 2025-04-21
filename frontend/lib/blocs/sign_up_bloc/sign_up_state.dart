part of 'sign_up_bloc.dart';

enum SignUpStatus { initial, submitting, success, failure }

class SignUpState extends Equatable {
  const SignUpState({
    this.status = SignUpStatus.initial,
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.errorMessage = '',
  });

  final SignUpStatus status;
  final String email;
  final String password;
  final String confirmPassword;
  final String errorMessage;

  bool get isEmailValid => EmailValidator.validate(email);
  bool get isPasswordValid => password.isNotEmpty && password.length >= 6;
  bool get isConfirmPasswordValid => password == confirmPassword && confirmPassword.isNotEmpty;
  bool get isFormValid => isEmailValid && isPasswordValid && isConfirmPasswordValid;

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