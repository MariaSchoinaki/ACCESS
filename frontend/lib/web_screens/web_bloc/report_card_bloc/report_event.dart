part of 'report_bloc.dart';

class ReportEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SubmitReport extends ReportEvent {
  final String location;
  final DateTime startDate;
  final DateTime endDate;
  final String obstacleType;
  final String? damageReport;
  final String? accessibility;
  final double? latitude;
  final double? longitude;

  SubmitReport({
    required this.location,
    required this.startDate,
    required this.endDate,
    required this.obstacleType,
    this.damageReport,
    this.accessibility,
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [
    location,
    startDate,
    endDate,
    obstacleType,
    damageReport,
    accessibility,
    latitude,
    longitude,
  ];
}
