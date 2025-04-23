import 'package:access/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../widgets/bottom_bar.dart';
import '../../blocs/my_account_bloc/my_account_bloc.dart';
import '../widgets/user_info_popup.dart';

class MyAccountScreen extends StatelessWidget {
  const MyAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocListener<MyAccountBloc, MyAccountState>(
        listener: (context, state) {
          if (state is MyAccountSignedOut) {
            Navigator.pushReplacementNamed(context, '/login');
          } else if (state is MyAccountError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is MyAccountUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Τα στοιχεία ενημερώθηκαν!")),
            );
            Navigator.pushReplacementNamed(context, '/profile');
          }
        },
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: const Text("Ο λογαριασμός μου"),
            centerTitle: true,
            backgroundColor: theme.appBarTheme.backgroundColor,
            foregroundColor: theme.appBarTheme.foregroundColor,
            elevation: 0,
          ),
          body: BlocBuilder<MyAccountBloc, MyAccountState>(
            builder: (context, state) {
              if (state is MyAccountLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is MyAccountLoaded) {
                if (state.dateOfBirth == null || state.disabilityType == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    showDialog(
                      context: context,
                      builder: (context) => UserInfoPopup(
                        onSubmit: (birthDate, disabilityType) {
                          context.read<MyAccountBloc>().add(UpdateUserInfo(
                            dateOfBirth: birthDate,
                            disabilityType: disabilityType,
                          ));
                        },
                      ),
                    );
                  });
                }

                return Column(
                  children: [
                    const SizedBox(height: 40),
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: state.photoUrl != null
                          ? NetworkImage(state.photoUrl!)
                          : null,
                      child: state.photoUrl == null
                          ? const Icon(Icons.person, size: 50)
                          : null,
                    ),
                    const SizedBox(height: 12),
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
                        showDialog(
                          context: context,
                          builder: (context) => UserInfoPopup(
                            onSubmit: (birthDate, disabilityType) {
                              context.read<MyAccountBloc>().add(UpdateUserInfo(
                                dateOfBirth: birthDate,
                                disabilityType: disabilityType,
                              ));
                            },
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          infoRow(Icons.email, "Email:", state.email),
                          if (state.dateOfBirth != null)
                            infoRow(Icons.calendar_today, "Ημερομηνία Γέννησης:", state.dateOfBirth!),
                          if (state.disabilityType != null)
                            infoRow(Icons.accessibility_new, "Είδος αναπηρίας:", state.disabilityType!),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    ListTile(
                      leading: const Icon(Icons.route),
                      title: const Text('Αποθηκευμένες Διαδρομές'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Navigate to Saved Routes
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.palette),
                      title: const Text('Προσαρμογή Εφαρμογής'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // TODO: Navigate to Customizable UI settings
                      },
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.logout),
                        label: const Text('Αποσύνδεση'),
                        onPressed: () {
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
              } else if (state is MyAccountError) {
                return Center(child: Text('Κάτι πήγε λάθος. ${state.message}'));
              }
              return const Center(child: Text(" Ο λογαριασμός δεν βρέθηκε."));
            },
          ),
          bottomNavigationBar: const BottomNavBar(),
        ),
    );
  }

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
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(value),
            ),
          ),
        ],
      ),
    );
  }
}
