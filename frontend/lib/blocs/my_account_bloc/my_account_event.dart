part of 'my_account_bloc.dart';

abstract class MyAccountEvent {}

class LoadUserProfile extends MyAccountEvent {}

class SignOutRequested extends MyAccountEvent {}
