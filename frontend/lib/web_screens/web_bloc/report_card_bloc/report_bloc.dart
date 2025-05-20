import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
part 'report_event.dart';
part 'report_state.dart';

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  ReportBloc() : super(ReportInitial()) {
    on<SubmitReport>(_onSubmitReport);
  }

  Future<void> _onSubmitReport(SubmitReport event, Emitter<ReportState> emit) async {
    emit(ReportLoading());

    try {
      await FirebaseFirestore.instance.collection('municipal_reports').add({
        'location': event.location,
        'startDate': event.startDate,
        'endDate': event.endDate,
        'obstacleType': event.obstacleType,
        'damageReport': event.damageReport,
        'accessibility': event.accessibility,
        'latitude': event.latitude,
        'longitude': event.longitude,
        'createdAt': Timestamp.now(),
      });

      emit(ReportSuccess());
    } catch (e) {
      emit(ReportFailure(e.toString()));
    }
  }
}