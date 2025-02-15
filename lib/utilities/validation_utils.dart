class ValidationUtils {
  // validate email
  static const String emailPattern =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static final RegExp emailRegex = RegExp(emailPattern);

  static bool validateEmail(String email) {
    return emailRegex.hasMatch(email);
  }

  // validate password
  static const String passwordPattern =
      r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{6,20}$';
  static final RegExp passwordRegex = RegExp(passwordPattern);

  static bool validatePassword(String password) {
    return passwordRegex.hasMatch(password);
  }

  // validate mobile
  static const String mobilePattern = r'^(\+88)?01[3-9][0-9]{8}$';
  static final RegExp mobileRegex = RegExp(mobilePattern);

  static bool validateMobile(String mobile) {
    return mobileRegex.hasMatch(mobile);
  }

  static const String linkPattern =
      r'^(https:\/\/www\.|http:\/\/www\.|https:\/\/|http:\/\/)?[a-zA-Z0-9]{2,}(\.[a-zA-Z0-9]{2,})(\.[a-zA-Z0-9]{2,})?$';
  static final RegExp linkRegex = RegExp(linkPattern);

  static bool validateLink(String link) {
    return linkRegex.hasMatch(link);
  }
}
