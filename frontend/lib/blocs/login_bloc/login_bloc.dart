import 'package:email_validator/email_validator.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
part 'login_event.dart';
part 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  LoginBloc() : super(const LoginState()) {
    on<LoginSubmitted>(_onLoginSubmitted);
  }

  Future<void> _onLoginSubmitted(LoginSubmitted event, Emitter<LoginState> emit) async {
    // Αλλαγή της κατάστασης σε loading
    emit(state.copyWith(status: LoginStatus.loading));

    try {
      // Προσπάθεια σύνδεσης με Firebase
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: event.email,
        password: event.password,
      );

      // Αν η σύνδεση είναι επιτυχής, αλλάζουμε την κατάσταση σε success
      emit(state.copyWith(status: LoginStatus.success, email: event.email, password: event.password));

      // Μπορείς να προσθέσεις εδώ την πλοήγηση σε άλλη σελίδα
      // Navigator.pushNamed(context, '/myaccount');
    } catch (e) {
      // Αν παρουσιαστεί σφάλμα, αποτυγχάνει η σύνδεση
      emit(state.copyWith(status: LoginStatus.failure, error: e.toString()));
    }
  }
}