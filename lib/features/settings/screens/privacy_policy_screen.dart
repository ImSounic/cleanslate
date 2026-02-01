import 'package:flutter/material.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:cleanslate/core/utils/theme_utils.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeUtils.isDarkMode(context);

    return Scaffold(
      backgroundColor:
          isDarkMode ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
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
              'Introduction',
              'CleanSlate ("the App") is developed by Sounic Akkaraju ("we," "us," or "our"). '
                  'This Privacy Policy explains how we collect, use, store, and protect your information when you use our mobile application.\n\n'
                  'By using CleanSlate, you agree to the collection and use of information as described in this policy.',
            ),
            _buildSection(
              isDarkMode,
              'Contact Information',
              'Developer: Sounic Akkaraju\nEmail: imsounic@gmail.com',
            ),
            _buildSection(
              isDarkMode,
              'Information We Collect',
              'Account Information\n'
                  '• Email address\n'
                  '• Full name\n'
                  '• Profile picture\n\n'
                  'Household Data\n'
                  '• Household name\n'
                  '• Household membership\n'
                  '• Room configuration\n\n'
                  'Chore Data\n'
                  '• Chore names and descriptions\n'
                  '• Chore assignments\n'
                  '• Chore schedules\n'
                  '• Completion status\n\n'
                  'Device Data\n'
                  '• Firebase Cloud Messaging (FCM) push notification tokens\n'
                  '• Device platform (e.g., Android, iOS)\n\n'
                  'Calendar Data\n'
                  '• Google Calendar events (only if you choose to connect your Google Calendar)\n\n'
                  'Preferences\n'
                  '• Chore preferences (availability, liked/disliked chores)\n'
                  '• Theme settings (light/dark mode)',
            ),
            _buildSection(
              isDarkMode,
              'How We Use Your Data',
              'We use your data solely for app functionality, including:\n\n'
                  '• Managing chores and assignments within your household\n'
                  '• Sending push notifications for chore reminders and updates\n'
                  '• Displaying schedules and calendar integrations\n'
                  '• Personalizing your experience (theme, preferences)\n'
                  '• Enabling household collaboration features\n\n'
                  'We do not use your data for advertising, analytics profiling, or any purpose unrelated to the core functionality of CleanSlate.',
            ),
            _buildSection(
              isDarkMode,
              'Data Storage',
              'Your data is stored using the following services:\n\n'
                  '• Supabase — PostgreSQL database hosted on Amazon Web Services (AWS) for all app data\n'
                  '• Firebase Cloud Messaging — Google Cloud infrastructure for delivering push notifications',
            ),
            _buildSection(
              isDarkMode,
              'Data Sharing',
              '• We do not sell your personal data to any third party.\n'
                  '• We do not share your data with third parties for marketing or advertising purposes.\n'
                  '• Your household data is shared only with members of your household within the app.\n'
                  '• Data is transmitted to Supabase and Firebase solely for the purpose of providing app services.',
            ),
            _buildSection(
              isDarkMode,
              'Your Rights',
              '• View and edit your profile information at any time through the app settings\n'
                  '• Delete your account, which permanently removes all your personal data\n'
                  '• Leave households, which removes your association with that household\'s data\n'
                  '• Disconnect Google Calendar, which removes stored calendar integration data\n\n'
                  'To exercise any of these rights, use the relevant options within the app or contact us at imsounic@gmail.com.',
            ),
            _buildSection(
              isDarkMode,
              'Data Security',
              '• Row Level Security (RLS) is enforced on all database tables\n'
                  '• Encrypted authentication tokens are used for all authenticated sessions\n'
                  '• HTTPS is used for all data transmission',
            ),
            _buildSection(
              isDarkMode,
              'Children\'s Privacy',
              'CleanSlate is not directed at children under the age of 13. We do not knowingly collect personal information from children under 13. '
                  'If you believe a child under 13 has provided us with personal data, please contact us at imsounic@gmail.com.',
            ),
            _buildSection(
              isDarkMode,
              'Changes to This Policy',
              'We may update this Privacy Policy from time to time. When we make changes, we will notify users through app updates.',
            ),
            _buildSection(
              isDarkMode,
              'Contact Us',
              'If you have any questions or concerns about this Privacy Policy, please contact us:\n\n'
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
