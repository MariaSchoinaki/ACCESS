import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'my_account_event.dart';
part 'my_account_state.dart';

class MyAccountBloc extends Bloc<MyAccountEvent, MyAccountState> {
  MyAccountBloc() : super(MyAccountInitial()) {
    on<LoadUserProfile>(_onLoadUserProfile);
    on<SignOutRequested>(_onSignOutRequested);
    on<UpdateUserInfo>(_onUpdateUserInfo); // νέο event
  }

  Future<void> _onLoadUserProfile(
      LoadUserProfile event, Emitter<MyAccountState> emit) async {
    emit(MyAccountLoading());
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        emit(MyAccountLoaded(
          email: user.email ?? '',
          photoUrl: user.photoURL,
          dateOfBirth: doc.data()?['dateOfBirth'],
          disabilityType: doc.data()?['disabilityType'],
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

  Future<void> _onUpdateUserInfo(
      UpdateUserInfo event, Emitter<MyAccountState> emit) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'dateOfBirth': event.dateOfBirth,
        'disabilityType': event.disabilityType,
      }, SetOptions(merge: true));

      if (state is MyAccountLoaded) {
        final current = state as MyAccountLoaded;
        emit(MyAccountLoaded(
          email: current.email,
          photoUrl: current.photoUrl,
          dateOfBirth: event.dateOfBirth,
          disabilityType: event.disabilityType,
        ));
      }
    } catch (e) {
      emit(MyAccountError('Failed to update user info.'));
    }
  }
}

