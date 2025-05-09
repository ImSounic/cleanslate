// lib/features/auth/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:cleanslate/core/utils/theme_utils.dart';
import 'package:cleanslate/data/services/supabase_service.dart';
import 'package:cleanslate/data/services/household_service.dart';
import 'package:cleanslate/features/home/screens/home_screen.dart';
import 'package:cleanslate/features/auth/screens/forgot_password_screen.dart';
import 'package:cleanslate/features/auth/screens/otp_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _supabaseService = SupabaseService();
  final _householdService = HouseholdService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _usePasswordlessLogin = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handlePasswordLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email and password')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _supabaseService.signIn(email: email, password: password);

      // Initialize household service after successful login
      await _householdService.initializeHousehold();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${error.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handlePasswordlessLogin() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter your email')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _supabaseService.sendEmailOtp(email: email);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(email: email),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${error.toString()}')));
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
            image: const AssetImage('assets/images/background.png'),
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
                const SizedBox(height: 40),
                const Text(
                  'Welcome back!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your roommate is waiting for\nyou to spam that chore!',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 30),

                // Toggle between password and passwordless login
                Row(
                  children: [
                    Checkbox(
                      value: _usePasswordlessLogin,
                      onChanged: (value) {
                        setState(() {
                          _usePasswordlessLogin = value ?? false;
                        });
                      },
                      checkColor: AppColors.primary,
                      fillColor: MaterialStateProperty.resolveWith<Color>(
                        (states) => Colors.white,
                      ),
                    ),
                    const Text(
                      'Login with OTP (no password)',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                _buildTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  suffixIcon: Icons.email_outlined,
                ),

                // Only show password field if not using passwordless login
                if (!_usePasswordlessLogin) ...[
                  const SizedBox(height: 24),
                  _buildTextField(
                    controller: _passwordController,
                    label: 'Password',
                    isPassword: true,
                    suffixIcon:
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                    onSuffixTap: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ],

                const SizedBox(height: 24),

                if (!_usePasswordlessLogin) ...[
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _isLoading
                            ? null
                            : (_usePasswordlessLogin
                                ? _handlePasswordlessLogin
                                : _handlePasswordLogin),
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
                            ? const CircularProgressIndicator()
                            : Text(
                              _usePasswordlessLogin ? 'SEND CODE' : 'LOGIN',
                            ),
                  ),
                ),
              ],
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
    VoidCallback? onSuffixTap,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword && _obscurePassword,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            contentPadding: EdgeInsets.zero,
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white70),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
            suffixIcon:
                suffixIcon != null
                    ? GestureDetector(
                      onTap: onSuffixTap,
                      child: Icon(suffixIcon, color: Colors.white),
                    )
                    : null,
          ),
        ),
      ],
    );
  }
}
