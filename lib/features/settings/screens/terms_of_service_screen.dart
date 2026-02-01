import 'package:flutter/material.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:cleanslate/core/utils/theme_utils.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeUtils.isDarkMode(context);

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(
          'Terms of Service',
          style: TextStyle(
            fontFamily: 'Switzer',
            fontWeight: FontWeight.bold,
            color:
                isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        backgroundColor:
            isDarkMode ? AppColors.backgroundDark : AppColors.background,
        iconTheme: IconThemeData(
          color:
              isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLastUpdated(isDarkMode),
            const SizedBox(height: 24),
            _buildSection(
              isDarkMode,
              '1. Acceptance of Terms',
              'By downloading, installing, or using CleanSlate ("the App"), you agree to be bound by these Terms of Service ("Terms"). '
                  'If you do not agree to these Terms, do not use the App.',
            ),
            _buildSection(
              isDarkMode,
              '2. Description of Service',
              'CleanSlate is a household chore management application that allows users to create households, assign and track chores, '
                  'set schedules, and collaborate with household members.',
            ),
            _buildSection(
              isDarkMode,
              '3. Account Responsibility',
              '• You are responsible for maintaining the confidentiality of your account credentials.\n'
                  '• You are responsible for all activity that occurs under your account.\n'
                  '• You must provide accurate and complete information when creating your account.\n'
                  '• You must notify us promptly of any unauthorized use of your account.',
            ),
            _buildSection(
              isDarkMode,
              '4. Acceptable Use',
              'You agree not to:\n\n'
                  '• Use the App for any unlawful purpose\n'
                  '• Harass, abuse, or harm other users\n'
                  '• Attempt to gain unauthorized access to other users\' data or accounts\n'
                  '• Upload malicious content or interfere with the App\'s operation\n'
                  '• Create multiple accounts for deceptive purposes\n'
                  '• Use the App in any way that could damage, disable, or impair the service',
            ),
            _buildSection(
              isDarkMode,
              '5. Household Data',
              '• Content you create within households (chore names, descriptions, schedules) is visible to all members of that household.\n'
                  '• You are responsible for the content you create within the App.\n'
                  '• Household administrators have the ability to manage household membership and settings.',
            ),
            _buildSection(
              isDarkMode,
              '6. Intellectual Property',
              'The App, including its design, code, graphics, and content, is owned by Sounic Akkaraju and is protected by applicable '
                  'intellectual property laws. You may not copy, modify, distribute, or reverse-engineer any part of the App.',
            ),
            _buildSection(
              isDarkMode,
              '7. No Warranty',
              'The App is provided "as is" and "as available" without warranties of any kind, either express or implied, including but not limited to:\n\n'
                  '• Implied warranties of merchantability\n'
                  '• Fitness for a particular purpose\n'
                  '• Non-infringement\n\n'
                  'We do not warrant that the App will be uninterrupted, error-free, or free of harmful components.',
            ),
            _buildSection(
              isDarkMode,
              '8. Limitation of Liability',
              'To the fullest extent permitted by applicable law, Sounic Akkaraju shall not be liable for any indirect, incidental, special, '
                  'consequential, or punitive damages, including but not limited to loss of data, loss of profits, or interruption of service.\n\n'
                  'Our total liability for any claim arising from or related to the App shall not exceed the amount you paid for the App.',
            ),
            _buildSection(
              isDarkMode,
              '9. Termination',
              '• You may stop using the App and delete your account at any time.\n'
                  '• We reserve the right to suspend or terminate your access to the App at our sole discretion, without notice, '
                  'for conduct that we believe violates these Terms or is harmful to other users.\n'
                  '• Upon termination, your right to use the App ceases immediately.',
            ),
            _buildSection(
              isDarkMode,
              '10. Changes to Terms',
              'We may update these Terms from time to time. Continued use of the App after changes constitutes acceptance of the revised Terms. '
                  'We will notify users of significant changes through app updates.',
            ),
            _buildSection(
              isDarkMode,
              '11. Contact Us',
              'If you have any questions about these Terms, please contact us:\n\n'
                  'Email: imsounic@gmail.com',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildLastUpdated(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Last Updated: February 1, 2026',
        style: TextStyle(
          fontFamily: 'VarelaRound',
          fontSize: 13,
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSection(bool isDarkMode, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Switzer',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontFamily: 'VarelaRound',
              fontSize: 14,
              height: 1.6,
              color: isDarkMode
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
