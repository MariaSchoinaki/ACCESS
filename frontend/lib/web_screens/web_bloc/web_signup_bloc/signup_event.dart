part of 'signup_bloc.dart';

abstract class SignupEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class SignupRequested extends SignupEvent {
  final String email;
  final String password;

  SignupRequested({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}
