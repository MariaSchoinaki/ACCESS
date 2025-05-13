import 'package:access/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// Import related widgets and BLoC
import '../widgets/bottom_bar.dart';
import '../../blocs/my_account_bloc/my_account_bloc.dart';
import '../widgets/user_info_popup.dart';

/// Displays the user's account information and provides options for
/// editing profile details, viewing saved routes (TODO), customizing the app (TODO),
/// and signing out. It interacts with [MyAccountBloc] to manage state.
class MyAccountScreen extends StatefulWidget {
  /// Creates a const [MyAccountScreen].
  const MyAccountScreen({super.key});

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

/// The state associated with [MyAccountScreen].
class _MyAccountScreenState extends State<MyAccountScreen> {

  /// Flag to ensure the initial info popup is shown only once per screen load
  /// if user information is missing.
  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();

    // Request loading the user profile data when the screen initializes.
    context.read<MyAccountBloc>().add(LoadUserProfile());
  }


  @override
  Widget build(BuildContext context) {

    // Τhe current theme for styling.
    final theme = Theme.of(context);

    // BlocListener for side effects like navigation or showing SnackBars
    // based on state changes, without rebuilding the entire UI.
    return BlocListener<MyAccountBloc, MyAccountState>(
      listener: (context, state) {

        // If the state indicates successful sign-out...
        if (state is MyAccountSignedOut) {

          // Navigate to the login screen, replacing the current screen stack.
          Navigator.pushReplacementNamed(context, '/login');

        // If the state indicates an error...
        } else if (state is MyAccountError) {

          // Show a SnackBar with the error message.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );

        // If the state indicates successful profile update...
        } else if (state is MyAccountUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Τα στοιχεία ενημερώθηκαν!")),
          );
        }
      },
      // The main Scaffold structure of the screen.
      child: Scaffold(
        resizeToAvoidBottomInset: false, // Prevents the screen from resizing when the keyboard appears.
        backgroundColor: theme.scaffoldBackgroundColor,
        /// Title
        appBar: AppBar(
          title: const Text("Ο λογαριασμός μου"),
          centerTitle: true, 
          backgroundColor: theme.appBarTheme.backgroundColor,
          foregroundColor: theme.appBarTheme.foregroundColor,
          elevation: 0,
        ),
        body: BlocBuilder<MyAccountBloc, MyAccountState>(
          builder: (context, state) {

            // Display a loading indicator while data is being fetched.
            if (state is MyAccountLoading) {
              return const Center(child: CircularProgressIndicator());
            // If data is loaded successfully...
            } else if (state is MyAccountLoaded) {

              // Check if essential profile info (DoB, Disability) is missing.
              final hasMissingInfo = state.dateOfBirth == null || state.disabilityType == null;

              // If info is missing AND the dialog hasn't been shown yet in this session...
              if (hasMissingInfo && !_dialogShown) {
                // Set the flag to true to prevent showing it again immediately.
                _dialogShown = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  showDialog(
                    context: context,
                    barrierDismissible: false, //Requires completion
                    builder: (dialogContext) => UserInfoPopup(
                      // Callback function executed when the popup's form is submitted.
                          onSubmit: (birthDate, disabilityType) {
                            context.read<MyAccountBloc>().add(UpdateUserInfo(
                                dateOfBirth: birthDate,disabilityType: disabilityType,
                              ),);
                      // Close the dialog after submitting
                            Navigator.of(
                              dialogContext,
                            ).pop();
                          },
                      // Pass current values to the popup.
                          initialBirthDate:state.dateOfBirth,
                          initialDisability: state.disabilityType,
                        ),
                  );
                });
              }

              /// main content column when data is loaded.
              return Column(
                children: [
                  const SizedBox(height: 40),
                  /// User's profile picture
                  CircleAvatar(
                    radius: 50,
                    // Load image from URL if available.
                    backgroundImage: state.photoUrl != null
                        ? NetworkImage(state.photoUrl!)
                        : null, // Otherwise, no background image.
                    // Show person icon if photoUrl is null.
                    child: state.photoUrl == null
                        ? const Icon(Icons.person, size: 50)
                        : null, // Otherwise, show nothing (backgroundImage is used).
                  ),
                  const SizedBox(height: 12),
                  /// Edit Info Button
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.primaryAccent.shade100,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text("Τροποποίηση στοιχείων", style: TextStyle(fontSize: 13)),
                    onPressed: () {
                      // Get the current state
                      final currentState = context.read<MyAccountBloc>().state
                      as MyAccountLoaded;
                      // Show the UserInfoPopup for editing.
                      showDialog(
                        context: context,

                        builder: (dialogContext) => UserInfoPopup(
                              onSubmit: (birthDate, disabilityType) {
                                context.read<MyAccountBloc>().add(UpdateUserInfo(dateOfBirth: birthDate,
                                    disabilityType: disabilityType,
                                  ),
                                );
                              },
                              // Pre-fill with current data from state.
                              initialBirthDate: currentState.dateOfBirth,
                              initialDisability: currentState.disabilityType,
                            ),
                      );
                    },
                  ),
                  const SizedBox(height: 30),
                  /// User's Info
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        /// Email
                        infoRow(Icons.email, "Email:", state.email),
                        /// Date of Birth
                        if (state.dateOfBirth != null)
                          infoRow(Icons.calendar_today, "Ημερομηνία Γέννησης:", state.dateOfBirth!),
                        /// Mobility kind
                        if (state.disabilityType != null)
                          infoRow(Icons.accessibility_new, "Είδος κινητικής δυσκολίας:", state.disabilityType!),

                        const SizedBox(height: 30),

                        // Action item for navigating to Saved Routes (TODO).
                        ListTile(
                          leading: const Icon(Icons.route),
                          title: const Text('Αποθηκευμένες Διαδρομές'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            ///TODO: Implement navigation to the saved routes screen.
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Η λειτουργία "Αποθηκευμένες Διαδρομές" θα υλοποιηθεί σύντομα!'),
                              ),
                            );
                          },
                        ),
                        // Action item for navigating to App Customization (TODO).
                        ListTile(
                          leading: const Icon(Icons.palette),
                          title: const Text('Προσαρμογή Εφαρμογής'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            ///TODO: Implement navigation to theme/appearance customization screen.
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Η λειτουργία "Προσαρμογή Εφαρμογής" θα υλοποιηθεί σύντομα!'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // Sign Out button at the bottom.
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.logout),
                      label: const Text('Αποσύνδεση'),
                      onPressed: () {
                        // Dispatch the sign-out event to the BLoC.
                        context.read<MyAccountBloc>().add(SignOutRequested());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryAccent.shade200,
                        foregroundColor: AppColors.whiteAccent.shade100,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ),
                ],
              );
            // If there was an error loading data
            } else if (state is MyAccountError) {
              return Center(child: Text('Κάτι πήγε λάθος. ${state.message}'));
            }
            // Fallback case if state is none of the above
            return const SizedBox.shrink();
          },
        ),
        // Add the bottom navigation bar.
        bottomNavigationBar: const BottomNavBar(),
      ),
    );
  }

  /// Helper method to build a consistent row for displaying user information.
  /// Takes an [icon], a [label] string, and a [value] string.
  Widget infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}