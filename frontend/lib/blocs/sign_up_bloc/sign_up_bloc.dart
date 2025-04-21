import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:email_validator/email_validator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

part 'sign_up_event.dart';
part 'sign_up_state.dart';

class SignUpBloc extends Bloc<SignUpEvent, SignUpState> {
  SignUpBloc() : super(const SignUpState()) {
    on<SignUpEmailChanged>(_onEmailChanged);
    on<SignUpPasswordChanged>(_onPasswordChanged);
    on<SignUpConfirmPasswordChanged>(_onConfirmPasswordChanged);
    on<SignUpSubmitted>(_onSubmitted);
    on<SignUpWithGoogleRequested>(_onGoogleSignInRequested);
    on<SignUpSnackBarShow>(_onSignUpSnackBarShow);
  }

  void _onEmailChanged(SignUpEmailChanged event, Emitter<SignUpState> emit) {
    emit(state.copyWith(email: event.email));
  }

  void _onPasswordChanged(SignUpPasswordChanged event, Emitter<SignUpState> emit) {
    emit(state.copyWith(password: event.password));
  }

  void _onConfirmPasswordChanged(SignUpConfirmPasswordChanged event, Emitter<SignUpState> emit) {
    emit(state.copyWith(confirmPassword: event.confirmPassword));
  }

  Future<void> _onSubmitted(SignUpSubmitted event, Emitter<SignUpState> emit) async {
    if (state.isFormValid) {
      emit(state.copyWith(status: SignUpStatus.submitting));

      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: state.email.trim(),
          password: state.password.trim(),
        );
        emit(state.copyWith(status: SignUpStatus.success));
      } on FirebaseAuthException catch (e) {
        emit(state.copyWith(status: SignUpStatus.failure, errorMessage: _mapFirebaseSignUpErrorToMessage(e.code)));
      } catch (_) {
        emit(state.copyWith(status: SignUpStatus.failure, errorMessage: 'An unexpected error occurred'));
      }
    }
  }


  Future<void> _onGoogleSignInRequested(
      SignUpWithGoogleRequested event,
      Emitter<SignUpState> emit,
      ) async {
    emit(state.copyWith(status: SignUpStatus.submitting));

    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        emit(state.copyWith(status: SignUpStatus.initial)); // canceled
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      emit(state.copyWith(status: SignUpStatus.success));
    } catch (e) {
      emit(state.copyWith(
        status: SignUpStatus.failure,
        errorMessage: 'Google sign-in failed',
      ));
    }
  }

  void _onSignUpSnackBarShow(SignUpSnackBarShow event, Emitter<SignUpState> emit) async {
    emit(state.copyWith(status: SignUpStatus.initial));
  }

  String _mapFirebaseSignUpErrorToMessage(String errorCode) {
    switch (errorCode) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'invalid-email':
        return 'The email provided is not valid.';
      default:
        return 'An error occurred during sign up.';
    }
  }
}