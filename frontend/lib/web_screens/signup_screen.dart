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
  final TextEditingController dimosNameController = TextEditingController();
  final TextEditingController dimosTKController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  void _updateState() => setState(() {});

  @override
  void initState() {
    super.initState();
    emailController.addListener(_updateState);
    passwordController.addListener(_updateState);
    dimosNameController.addListener(_updateState);
    dimosTKController.addListener(_updateState);
    confirmPasswordController.addListener(_updateState);
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    dimosNameController.dispose();
    dimosTKController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _areFieldsValid =>
      emailController.text.isNotEmpty &&
          passwordController.text.isNotEmpty &&
          confirmPasswordController.text.isNotEmpty &&
          dimosNameController.text.isNotEmpty &&
          dimosTKController.text.isNotEmpty &&
          passwordController.text == confirmPasswordController.text;

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
        automaticallyImplyLeading: false,
      ),
      body: BlocConsumer<SignupBloc, SignupState>(
        listener: (context, state) {
          if (state is SignupSuccess) {
            Navigator.pushNamedAndRemoveUntil(
                context, '/webhome', (route) => false);
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
                // Email Field
                TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email *',
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: colors.outline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: colors.primary),
                      ),
                    ),
            ),
                    const SizedBox(height: 20),

                    // Password Field
                    TextField(
                      controller: passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Κωδικός *',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color:  AppColors.primary,
                          ),
                          onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Confirm Password Field
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      decoration: InputDecoration(
                        labelText: 'Επιβεβαίωση Κωδικού *',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: AppColors.primary,
                          ),
                          onPressed: () => setState(
                                  () => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Municipality Name
                    TextField(
                      controller: dimosNameController,
                      decoration: InputDecoration(
                        labelText: 'Όνομα Δήμου *',
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Postal Code
                    TextField(
                      controller: dimosTKController,
                      decoration: InputDecoration(
                        labelText: 'Ταχυδρομικός Κώδικας *',
                      ),
                    ),

                    const SizedBox(height: 30),
                if (passwordController.text.isNotEmpty &&
                confirmPasswordController.text.isNotEmpty &&
                passwordController.text != confirmPasswordController.text)
                Text(
                  'Οι κωδικοί δεν ταιριάζουν',
                  style: TextStyle(color: colors.error),
                ),

                const SizedBox(height: 20),

                // Submit Button
                state is SignupLoading
                    ? CircularProgressIndicator(color: colors.primary)
                    : ElevatedButton(
                  onPressed: _areFieldsValid
                      ? () {
                    context.read<SignupBloc>().add(SignupRequested(
                      email: emailController.text,
                      password: passwordController.text,
                      confirmPassword: confirmPasswordController.text,
                      dimosName: dimosNameController.text,
                      dimosTK: dimosTKController.text,
                    ));
                  }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _areFieldsValid
                        ? AppColors.primary
                        : AppColors.black.withOpacity(0.12),
                  ),
                  child: Text('Εγγραφή'),
                ),

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Έχεις ήδη λογαριασμό; Σύνδεση'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}