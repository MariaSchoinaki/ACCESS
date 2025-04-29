import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/login_bloc/login_bloc.dart';
import '../theme/app_colors.dart';
import '../widgets/bottom_bar.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Main widget for the Login route.
/// Handles auto-login check & provides [LoginBloc].
class LoginScreen extends StatelessWidget {

  LoginScreen({super.key});

  final storage = FlutterSecureStorage();
  /// Checks storage & navigates if logged in.
  Future<void> _checkIfUserIsLoggedIn(BuildContext context) async {
    final String? isLoggedIn = await storage.read(key: 'isLoggedIn');

    if (isLoggedIn == 'true') {
      Navigator.pushReplacementNamed(context, '/myaccount');
    }
  }


  @override
  Widget build(BuildContext context) {
    _checkIfUserIsLoggedIn(context);

    /// Provides [LoginBloc] to [_LoginView].
    return BlocProvider(
      create: (context) => LoginBloc(),
      child: const _LoginView(),
    );
  }
}

/// Login form UI.
class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => __LoginViewState();
}

/// Manages login form state.
class __LoginViewState extends State<_LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  /// Builds the login form UI.
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        /// Listens to [LoginState] for navigation/errors.
        child: BlocListener<LoginBloc, LoginState>(
          listener: (context, state) {
            if (state.status == LoginStatus.success) {
              Navigator.pushReplacementNamed(context, '/myaccount');
            }
            if (state.status == LoginStatus.failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.error)),
              );
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 48),
                  /// App logo
                  Image.asset('assets/images/logo.png', height: 120),
                  const SizedBox(height: 24),
                  /// Title
                  const Text(
                    'Συνδεθείτε στον λογαριασμό σας',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  /// Subtitle
                  const Text(
                    textAlign: TextAlign.center,
                    'Εισάγετε το email και τον κωδικό σας για να συνεχίσετε',
                    style: TextStyle(
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 24),
                  /// Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'email@domain.com',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      fillColor: Colors.white,
                      filled: true,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Πληκρολόγηστε το email σας';
                      }
                      if (!EmailValidator.validate(value)) {
                        return 'Πληκτρολογήστε ένα έγκυρο email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  /// Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Κωδικός Πρόσβασης',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      fillColor: Colors.white,
                      filled: true,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Πληκτρολόγηστε τον κωδικό σας';
                      }
                      if (value.length < 6) {
                        return 'Ο κωδικός πρέπει να έχει τουλάχιστον 6 χαρακτήρες';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),
                  /// Login buttons & status.
                  BlocBuilder<LoginBloc, LoginState>(
                    builder: (context, state) {
                      return Column(
                        children: [
                          /// Email/Password Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: state.status == LoginStatus.loading // Disable while loading
                                  ? null
                                  : () {
                                if (_formKey.currentState!.validate()) {
                                  context.read<LoginBloc>().add(
                                    LoginSubmitted(
                                      email: _emailController.text,
                                      password: _passwordController.text,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: state.status == LoginStatus.loading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                'Συνέχεια',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          /// or text
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

                          /// Google Log In Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                context.read<LoginBloc>().add(LoginWithGoogleSubmitted());
                              },
                              icon: Image.asset(
                                'assets/images/google_logo.png',
                                height: 25,
                              ),
                              label: const Text('Σύνδεση με Google'),
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
                      );
                    },
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Δεν έχετε λογαριασμό; '),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, '/signup');
                        },
                        child: const Text(
                          'Εγγραφείτε',
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
      /// Bottom navigation bar.
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}
