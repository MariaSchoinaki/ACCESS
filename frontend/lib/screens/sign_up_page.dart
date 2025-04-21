import 'package:access/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:access/blocs/sign_up_bloc/sign_up_bloc.dart';
import '../widgets/bottom_bar.dart';

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SignUpBloc(),
      child: const SignUpView(),
    );
  }
}

class SignUpView extends StatefulWidget {
  const SignUpView({Key? key}) : super(key: key);

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  bool _emailTouched = false;
  bool _passwordTouched = false;
  bool _confirmPasswordTouched = false;
  bool _passwordObscured = true;
  bool _confirmPasswordObscured = true;


  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      if (_emailFocusNode.hasFocus) {
        setState(() => _emailTouched = true);
      }
    });
    _passwordFocusNode.addListener(() {
      if (_passwordFocusNode.hasFocus) {
        setState(() => _passwordTouched = true);
      }
    });
    _confirmPasswordFocusNode.addListener(() {
      if (_confirmPasswordFocusNode.hasFocus) {
        setState(() => _confirmPasswordTouched = true);
      }
    });
  }

  @override
  void dispose() {
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).inputDecorationTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(48.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                'assets/images/logo.png',
                height: 120,
              ),
              const SizedBox(height: 12.0),
              const Text(
                'Create an account',
                style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              const Text(
                'Enter your details to sign up',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16.0, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16.0),
              BlocBuilder<SignUpBloc, SignUpState>(
                builder: (context, state) {
                  return TextFormField(
                    focusNode: _emailFocusNode,
                    key: const Key('signUpForm_emailInput_textField'),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      errorText: _emailTouched && !state.isEmailValid ? 'Please enter a valid email' : null,
                      border: theme.border,
                      errorBorder: theme.errorBorder,
                      focusedErrorBorder: theme.focusedErrorBorder,
                      fillColor: AppColors.white,
                      filled: true,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (email) => context.read<SignUpBloc>().add(SignUpEmailChanged(email)),
                  );
                },
              ),
              const SizedBox(height: 16.0),
              BlocBuilder<SignUpBloc, SignUpState>(
                builder: (context, state) {
                  return TextFormField(
                    focusNode: _passwordFocusNode,
                    key: const Key('signUpForm_passwordInput_textField'),
                    obscureText: _passwordObscured,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      errorText: _passwordTouched && !state.isPasswordValid
                          ? 'Password must be at least 6 characters'
                          : null,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordObscured ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _passwordObscured = !_passwordObscured;
                          });
                        },
                      ),
                      border: theme.border,
                      errorBorder: theme.errorBorder,
                      focusedErrorBorder: theme.focusedErrorBorder,
                      fillColor: AppColors.white,
                      filled: true,
                    ),
                    onChanged: (password) => context.read<SignUpBloc>().add(SignUpPasswordChanged(password)),
                  );
                },
              ),
              const SizedBox(height: 16.0),
              BlocBuilder<SignUpBloc, SignUpState>(
                builder: (context, state) {
                  return TextFormField(
                    focusNode: _confirmPasswordFocusNode,
                    obscureText: _confirmPasswordObscured,
                    key: const Key('signUpForm_confirmPasswordInput_textField'),
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      errorText: _confirmPasswordTouched && !state.isConfirmPasswordValid
                          ? 'Passwords do not match'
                          : null,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _confirmPasswordObscured ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _confirmPasswordObscured = !_confirmPasswordObscured;
                          });
                        },
                      ),
                      border: theme.border,
                      errorBorder: theme.errorBorder,
                      focusedErrorBorder: theme.focusedErrorBorder,
                      fillColor: AppColors.white,
                      filled: true,
                    ),
                    onChanged: (confirmPassword) => context.read<SignUpBloc>().add(SignUpConfirmPasswordChanged(confirmPassword)),
                  );
                },
              ),
              const SizedBox(height: 24.0),
              BlocBuilder<SignUpBloc, SignUpState>(
                builder: (context, state) {
                  return Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          key: const Key('signUpForm_continue_raisedButton'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          onPressed: state.isFormValid
                              ? () => context.read<SignUpBloc>().add(SignUpSubmitted())
                              : null,
                          child: state.status.isSubmitting
                              ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                              : const Text(
                            'Sign Up',
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          const SizedBox(height: 12.0),
                          const Text(
                            'or',
                            style: TextStyle(fontSize: 14.0, color: Colors.grey),
                          ),
                          const SizedBox(height: 12.0),
                          GestureDetector(
                            onTap: () {
                              context.read<SignUpBloc>().add(SignUpWithGoogleRequested());
                            },
                            child: Image.asset(
                              'assets/images/android_signup.png',
                              height: 55.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16.0),
              const Text(
                'By signing up, you agree to our Terms of Service and Privacy Policy',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.0, color: Colors.grey),
              ),
              const SizedBox(height: 8.0),
              BlocListener<SignUpBloc, SignUpState>(
                listener: (context, state) {
                  if (state.status.isSuccess) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(content: Text('Sign Up Successful!')),
                      );
                    Navigator.of(context).pushReplacementNamed('/myaccount');
                  }  else if (state.status == SignUpStatus.failure) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(content: Text(state.errorMessage)),
                      );
                    context.read<SignUpBloc>().add(SignUpSnackBarShow());
                  }
                },
                child: Container(),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? '),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/login');
                    },
                    child: const Text(
                      'Log in',
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}

extension on SignUpStatus {
  bool get isInitial => this == SignUpStatus.initial;
  bool get isSubmitting => this == SignUpStatus.submitting;
  bool get isSuccess => this == SignUpStatus.success;
  bool get isFailure => this == SignUpStatus.failure;
}