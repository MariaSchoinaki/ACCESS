part of 'home_web_bloc.dart';

class HomeWebState extends Equatable {
  final bool isReportDialogOpen;

  const HomeWebState({required this.isReportDialogOpen});

  HomeWebState copyWith({bool? isReportDialogOpen}) {
    return HomeWebState(
      isReportDialogOpen: isReportDialogOpen ?? this.isReportDialogOpen,
    );
  }

  @override
  List<Object> get props => [isReportDialogOpen];
}
