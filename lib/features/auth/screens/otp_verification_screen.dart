// lib/features/auth/screens/otp_verification_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:cleanslate/core/utils/theme_utils.dart';
import 'package:cleanslate/data/services/supabase_service.dart';
import 'package:cleanslate/data/services/household_service.dart';
import 'package:cleanslate/features/home/screens/home_screen.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final Map<String, dynamic>? userData;

  const OtpVerificationScreen({Key? key, required this.email, this.userData})
    : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  final _supabaseService = SupabaseService();
  final _householdService = HouseholdService();
  bool _isLoading = false;
  bool _isResending = false;
  int _remainingSeconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _verifyOtp() async {
    // Combine all digits
    final otp = _controllers.map((c) => c.text).join();

    if (otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter all 6 digits')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final bool verified = await _supabaseService.verifyOtp(
        email: widget.email,
        otp: otp,
      );

      if (verified) {
        // If user data was provided, update the user profile
        if (widget.userData != null) {
          await _supabaseService.updateUserProfile(
            fullName: widget.userData!['full_name'],
            // Add other fields as needed
          );
        }

        if (mounted) {
          // Initialize household service after successful login
          await _householdService.initializeHousehold();

          // Navigate to home screen on success
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid verification code')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resendCode() async {
    if (_remainingSeconds > 0) return;

    setState(() {
      _isResending = true;
    });

    try {
      await _supabaseService.sendEmailOtp(email: widget.email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification code resent')),
        );
        _startResendTimer();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeUtils.isDarkMode(context);

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        backgroundColor:
            isDarkMode ? AppColors.backgroundDark : AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDarkMode ? AppColors.textPrimaryDark : AppColors.primary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Email Verification",
          style: TextStyle(
            color: isDarkMode ? AppColors.textPrimaryDark : AppColors.primary,
            fontFamily: 'Switzer',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Enter 6 digit verification code sent to your email",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  color:
                      isDarkMode
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.email,
                style: TextStyle(
                  fontSize: 16,
                  color:
                      isDarkMode
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                  fontFamily: 'VarelaRound',
                ),
              ),
              const SizedBox(height: 32),

              // OTP input fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  6,
                  (index) => _buildOtpDigitField(index, isDarkMode),
                ),
              ),

              const SizedBox(height: 24),

              // Resend code button
              Center(
                child: TextButton(
                  onPressed:
                      _remainingSeconds == 0 && !_isResending
                          ? _resendCode
                          : null,
                  child:
                      _isResending
                          ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color:
                                  isDarkMode
                                      ? AppColors.primaryDark
                                      : AppColors.primary,
                            ),
                          )
                          : Text(
                            _remainingSeconds > 0
                                ? "Resend Code (${_remainingSeconds}s)"
                                : "Resend Code",
                            style: TextStyle(
                              color:
                                  _remainingSeconds > 0
                                      ? (isDarkMode
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondary)
                                      : (isDarkMode
                                          ? AppColors.primaryDark
                                          : AppColors.primary),
                              fontFamily: 'VarelaRound',
                            ),
                          ),
                ),
              ),

              const Spacer(),

              // Verify button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isDarkMode ? AppColors.primaryDark : AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    disabledBackgroundColor:
                        isDarkMode
                            ? AppColors.primaryDark.withOpacity(0.5)
                            : AppColors.primary.withOpacity(0.5),
                  ),
                  child:
                      _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            'Verify',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'VarelaRound',
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpDigitField(int index, bool isDarkMode) {
    return SizedBox(
      width: 48,
      height: 56,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDarkMode ? AppColors.borderDark : AppColors.border,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDarkMode ? AppColors.borderDark : AppColors.border,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDarkMode ? AppColors.primaryDark : AppColors.primary,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            // Auto advance to next field
            if (index < 5) {
              _focusNodes[index + 1].requestFocus();
            } else {
              // Last digit entered, hide keyboard
              _focusNodes[index].unfocus();

              // Check if all fields are filled
              final allFilled = _controllers.every((c) => c.text.isNotEmpty);
              if (allFilled) {
                // Auto-submit when all digits are entered
                _verifyOtp();
              }
            }
          } else if (index > 0) {
            // If empty and backspace was pressed, go back
            _focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }
}
