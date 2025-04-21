
class EmailValidator {

  static String? validate(String? email) {
    if (email == null || email.isEmpty) {
      return 'Please enter an email';
    }
    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    if (!emailRegex.hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }
}
