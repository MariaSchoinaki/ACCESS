import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:equatable/equatable.dart';

part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final FirebaseAuth _auth;

  LoginBloc({FirebaseAuth? firebaseAuth})
      : _auth = firebaseAuth ?? FirebaseAuth.instance,
        super(LoginInitial()) {
    on<LoginRequested>(_onLoginRequested);
  }

  Future<void> _onLoginRequested(LoginRequested event, Emitter<LoginState> emit) async {
    emit(LoginLoading());
    try {
      await _auth.signInWithEmailAndPassword(
        email: event.email.trim(),
        password: event.password,
      );
      emit(LoginSuccess());
    } catch (e) {
      emit(LoginFailure(message: 'Αποτυχία σύνδεσης. Έλεγξε τα στοιχεία σου.'));
    }
  }
}
