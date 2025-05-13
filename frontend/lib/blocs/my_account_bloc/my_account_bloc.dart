import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'my_account_event.dart';
part 'my_account_state.dart';

/// A BLoC responsible for managing the state
/// and logic related to the user's account information and actions like
/// loading profile data, updating information, and signing out.
class MyAccountBloc extends Bloc<MyAccountEvent, MyAccountState> {

  /// Initializes the BLoC.
  /// Sets the initial state to [MyAccountInitial] and registers event handlers.
  MyAccountBloc() : super(MyAccountInitial()) {
    // Register the handler for loading the user profile.
    on<LoadUserProfile>(_onLoadUserProfile);
    // Register the handler for sign-out requests.
    on<SignOutRequested>(_onSignOutRequested);
    // Register the handler for updating user info (new event).
    on<UpdateUserInfo>(_onUpdateUserInfo); // νέο event (new event)
  }

  /// Handles the [LoadUserProfile] event.
  ///
  /// - Fetches the current authenticated user's data from Firebase Auth
  /// and additional profile details from the Firestore 'users' collection.
  /// - Emits [MyAccountLoading] while fetching, [MyAccountLoaded] on success,
  /// or [MyAccountError] if the user is not logged in or an error occurs.
  Future<void> _onLoadUserProfile(
      LoadUserProfile event, Emitter<MyAccountState> emit) async {
    // Indicate that data loading has started.
    emit(MyAccountLoading());
    try {
      // Get the currently signed-in user from Firebase Authentication.
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // If a user is logged in, fetch their corresponding document from Firestore.
        final doc = await FirebaseFirestore.instance
            .collection('users') // Target the 'users' collection.
            .doc(user.uid)      // Get the document with the user's ID.
            .get();             // Execute the fetch operation.

        // Emit the loaded state with combined data from Auth and Firestore.
        emit(MyAccountLoaded(
          email: user.email ?? '',
          photoUrl: user.photoURL,
          dateOfBirth: doc.data()?['dateOfBirth'],
          disabilityType: doc.data()?['disabilityType'],
        ));
      } else {
        // If no user is logged in, emit an error state.
        emit(MyAccountError('User not logged in.'));
      }
    } catch (e) {
      // Catch any other errors during the process and emit an error state.
      emit(MyAccountError(e.toString()));
    }
  }

  /// Handles the [SignOutRequested] event.
  ///
  /// - Attempts to sign the current user out using Firebase Authentication.
  /// - Emits [MyAccountSignedOut] on successful sign-out,
  /// or [MyAccountError] if the sign-out process fails.
  Future<void> _onSignOutRequested(
      SignOutRequested event, Emitter<MyAccountState> emit) async {
    try {
      await FirebaseAuth.instance.signOut();
      emit(MyAccountSignedOut());
    } catch (e) {
      emit(MyAccountError('Sign out failed.'));
    }
  }

  /// Handles the [UpdateUserInfo] event.
  ///
  /// - Updates the user's `dateOfBirth` and/or `disabilityType` fields
  /// in their Firestore document using `set` with `merge: true`.
  /// - Re-emits [MyAccountLoaded] with the updated information upon success,
  /// or [MyAccountError] if the update fails or the user is not logged in.
  Future<void> _onUpdateUserInfo(
      UpdateUserInfo event, Emitter<MyAccountState> emit) async {
    // Get the current user.
    final user = FirebaseAuth.instance.currentUser;
    // If no user is logged in, do nothing and exit.
    if (user == null) return;

    try {
      // Update the user's document in the 'users' collection.
      // Using set with merge: true ensures only the specified fields are updated
      // and existing fields are preserved.
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        // Update dateOfBirth if provided in the event
        'dateOfBirth': event.dateOfBirth,
        // Update disabilityType if provided in the event.
        'disabilityType': event.disabilityType,
      }, SetOptions(merge: true)); // Use merge option to avoid overwriting other fields.

      // Check if the current state is MyAccountLoaded to access existing data.
      if (state is MyAccountLoaded) {
        // Cast the current state to MyAccountLoaded to access its properties.
        final currentState = state as MyAccountLoaded;
        // Emit a new MyAccountLoaded state with the updated information.
        emit(MyAccountLoaded(
          email: currentState.email,
          photoUrl: currentState.photoUrl,
          dateOfBirth: event.dateOfBirth,
          disabilityType: event.disabilityType,
        ));
      }

    } catch (e) {
      // If updating fails, emit an error state.
      emit(MyAccountError('Failed to update user info.'));
    }
  }
}