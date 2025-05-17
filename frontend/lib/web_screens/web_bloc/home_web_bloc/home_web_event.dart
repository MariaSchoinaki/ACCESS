import 'package:equatable/equatable.dart';

abstract class HomeWebEvent extends Equatable {
  const HomeWebEvent();

  @override
  List<Object> get props => [];
}

class OpenProfile extends HomeWebEvent {}

class OpenReportDialog extends HomeWebEvent {}

class CloseReportDialog extends HomeWebEvent {}

class OpenSettings extends HomeWebEvent {}
