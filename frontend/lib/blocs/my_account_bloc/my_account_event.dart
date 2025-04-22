part of 'my_account_bloc.dart';

abstract class MyAccountEvent {}

class LoadUserProfile extends MyAccountEvent {}

class SignOutRequested extends MyAccountEvent {}

class UpdateUserInfo extends MyAccountEvent {
  final String dateOfBirth;
  final String disabilityType;

  UpdateUserInfo({
    required this.dateOfBirth,
    required this.disabilityType,
  });

  @override
  List<Object> get props => [dateOfBirth, disabilityType];
}