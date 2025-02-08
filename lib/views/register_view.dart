import 'package:flutter/material.dart';
import 'package:guardix/constants/colors.dart';
import 'package:guardix/constants/routes.dart';
import 'package:guardix/service/auth/auth_exception.dart';
import 'package:guardix/service/auth/auth_service.dart';
import 'package:guardix/service/cloud/firebase_cloud_storage.dart';
import 'package:guardix/utilities/decorations/input_decoration_template.dart';
import 'package:guardix/utilities/dialogs/error_dialog.dart';
import 'package:guardix/utilities/validation_utils.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _password;
  late final TextEditingController _confirmPassword;

// Will show message if email is not valid at the bottom of the text field
  String _nameErrorText = '';
  String _emailErrorText = '';
  String _mobileErrorText = '';
  String _passwordErrorText = '';
  String _confirmPasswordErrorText = '';

  bool _nameNotEmpty = false;
  bool _emailValid = false;
  bool _mobileValid = false;
  bool _passwordValid = false;
  bool _confirmPasswordValid = false;

  bool isButtonActive = false;

  @override
  void initState() {
    _name = TextEditingController();
    _email = TextEditingController();
    _phone = TextEditingController();
    _password = TextEditingController();
    _confirmPassword = TextEditingController();

    _name.addListener(() {
      final String value = _name.text;

      setState(() {
        if (value.isNotEmpty) {
          _nameErrorText = '';
          _nameNotEmpty = true;
        } else {
          _nameErrorText = 'Please enter your name';
        }

        isButtonActive = _nameNotEmpty &&
            _emailValid &&
            _mobileValid &&
            _passwordValid &&
            _confirmPasswordValid;
      });
    });

    _email.addListener(() {
      final String value = _email.text;
      // Update the error text based on validation
      setState(() {
        if (value.isNotEmpty && ValidationUtils.validateEmail(value)) {
          _emailErrorText = '';
          _emailValid = true;
        } else {
          _emailErrorText = value.isEmpty
              ? 'Please enter your  email address'
              : 'Please enter a valid  email address';
          _emailValid = false;
        }

        isButtonActive = _nameNotEmpty &&
            _emailValid &&
            _mobileValid &&
            _passwordValid &&
            _confirmPasswordValid;
      });
    });
    _phone.addListener(() {
      final String value = _phone.text;

      // Update the error text based on validation
      setState(() {
        if (value.isNotEmpty && ValidationUtils.validateMobile(value)) {
          _mobileErrorText = '';
          _mobileValid = true;
        } else {
          _mobileErrorText = value.isEmpty
              ? 'Please enter your mobile nummber'
              : 'Please enter a valid mobile number';
          _mobileValid = false;
        }
        isButtonActive = _nameNotEmpty &&
            _emailValid &&
            _mobileValid &&
            _passwordValid &&
            _confirmPasswordValid;
      });
    });
    _password.addListener(
      () {
        final String value = _password.text;
        // Update the error text based on validation
        setState(() {
          if (value.isNotEmpty && ValidationUtils.validatePassword(value)) {
            _passwordErrorText = '';
            _passwordValid = true;
          } else {
            _passwordErrorText = value.isEmpty
                ? 'Please enter a strong password'
                : 'Use at least an uppercase, a lowercase, a special character and a number. The length should be at least 6 and not more than 20';
            _passwordValid = false;
          }
          isButtonActive = _nameNotEmpty &&
              _emailValid &&
              _mobileValid &&
              _passwordValid &&
              _confirmPasswordValid;
        });
      },
    );
    _confirmPassword.addListener(
      () {
        final String value = _confirmPassword.text;
        // Update the error text based on validation
        setState(() {
          final password = _password.text;
          final confirmPassword = _confirmPassword.text;
          if (confirmPassword.isNotEmpty &&
              (confirmPassword.compareTo(password) == 0)) {
            _confirmPasswordErrorText = '';
            _confirmPasswordValid = true;
          } else {
            _confirmPasswordErrorText = value.isEmpty
                ? 'Please confirm your password'
                : 'Passwords not matched';
            _confirmPasswordValid = false;
          }
          isButtonActive = _nameNotEmpty &&
              _emailValid &&
              _mobileValid &&
              _passwordValid &&
              _confirmPasswordValid;
        });
      },
    );

    super.initState();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(22.0),
        child: SingleChildScrollView(
          child: Column(
            // Aligns the children to the left
            children: [
              const SizedBox(height: 40),
              const Text(
                'Create Account',
                style: TextStyle(
                  color: midnightBlueColor,
                  fontSize: 33,
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'Join The Movement of "Safer Communities"',
                  style: TextStyle(
                    color: blackColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _name,
                enableSuggestions: false,
                autocorrect: false,
                keyboardType: TextInputType.name,
                decoration: buildInputDecoration(label: 'Name'),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 1.0, left: 16.0),
                child: Align(
                  alignment: Alignment
                      .centerLeft, // Aligns the error message to the left
                  child: Text(
                    _nameErrorText,
                    style:
                        const TextStyle(color: crimsonRedColor, fontSize: 10),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _email,
                enableSuggestions: false,
                autocorrect: false,
                keyboardType: TextInputType.emailAddress,
                decoration: buildInputDecoration(label: 'Email'),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 1.0, left: 16.0),
                child: Align(
                  alignment: Alignment
                      .centerLeft, // Aligns the error message to the left
                  child: Text(
                    _emailErrorText,
                    style:
                        const TextStyle(color: crimsonRedColor, fontSize: 10),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phone,
                enableSuggestions: true,
                autocorrect: false,
                keyboardType: TextInputType.phone,
                decoration: buildInputDecoration(label: 'Mobile Number'),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 1.0, left: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _mobileErrorText,
                    style:
                        const TextStyle(color: crimsonRedColor, fontSize: 10),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _password,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                keyboardType: TextInputType.text,
                decoration: buildInputDecoration(label: 'Password'),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 1.0, left: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _passwordErrorText,
                    style:
                        const TextStyle(color: crimsonRedColor, fontSize: 10),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _confirmPassword,
                obscureText: true,
                enableSuggestions: false,
                autocorrect: false,
                decoration: buildInputDecoration(label: 'Confirm Password'),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 1.0, left: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _confirmPasswordErrorText,
                    style:
                        const TextStyle(color: crimsonRedColor, fontSize: 10),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isButtonActive
                          ? () async {
                              final name = _name.text;
                              final email = _email.text;
                              final phone = _phone.text;
                              final password = _password.text;
                              final confirmPassword = _confirmPassword.text;

                              if (password.compareTo(confirmPassword) != 0) {
                                _confirmPasswordErrorText =
                                    'Passwords not matched';
                                _confirmPasswordValid = false;
                                isButtonActive = false;
                                _confirmPassword.text = '';
                                _confirmPasswordErrorText =
                                    'Passwords not matched';
                              } else if (_nameNotEmpty &&
                                  _emailValid &&
                                  _mobileValid &&
                                  _passwordValid &&
                                  _confirmPasswordValid &&
                                  (password.compareTo(confirmPassword) == 0)) {
                                try {
                                  await AuthService.firebase().createUser(
                                    email: email,
                                    password: password,
                                  );

                                  AuthService.firebase()
                                      .sendEmailVerification();

                                  FirebaseCloudStorage().createNewUser(
                                      userName: name,
                                      email: email,
                                      phone: phone,
                                      isAdmin: false);

                                  if (context.mounted) {
                                    Navigator.of(context)
                                        .pushNamed(verifyEmailRoute);
                                  }
                                } on EmailAlreadyInUseAuthException catch (_) {
                                  if (context.mounted) {
                                    await showErrorDialog(
                                      context,
                                      'Email is already in use',
                                    );
                                  }
                                } on InvalidEmailAuthException catch (_) {
                                  if (context.mounted) {
                                    await showErrorDialog(
                                      context,
                                      'Invalid Email',
                                    );
                                  }
                                } on GenericAuthException catch (_) {
                                  if (context.mounted) {
                                    await showErrorDialog(
                                      context,
                                      'Failed to register',
                                    );
                                  }
                                }
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: midnightBlueColor,
                        elevation: 2,
                        shadowColor: midnightBlueColor,
                        foregroundColor: whiteColor,
                        textStyle: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Sign up'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    loginRoute,
                    (route) => false,
                  );
                },
                style: TextButton.styleFrom(
                  textStyle: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Already have an account?',
                  style: TextStyle(
                    color: skyBlueColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 55),
              const Text(
                'Or continue with',
                style: TextStyle(
                  color: blackColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: lightGreyColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          vertical: 11, horizontal: 20),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Image.asset(
                      'assets/images/google_icon.png',
                      width: 22,
                      height: 22,
                      color: midnightBlueColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: lightGreyColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Image.asset(
                      'assets/images/facebook_icon.png',
                      width: 22,
                      height: 22,
                      color: midnightBlueColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: lightGreyColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Image.asset(
                      'assets/images/apple_icon.png',
                      width: 22,
                      height: 22,
                      color: midnightBlueColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}


// I gave you a prmpt in this code : "// Hey chat GPT. Listen. I want to make this field to align left. help me.". help to resolve this please.