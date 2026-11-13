import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'login.dart';
import 'signup.dart';

// void main() {
//   runApp(
//     const MaterialApp(
//       debugShowCheckedModeBanner: false,
//       home: WelcomeScreen(),
//     ),
//   );
// }

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    this.onLogin,
  });

  final VoidCallback? onLogin;

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDDDDDD),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final pageHeight = constraints.maxHeight < 900
              ? 900.0
              : constraints.maxHeight;
          final contentWidth =
              (constraints.maxWidth - 50).clamp(0.0, 440.0).toDouble();
          final contentLeft = (constraints.maxWidth - contentWidth) / 2;
          final compact = constraints.maxHeight < 700;

          return SingleChildScrollView(
            child: SizedBox(
              width: constraints.maxWidth,
              height: pageHeight,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // --- BACKGROUND RADIAL GRADIENT RESPONSIF ---
                  // Gradien Kuning
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
                  // Gradien Oranye
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
                  // Gradien Ungu
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
                    top: compact ? pageHeight * 0.2 : 190,
                    left: contentLeft,
                    width: contentWidth,
                    child: const Text(
                      'Welcome',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF1E1E1E),
                        fontFamily: 'Bricolage Grotesque',
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ),

                  Positioned(
                    top: compact ? pageHeight * 0.25 : 285,
                    left: contentLeft,
                    width: contentWidth,
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/icons/logo.svg', // Sesuaikan path asset ilustrasi logo Anda
                        width: 220,
                        height: 220,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: compact ? pageHeight * 0.12 : 200,
                    left: contentLeft,
                    width: contentWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _GradientButton(
                          label: 'Create Account',
                          gradient: _gradient,
                          filled: false,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const SignupScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 15),
                        _GradientButton(
                          label: 'Log In',
                          gradient: _gradient,
                          filled: true,
                          onPressed: onLogin ??
                              () {
                                Navigator.of(context).push(
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

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.label,
    required this.gradient,
    required this.filled,
    required this.onPressed,
  });

  final String label;
  final Gradient gradient;
  final bool filled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(100),
          child: Ink(
            height: 55,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(100),
            ),
            padding: EdgeInsets.all(filled ? 0 : 2),
            child: Ink(
              decoration: BoxDecoration(
                color: filled ? Colors.transparent : const Color(0xFFF8F8F8),
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
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}