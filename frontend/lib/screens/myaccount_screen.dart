import 'package:access/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../widgets/bottom_bar.dart';
import '../../blocs/my_account_bloc/my_account_bloc.dart';

class MyAccountScreen extends StatelessWidget {
  const MyAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider(
      create: (_) => MyAccountBloc()..add(LoadUserProfile()),
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text("My Account"),
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
              return Column(
                children: [
                  const SizedBox(height: 30),
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
                  Text(
                    state.email,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  ListTile(
                    leading: const Icon(Icons.route),
                    title: const Text('Saved Routes'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Navigate to Saved Routes
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.palette),
                    title: const Text('Customizable UI'),
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
                      label: const Text('Sign Out'),
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
              return Center(child: Text('Error: ${state.message}'));
            } else {
              return const Center(child: Text("No user data found"));
            }
          },
        ),
        bottomNavigationBar: const BottomNavBar(),
      ),
    );
  }
}
