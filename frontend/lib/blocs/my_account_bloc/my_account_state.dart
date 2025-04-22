part of 'my_account_bloc.dart';

abstract class MyAccountState {}

class MyAccountInitial extends MyAccountState {}

class MyAccountLoading extends MyAccountState {}

class MyAccountLoaded extends MyAccountState {
  final String email;
  final String? photoUrl;

  MyAccountLoaded({required this.email, this.photoUrl});
}

class MyAccountSignedOut extends MyAccountState {}

class MyAccountError extends MyAccountState {
  final String message;

  MyAccountError(this.message);
}
