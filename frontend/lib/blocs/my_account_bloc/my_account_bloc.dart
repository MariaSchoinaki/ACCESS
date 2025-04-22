import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
part 'my_account_event.dart';
part 'my_account_state.dart';

class MyAccountBloc extends Bloc<MyAccountEvent, MyAccountState> {
  MyAccountBloc() : super(MyAccountInitial()) {
    on<LoadUserProfile>(_onLoadUserProfile);
    on<SignOutRequested>(_onSignOutRequested);
  }

  Future<void> _onLoadUserProfile(
      LoadUserProfile event, Emitter<MyAccountState> emit) async {
    emit(MyAccountLoading());
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        emit(MyAccountLoaded(
          email: user.email ?? '',
          photoUrl: user.photoURL,
        ));
      } else {
        emit(MyAccountError('User not logged in.'));
      }
    } catch (e) {
      emit(MyAccountError(e.toString()));
    }
  }

  Future<void> _onSignOutRequested(
      SignOutRequested event, Emitter<MyAccountState> emit) async {
    try {
      await FirebaseAuth.instance.signOut();
      emit(MyAccountSignedOut());
    } catch (e) {
      emit(MyAccountError('Sign out failed.'));
    }
  }
}
