part of '../map_bloc.dart';

extension MapBlocActions on MapBloc {
  Future<void> _onShareLocation(ShareLocationRequested event, Emitter<MapState> emit,) async {
    try {
      final encodedLocation = Uri.encodeComponent(event.location);
      final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$encodedLocation';
      await launchUrl(Uri.parse(googleMapsUrl));
      emit(ActionCompleted());
    } catch (e) {
      emit(ActionFailed("Αποτυχία διαμοιρασμού τοποθεσίας"));
    }
  }

  Future<void> _onLaunchPhoneDialer(LaunchPhoneDialerRequested event, Emitter<MapState> emit,) async {
    try {
      final Uri launchUri = Uri(
        scheme: 'tel',
        path: event.phoneNumber,
      );
      await launchUrl(launchUri);
      emit(ActionCompleted());
    } catch (e) {
      emit(ActionFailed("Αποτυχία κλήσης τηλεφώνου"));
    }
  }
}