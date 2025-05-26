import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:equatable/equatable.dart';

part 'signup_event.dart';
part 'signup_state.dart';

class SignupBloc extends Bloc<SignupEvent, SignupState> {
  final FirebaseAuth _auth;

  SignupBloc({FirebaseAuth? firebaseAuth})
      : _auth = firebaseAuth ?? FirebaseAuth.instance,
        super(SignupInitial()) {
    on<SignupRequested>(_onSignupRequested);
  }

  Future<void> _onSignupRequested(SignupRequested event, Emitter<SignupState> emit) async {
    emit(SignupLoading());
    try {
      await _auth.createUserWithEmailAndPassword(
        email: event.email.trim(),
        password: event.password,
      );
      emit(SignupSuccess());
    } catch (e) {
      emit(SignupFailure(message: 'Αποτυχία εγγραφής. Δοκίμασε ξανά.'));
    }
  }
}
