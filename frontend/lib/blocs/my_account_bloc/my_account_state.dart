part of 'my_account_bloc.dart';

abstract class MyAccountState {}

class MyAccountInitial extends MyAccountState {}

class MyAccountLoading extends MyAccountState {}

class MyAccountLoaded extends MyAccountState {
  final String email;
  final String? photoUrl;
  final String? dateOfBirth;
  final String? disabilityType;

  MyAccountLoaded({
    required this.email,
    this.photoUrl,
    this.dateOfBirth,
    this.disabilityType,
  });
}

class MyAccountUpdated extends MyAccountState {
  final String dateOfBirth;
  final String disabilityType;

  MyAccountUpdated({
    required this.dateOfBirth,
    required this.disabilityType,
  });

  @override
  List<Object> get props => [dateOfBirth, disabilityType];
}

class MyAccountSignedOut extends MyAccountState {}

class MyAccountError extends MyAccountState {
  final String message;

  MyAccountError(this.message);
}

