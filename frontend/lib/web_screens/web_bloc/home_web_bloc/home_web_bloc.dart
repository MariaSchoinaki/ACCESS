import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_web_event.dart';
import 'home_web_state.dart';

class HomeWebBloc extends Bloc<HomeWebEvent, HomeWebState> {
  HomeWebBloc() : super(const HomeWebState(isReportDialogOpen: false)) {
    on<OpenReportDialog>((event, emit) {
      emit(state.copyWith(isReportDialogOpen: true));
    });

    on<CloseReportDialog>((event, emit) {
      emit(state.copyWith(isReportDialogOpen: false));
    });

    // These are placeholders for future navigation logic
    on<OpenProfile>((event, emit) {
      // Handle profile open logic if needed
    });

    on<OpenSettings>((event, emit) {
      // Handle settings open logic if needed
    });
  }
}
