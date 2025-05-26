import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'report_event.dart';
part 'report_state.dart';

class ReportBloc extends Bloc<ReportEvent, ReportState> {
  ReportBloc() : super(ReportInitial()) {
    on<SubmitReport>(_onSubmitReport);
  }

  Future<void> _onSubmitReport(SubmitReport event,
      Emitter<ReportState> emit) async {
    emit(ReportLoading());

    try {
      await FirebaseFirestore.instance.collection('municipal_reports').add({
        'accessibility': event.accessibility,
        'coordinates': GeoPoint(event.coordinates![0], event.coordinates![1]),
        'locationDescription': event.locationDescription,
        'startDate': event.startDate,
        'endDate': event.endDate,
        'needsUpdate': event.needsUpdate,
        'obstacleType': event.obstacleType,
        'needsImprove': event.needsImprove,
        'timestamp': Timestamp.fromDate(event.timestamp),
        'userEmail': event.userEmail,
        'userId': event.userId,
        'description': event.description,
      });

      emit(ReportSuccess());
    } catch (e) {
      emit(ReportFailure(e.toString()));
    }
  }
}
