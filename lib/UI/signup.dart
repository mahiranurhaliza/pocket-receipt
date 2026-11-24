import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'home.dart';
import 'login.dart';

// void main() {
//   runApp(
//     const MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: SignupScreen(),
//     ),
//   );
// }

class SignupScreen extends StatefulWidget {
  const SignupScreen({
    super.key,
    this.onSubmit,
    this.onGoogleSignup,
    this.onLogin,
  });

  final VoidCallback? onSubmit;
  final VoidCallback? onGoogleSignup;
  final VoidCallback? onLogin;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  static const _gradient = LinearGradient(
    begin: Alignment(-0.98, -0.17),
    end: Alignment(0.98, 0.17),
    stops: [0.1, 0.6, 1],
    colors: [
      Color(0xFFB696E3),
      Color(0xFFFFB357),
      Color(0xFFFFEC5C),
    ],
  );

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFEEEEEE),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final pageHeight = constraints.maxHeight < 900
              ? 900.0
              : constraints.maxHeight;
          final contentWidth =
              (constraints.maxWidth - 50).clamp(0.0, 440.0).toDouble();
          final contentLeft = (constraints.maxWidth - contentWidth) / 2;

          return SingleChildScrollView(
            child: SizedBox(
              width: constraints.maxWidth,
              height: pageHeight,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // --- BACKGROUND RADIAL GRADIENT RESPONSIF ---
                  Positioned(
                    left: constraints.maxWidth * 0.45,
                    top: -34,
                    child: Container(
                      width: constraints.maxWidth * 0.7,
                      height: constraints.maxWidth * 0.7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.5,
                          colors: [
                            Color(0xFFFFEC5C),
                            Color(0x00FFEC5C),
                          ],
                          stops: [0.0, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: constraints.maxWidth * 0.05,
                    top: -9,
                    child: Container(
                      width: constraints.maxWidth * 0.7,
                      height: constraints.maxWidth * 0.7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.5,
                          colors: [
                            Color(0xFFFFB357),
                            Color(0x00FFB357),
                          ],
                          stops: [0.0, 1.0],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -constraints.maxWidth * 0.2,
                    top: -63,
                    child: Container(
                      width: constraints.maxWidth * 0.7,
                      height: constraints.maxWidth * 0.7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 0.5,
                          colors: [
                            Color(0xFFB696E3),
                            Color(0x00B696E3),
                          ],
                          stops: [0.0, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // ---------------------------------------------

                  Positioned(
                    width: constraints.maxWidth,
                    height: pageHeight,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0x55F8F8F8),
                      ),
                    ),
                  ),

                  Positioned(
                    top: -63,
                    left: (constraints.maxWidth - 578) / 2,
                    child: SvgPicture.asset(
                      'assets/1d707.svg',
                      width: 578,
                      height: 963,
                      fit: BoxFit.fill,
                    ),
                  ),

                  Positioned(
                    top: 260,
                    //left: contentLeft,
                    width: constraints.maxWidth,
                    child: SvgPicture.asset(
                      'assets/cover/background.svg',
                      height: 640,
                      fit: BoxFit.fill,
                    ),
                  ),

                  Positioned(
                    top: 42,
                    left: contentLeft > 17 ? contentLeft : 17,
                    child: IconButton(
                      tooltip: 'Back',
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: SvgPicture.asset(
                        'assets/icons/back.svg',
                        width: 22,
                        height: 17,
                      ),
                    ),
                  ),

                  Positioned(
                    top: 277,
                    left: contentLeft,
                    width: contentWidth,
                    child: const Text(
                      'Create Your Account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF1E1E1E),
                        fontFamily: 'Bricolage Grotesque',
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                  ),

                  Positioned(
                    top: 328,
                    left: contentLeft,
                    width: contentWidth,
                    child: Column(
                      children: [
                        _SignupField(
                          controller: _nameController,
                          hintText: 'Enter name',
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.name],
                        ),
                        const SizedBox(height: 10),
                        _SignupField(
                          controller: _emailController,
                          hintText: 'Enter email',
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                        ),
                        const SizedBox(height: 10),
                        _SignupField(
                          controller: _passwordController,
                          hintText: 'Enter password',
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          autofillHints: const [AutofillHints.newPassword],
                          onSubmitted: (_) => widget.onSubmit?.call(),
                        ),
                        const SizedBox(height: 20),
                        _ActionButton(
                          label: 'Get Started',
                          onPressed: widget.onSubmit ??
                              () {
                                Navigator.of(context).pushAndRemoveUntil(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const HomeScreen(),
                                  ),
                                  (route) => false,
                                );
                              },
                        ),
                        const SizedBox(height: 23),
                        const _OrDivider(),
                        const SizedBox(height: 24),
                        _GoogleButton(
                          onPressed: widget.onGoogleSignup ?? () {},
                        ),
                        const SizedBox(height: 16),
                        _LoginPrompt(
                          onPressed: widget.onLogin ??
                              () {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const LoginScreen(),
                                  ),
                                );
                              },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SignupField extends StatelessWidget {
  const _SignupField({
    required this.controller,
    required this.hintText,
    required this.textInputAction,
    required this.autofillHints,
    this.keyboardType,
    this.obscureText = false,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputAction textInputAction;
  final Iterable<String> autofillHints;
  final TextInputType? keyboardType;
  final bool obscureText;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        autofillHints: autofillHints,
        obscureText: obscureText,
        onSubmitted: onSubmitted,
        style: const TextStyle(
          color: Color(0xFF1E1E1E),
          fontFamily: 'Bricolage Grotesque',
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color.fromRGBO(30, 30, 30, 0.3),
            fontFamily: 'Bricolage Grotesque',
            fontSize: 15,
            fontWeight: FontWeight.w400,
          ),
          filled: true,
          fillColor: const Color(0xFFF8F8F8),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          enabledBorder: _border,
          focusedBorder: _border.copyWith(
            borderSide: const BorderSide(color: Color(0xFF793ECC), width: 1.5),
          ),
        ),
      ),
    );
  }

  static final _border = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: const BorderSide(color: Color(0xFF5C5C5C)),
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(100),
        child: Ink(
          height: 50,
          decoration: BoxDecoration(
            gradient: _SignupScreenState._gradient,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF1E1E1E),
                fontFamily: 'Bricolage Grotesque',
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SvgPicture.asset(
            'assets/3ba61.svg',
            height: 1,
            fit: BoxFit.fill,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 11),
          child: Text(
            'or',
            style: TextStyle(
              color: Color(0xFF5C5C5C),
              fontFamily: 'Bricolage Grotesque',
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: SvgPicture.asset(
            'assets/3ba61.svg',
            height: 1,
            fit: BoxFit.fill,
          ),
        ),
      ],
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Image.asset(
          'assets/icons/google.png',
          width: 25,
          height: 26,
          fit: BoxFit.cover,
        ),
        label: const Text('Sign up with Google'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1E1E1E),
          backgroundColor: const Color(0xFFF8F8F8),
          side: const BorderSide(color: Color(0xFF5C5C5C)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Bricolage Grotesque',
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  const _LoginPrompt({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: const Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'Already have an account? ',
              style: TextStyle(color: Color(0xFF5C5C5C)),
            ),
            TextSpan(
              text: 'Log In',
              style: TextStyle(
                color: Color(0xFF793ECC),
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
        style: TextStyle(
          fontFamily: 'Bricolage Grotesque',
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}