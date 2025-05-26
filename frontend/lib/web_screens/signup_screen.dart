import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:access/web_screens/web_bloc/web_signup_bloc/signup_bloc.dart';
import 'package:access/theme/app_colors.dart';


class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Εγγραφή Δήμου',
          style: textTheme.titleLarge?.copyWith(
            color: AppColors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        iconTheme: IconThemeData(color: colors.onPrimary),
      ),
      body: BlocConsumer<SignupBloc, SignupState>(
        listener: (context, state) {
          if (state is SignupSuccess) {
            Navigator.pushReplacementNamed(context, '/webhome');
          } else if (state is SignupFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: colors.errorContainer,
              ),
            );
          }
        },
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: emailController,
                  style: textTheme.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: Theme.of(context).textTheme.labelLarge,
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: colors.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: colors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: passwordController,
                  obscureText: _obscurePassword,
                  style: textTheme.bodyMedium,
                  decoration: InputDecoration(
                    labelText: 'Κωδικός',
                    labelStyle: Theme.of(context).textTheme.labelLarge,
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: colors.outline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: colors.primary),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Theme.of(context).primaryColor,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                state is SignupLoading
                    ? CircularProgressIndicator(color: Theme.of(context).primaryColor)
                    : ElevatedButton(
                  onPressed: () {
                    context.read<SignupBloc>().add(SignupRequested(
                      email: emailController.text,
                      password: passwordController.text,
                    ));
                  },
                  child: Text(
                    'Εγγραφη',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.black,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Έχεις ήδη λογαριασμό; Σύνδεση',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.black,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}