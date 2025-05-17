import 'package:equatable/equatable.dart';

abstract class ReportState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ReportInitial extends ReportState {}

class ReportLoading extends ReportState {}

class ReportSuccess extends ReportState {}

class ReportFailure extends ReportState {
  final String error;

  ReportFailure(this.error);

  @override
  List<Object?> get props => [error];
}
