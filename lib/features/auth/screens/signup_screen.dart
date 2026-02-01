// lib/features/auth/screens/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:cleanslate/data/services/supabase_service.dart';
import 'package:cleanslate/data/services/household_service.dart';
import 'package:cleanslate/features/app_shell.dart';
import 'package:cleanslate/core/utils/theme_utils.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _supabaseService = SupabaseService();
  final _householdService = HouseholdService();
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate() || !_acceptedTerms) {
      if (!_acceptedTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please accept the terms and conditions'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _supabaseService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        userData: {'full_name': _nameController.text.trim()},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check your email to confirm your account'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        String errorMessage = error.toString();

        // Handle specific error messages
        if (errorMessage.contains('Google sign-in')) {
          errorMessage =
              'This email is already registered with Google. Please use "Sign in with Google" instead.';
        } else if (errorMessage.contains('already registered')) {
          errorMessage =
              'This email is already registered. Please sign in instead.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignUp() async {
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the terms and conditions'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isGoogleLoading = true;
    });

    try {
      await _supabaseService.signInWithGoogle();

      // Initialize household service after successful signup
      await _householdService.initializeHousehold();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AppShell()), (route) => false,
        );
      }
    } catch (error) {
      if (mounted) {
        String errorMessage = error.toString();

        // Handle specific error messages
        if (errorMessage.contains('already exists')) {
          errorMessage =
              'An account with this email already exists. Please sign in instead.';
        } else if (errorMessage.contains('cancelled')) {
          // User cancelled, don't show error
          setState(() {
            _isGoogleLoading = false;
          });
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if dark mode is enabled
    final isDarkMode = ThemeUtils.isDarkMode(context);

    return Scaffold(
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button at top left
                  Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Let\'s Start',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Start that chores with a\nchorus.',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  const SizedBox(height: 40),

                  // Google Sign Up Button
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _isGoogleLoading ? null : _handleGoogleSignUp,
                      icon:
                          _isGoogleLoading
                              ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.grey,
                                  ),
                                ),
                              )
                              : SvgPicture.asset(
                                'assets/images/google_logo.svg',
                                height: 24,
                                width: 24,
                              ),
                      label: Text(
                        _isGoogleLoading
                            ? 'Signing up...'
                            : 'Sign up with Google',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        minimumSize: const Size(200, 48),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Center(
                    child: Text(
                      'Or',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    isDarkMode: isDarkMode,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email Address',
                    suffixIcon: Icons.email_outlined,
                    isDarkMode: isDarkMode,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      ).hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _passwordController,
                    label: 'Password',
                    isPassword: true,
                    suffixIcon: Icons.lock_outline,
                    isDarkMode: isDarkMode,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Terms & Conditions Checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _acceptedTerms,
                        onChanged: (bool? value) {
                          setState(() {
                            _acceptedTerms = value ?? false;
                          });
                        },
                        checkColor: Colors.white,
                        fillColor: WidgetStateProperty.resolveWith<Color>((
                          Set<WidgetState> states,
                        ) {
                          if (states.contains(WidgetState.selected)) {
                            return AppColors.primary;
                          }
                          return Colors.white.withValues(alpha: 0.3);
                        }),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _acceptedTerms = !_acceptedTerms;
                          });
                        },
                        child: const Text(
                          'I accept the Terms & Conditions',
                          style: TextStyle(
                            color: Colors.white,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          (_isLoading || _isGoogleLoading)
                              ? null
                              : _handleSignup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF2185D0),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(),
                              )
                              : const Text(
                                'SIGN UP',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an account? ",
                          style: TextStyle(color: Colors.white),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? suffixIcon,
    bool isPassword = false,
    required bool isDarkMode,
    required String? Function(String?) validator,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          validator: validator,
          keyboardType: keyboardType,
          textAlign: TextAlign.center,
          textAlignVertical: TextAlignVertical.center,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'VarelaRound',
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(vertical: 16.0),
            filled: true,
            fillColor: Colors.transparent,
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white70),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
            errorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.redAccent),
            ),
            errorStyle: const TextStyle(color: Colors.redAccent),
            suffixIcon:
                suffixIcon != null
                    ? Icon(suffixIcon, color: Colors.white)
                    : null,
          ),
        ),
      ],
    );
  }
}
