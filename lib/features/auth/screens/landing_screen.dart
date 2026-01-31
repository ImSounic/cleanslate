// lib/features/auth/screens/landing_screen.dart

import 'package:flutter/material.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:cleanslate/core/utils/theme_utils.dart';
import 'package:cleanslate/features/auth/screens/login_screen.dart';
import 'package:cleanslate/features/auth/screens/signup_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the theme provider
    final isDarkMode = ThemeUtils.isDarkMode(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                isDarkMode
                    ? AppColors.authGradientDark
                    : AppColors.authGradient,
          ),
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
            opacity: isDarkMode ? 0.5 : 1.0, // Reduce opacity in dark mode
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Assignment indicators at the top with padding
                const SizedBox(height: 20),
                Center(
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 15,
                              backgroundImage: AssetImage(
                                'assets/images/profile_pictures/dad.png',
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Dad assigned ',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'VarelaRound',
                              ),
                            ),
                            const Icon(
                              Icons.cleaning_services,
                              color: Colors.white,
                            ),
                            const Text(
                              ' to ',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'VarelaRound',
                              ),
                            ),
                            CircleAvatar(
                              radius: 15,
                              backgroundImage: AssetImage(
                                'assets/images/profile_pictures/dad_to.png',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 15,
                              backgroundImage: AssetImage(
                                'assets/images/profile_pictures/john.png',
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'John assigned ',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'VarelaRound',
                              ),
                            ),
                            const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                            ),
                            const Text(
                              ' to ',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'VarelaRound',
                              ),
                            ),
                            CircleAvatar(
                              radius: 15,
                              backgroundImage: AssetImage(
                                'assets/images/profile_pictures/john_to.png',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Expanded space to push content up from bottom (larger spacer)
                const Spacer(flex: 3),

                // Main content (positioned higher on screen)
                const Text(
                  'Clean Slate.',
                  style: TextStyle(
                    fontFamily: 'Switzer',
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The app to distribute chores to\nyour roomates, family, partner.',
                  style: TextStyle(
                    fontFamily: 'VarelaRound',
                    fontSize: 16,
                    color: Colors.white,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.9),
                          foregroundColor: const Color(0xFF2185D0),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomLeft: Radius.circular(12),
                            ),
                          ),
                        ),
                        child: const Text(
                          'Login',
                          style: TextStyle(fontFamily: 'VarelaRound'),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SignupScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0D2E52),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                        ),
                        child: const Text(
                          'Sign up',
                          style: TextStyle(fontFamily: 'VarelaRound'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                const Center(
                  child: Text(
                    'App Version 1.0.0',
                    style: TextStyle(
                      fontFamily: 'VarelaRound',
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),

                // Spacer at bottom (smaller spacer)
                const Spacer(flex: 5),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
