import 'package:equatable/equatable.dart';

class ReportEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SubmitReport extends ReportEvent {
  final String location;
  final DateTime startDate;
  final DateTime endDate;
  final String projectType;
  final String? damageReport;

  SubmitReport({
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.projectType,
    this.damageReport,
  });

  @override
  List<Object?> get props => [location, startDate, endDate, projectType, damageReport];
}
