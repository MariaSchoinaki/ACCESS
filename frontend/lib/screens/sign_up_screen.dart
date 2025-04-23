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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                'assets/images/logo.png',
                height: 120,
              ),
              const SizedBox(height: 12.0),
              const Text(
                'Δημιούργηστε τον λογαριασμό σας',
                style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8.0),
              const Text(
                'Συμπλήρωστε τα στοιχεία σας για να εγγραφείτε',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.0),
              ),
              const SizedBox(height: 16.0),
              BlocBuilder<SignUpBloc, SignUpState>(
                builder: (context, state) {
                  return TextFormField(
                    focusNode: _emailFocusNode,
                    key: const Key('signUpForm_emailInput_textField'),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      errorText: _emailTouched && !state.isEmailValid ? 'Πληκτρολογήστε ένα έγκυρο email' : null,
                      border: theme.inputDecorationTheme.border,
                      errorBorder: theme.inputDecorationTheme.errorBorder,
                      focusedErrorBorder: theme.inputDecorationTheme.focusedErrorBorder,
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
                      labelText: 'Κωδικός Πρόσβασης',
                      errorText: _passwordTouched && !state.isPasswordValid
                          ? 'Ο κωδικός πρέπει να έχει τουλάχιστον 6 χαρακτήρες'
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
                      border: theme.inputDecorationTheme.border,
                      errorBorder: theme.inputDecorationTheme.errorBorder,
                      focusedErrorBorder: theme.inputDecorationTheme.focusedErrorBorder,
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
                      labelText: 'Επιβεβαιώση κωδικού',
                      errorText: _confirmPasswordTouched && !state.isConfirmPasswordValid
                          ? 'Οι κωδικοί πρόσβασης δεν ταιριάζουν'
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
                      border: theme.inputDecorationTheme.border,
                      errorBorder: theme.inputDecorationTheme.errorBorder,
                      focusedErrorBorder: theme.inputDecorationTheme.focusedErrorBorder,
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
                            'Σύνδεση',
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          const SizedBox(height: 16),
                          Row(
                            children: const [
                              Expanded(child: Divider()),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text('ή'),
                              ),
                              Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                context.read<SignUpBloc>().add(SignUpWithGoogleRequested());
                              },
                              icon: Image.asset(
                                'assets/images/google_logo.png',
                                height: 25,
                              ),
                              label: const Text('Εγγραφή με Google'),
                              style: OutlinedButton.styleFrom(
                                backgroundColor: AppColors.white,
                                foregroundColor: AppColors.textPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(color: AppColors.grey),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16.0),
              const Text.rich(
                TextSpan(
                  text: 'Πατώντας συνέχεια, αποδέχεστε τους ',
                  children: [
                    TextSpan(
                      text: 'Όρους Χρήσης',
                      style: TextStyle(decoration: TextDecoration.underline),
                    ),
                    TextSpan(text: ' και την '),
                    TextSpan(
                      text: 'Πολιτική Απορρήτου',
                      style: TextStyle(decoration: TextDecoration.underline),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8.0),
              BlocListener<SignUpBloc, SignUpState>(
                listener: (context, state) {
                  if (state.status.isSuccess) {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        const SnackBar(content: Text('Επιτυχής Σύνδεση!')),
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
                  const Text('Έχετε ήδη λογαριασμό; '),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: const Text(
                      'Συνδεθείτε',
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