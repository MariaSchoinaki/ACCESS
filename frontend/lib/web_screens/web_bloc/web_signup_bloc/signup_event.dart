part of 'signup_bloc.dart';

abstract class SignupEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class SignupRequested extends SignupEvent {
  final String email;
  final String password;
  final String confirmPassword;
  final String dimosName;
  final String dimosTK;

  SignupRequested({
    required this.email,
    required this.password,
    required this.confirmPassword,
    required this.dimosName,
    required this.dimosTK
  });

  @override
  List<Object> get props => [email, password, confirmPassword, dimosName, dimosTK];
}
