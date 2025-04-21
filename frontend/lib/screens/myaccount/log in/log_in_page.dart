import 'package:flutter/material.dart';
import '../../../utils/email_validator.dart'; // Εισαγωγή της συνάρτησης επικύρωσης email

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>(); // Κλειδί φόρμας
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true; // Ελέγχει αν ο κωδικός είναι κρυφός ή ορατός

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFFFF6F0),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 48),
                Image.asset('assets/images/logo.png', height: 120),
                const SizedBox(height: 16),
                const Text(
                  'ACCESS',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Log in to your account',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter your email and password to continue',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),

                // Πεδίο email
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
                  validator: (value) => EmailValidator.validate(value),
                ),

                const SizedBox(height: 16),

                // Πεδίο password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword, // Απόκρυψη χαρακτήρων
                  decoration: InputDecoration(
                    hintText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    fillColor: Colors.white,
                    filled: true,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword; // Εναλλαγή εμφάνισης κωδικού
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter your password to continue';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Κουμπί Continue
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        Navigator.pushNamed(context, '/myaccount');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Όροι χρήσης
                const Text.rich(
                  TextSpan(
                    text: 'By clicking continue, you agree to our ',
                    children: [
                      TextSpan(
                        text: 'Terms of Service',
                        style: TextStyle(decoration: TextDecoration.underline),
                      ),
                      TextSpan(text: ' and '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(decoration: TextDecoration.underline),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),

                const SizedBox(height: 32),

                // Εναλλακτική εγγραφής
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Don’t have an account? '),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      child: const Text(
                        'Sign Up',
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
    );
  }
}
