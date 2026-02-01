// lib/features/settings/screens/settings_screen.dart
// Complete updated settings screen with chore preferences and calendar sync integration

import 'package:flutter/material.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:cleanslate/core/constants/app_text_styles.dart';
import 'package:cleanslate/data/services/supabase_service.dart';
import 'package:cleanslate/features/auth/screens/login_screen.dart';
import 'package:cleanslate/features/settings/screens/edit_profile_screen.dart';
import 'package:cleanslate/features/settings/screens/add_password_screen.dart';
import 'package:cleanslate/features/profile/screens/chore_preferences_screen.dart';
import 'package:cleanslate/features/calendar/screens/calendar_connection_screen.dart';
import 'package:cleanslate/features/settings/widgets/calendar_sync_settings.dart';
import 'package:provider/provider.dart';
import 'package:cleanslate/core/providers/theme_provider.dart';
import 'package:cleanslate/core/utils/debug_logger.dart';
import 'package:cleanslate/core/services/error_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _supabaseService = SupabaseService();
  String _userName = 'Joe';
  String _userEmail = 'Email@gmail.com';
  String? _profileImageUrl;
  bool _pushNotifications = true;
  bool _reminders = true;
  bool _isLoading = false;
  bool _hasGoogleLinked = false;
  String? _authProvider;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkGoogleLinkStatus();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Force refresh user data from Supabase
      await _supabaseService.client.auth.refreshSession();

      final user = _supabaseService.currentUser;
      if (user != null) {
        final userData = user.userMetadata;
        setState(() {
          _userName =
              userData?['full_name'] ?? user.email?.split('@').first ?? 'User';
          _userEmail = user.email ?? 'Email@gmail.com';
          _profileImageUrl = userData?['profile_image_url'];
        });

        // Get auth provider info from profiles table
        final profile =
            await _supabaseService.client
                .from('profiles')
                .select('auth_provider')
                .eq('id', user.id)
                .single();

        setState(() {
          _authProvider = profile['auth_provider'] as String?;
          _hasGoogleLinked =
              _authProvider == 'google' || _authProvider == 'email_and_google';
        });
      }
    } catch (e) {
      debugLog('Error loading user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkGoogleLinkStatus() async {
    try {
      final user = _supabaseService.currentUser;
      if (user != null) {
        final profile =
            await _supabaseService.client
                .from('profiles')
                .select('auth_provider')
                .eq('id', user.id)
                .maybeSingle();

        if (profile != null) {
          setState(() {
            _authProvider = profile['auth_provider'] as String?;
            _hasGoogleLinked =
                _authProvider == 'google' ||
                _authProvider == 'email_and_google';
          });
        }
      }
    } catch (e) {
      debugLog('Error checking Google link status: $e');
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _supabaseService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorService.showError(context, e, operation: 'logout');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return SafeArea(
      child: Column(
        children: [
          // Header
          _buildHeader(isDarkMode),

          // Settings Content
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Profile Section
                          _buildSectionTitle('Profile', isDarkMode),
                          _buildEditProfileOption(isDarkMode),
                          _buildChorePreferencesOption(isDarkMode),
                          _buildCalendarConnectionOption(isDarkMode),

                          const SizedBox(height: 24),

                          // Calendar Sync Settings (NEW)
                          const CalendarSyncSettings(),

                          const SizedBox(height: 24),

                          // Notifications Section
                          _buildSectionTitle('Notifications', isDarkMode),
                          _buildNotificationOptions(isDarkMode),

                          const SizedBox(height: 24),

                          // Appearance Section
                          _buildSectionTitle('Appearance', isDarkMode),
                          _buildThemeOption(isDarkMode),

                          const SizedBox(height: 24),

                          // Account Section
                          _buildSectionTitle('Account', isDarkMode),
                          _buildAccountOptions(isDarkMode),

                          const SizedBox(height: 24),

                          // Logout Button
                          _buildLogoutButton(isDarkMode),
                        ],
                      ),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.backgroundDark : AppColors.background,
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? AppColors.borderDark : AppColors.border,
          ),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.primary,
            backgroundImage:
                _profileImageUrl != null
                    ? NetworkImage(_profileImageUrl!)
                    : null,
            child:
                _profileImageUrl == null
                    ? Text(
                      _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                    : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: AppTextStyles.heading3.copyWith(
                    color:
                        isDarkMode
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                ),
                Text(
                  _userEmail,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color:
                        isDarkMode
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.qr_code,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            onPressed: () {
              // Show QR code for profile sharing
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: AppTextStyles.sectionLabel.copyWith(
          color:
              isDarkMode
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildEditProfileOption(bool isDarkMode) {
    return _buildSettingsTile(
      icon: Icons.person_outline,
      iconColor: AppColors.primary,
      title: 'Edit Profile',
      subtitle: 'Update your personal information',
      isDarkMode: isDarkMode,
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const EditProfileScreen()),
        );
        if (result == true) {
          _loadUserData();
        }
      },
    );
  }

  Widget _buildChorePreferencesOption(bool isDarkMode) {
    return _buildSettingsTile(
      icon: Icons.cleaning_services,
      iconColor: AppColors.primary,
      title: 'Chore Preferences',
      subtitle: 'Set your availability and chore preferences',
      isDarkMode: isDarkMode,
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ChorePreferencesScreen(),
          ),
        );

        if (result == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Preferences updated successfully'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }

  Widget _buildCalendarConnectionOption(bool isDarkMode) {
    return FutureBuilder<bool>(
      future: _checkCalendarConnectionStatus(),
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? false;

        return _buildSettingsTile(
          icon: Icons.calendar_month,
          iconColor: const Color(0xFF4285F4),
          title: 'Calendar Connection',
          subtitle: 'Sync your class schedule',
          isDarkMode: isDarkMode,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color:
                  isConnected
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isConnected ? 'Connected' : 'Not Connected',
              style: TextStyle(
                fontSize: 10,
                color: isConnected ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CalendarConnectionScreen(),
              ),
            );

            // Refresh status if calendar was connected/disconnected
            if (result == true) {
              setState(() {});
            }
          },
        );
      },
    );
  }

  Future<bool> _checkCalendarConnectionStatus() async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabaseService.client
          .from('calendar_integrations')
          .select('id')
          .eq('user_id', userId)
          .limit(1);

      return (response as List).isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  Widget _buildNotificationOptions(bool isDarkMode) {
    return Column(
      children: [
        _buildSwitchTile(
          icon: Icons.notifications_none,
          iconColor: Colors.orange,
          title: 'Push Notifications',
          subtitle: 'Receive chore reminders',
          value: _pushNotifications,
          isDarkMode: isDarkMode,
          onChanged: (value) {
            setState(() {
              _pushNotifications = value;
            });
          },
        ),
        _buildSwitchTile(
          icon: Icons.access_time,
          iconColor: Colors.blue,
          title: 'Daily Reminders',
          subtitle: 'Get reminded about pending chores',
          value: _reminders,
          isDarkMode: isDarkMode,
          onChanged: (value) {
            setState(() {
              _reminders = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildThemeOption(bool isDarkMode) {
    return _buildSettingsTile(
      icon: isDarkMode ? Icons.dark_mode : Icons.light_mode,
      iconColor: isDarkMode ? Colors.indigo : Colors.amber,
      title: 'Dark Mode',
      subtitle:
          isDarkMode
              ? 'Currently using dark theme'
              : 'Currently using light theme',
      isDarkMode: isDarkMode,
      trailing: Switch(
        value: isDarkMode,
        onChanged: (value) {
          Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
        },
        activeThumbColor: AppColors.primary,
      ),
      onTap: () {
        Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
      },
    );
  }

  Widget _buildAccountOptions(bool isDarkMode) {
    return Column(
      children: [
        if (_authProvider == 'email')
          _buildSettingsTile(
            icon: Icons.lock_outline,
            iconColor: Colors.green,
            title: 'Add Password',
            subtitle: 'Secure your account with a password',
            isDarkMode: isDarkMode,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddPasswordScreen(),
                ),
              );
            },
          ),

        if (_authProvider == 'email' && !_hasGoogleLinked)
          _buildSettingsTile(
            icon: Icons.link,
            iconColor: const Color(0xFF4285F4),
            title: 'Link Google Account',
            subtitle: 'Connect your Google account for easy login',
            isDarkMode: isDarkMode,
            onTap: () async {
              try {
                await _supabaseService.linkGoogleAccount();
                await _checkGoogleLinkStatus();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Google account linked successfully'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ErrorService.showError(context, e, operation: 'linkGoogle');
                }
              }
            },
          ),

        if (_hasGoogleLinked && _authProvider == 'email_and_google')
          _buildSettingsTile(
            icon: Icons.link_off,
            iconColor: Colors.red,
            title: 'Unlink Google Account',
            subtitle: 'Remove Google account connection',
            isDarkMode: isDarkMode,
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Unlink Google Account'),
                      content: const Text(
                        'Are you sure you want to unlink your Google account? '
                        'You\'ll still be able to log in with your email and password.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Unlink'),
                        ),
                      ],
                    ),
              );

              if (confirm == true) {
                try {
                  await _supabaseService.unlinkGoogleAccount();
                  await _checkGoogleLinkStatus();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Google account unlinked')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ErrorService.showError(context, e, operation: 'unlinkGoogle');
                  }
                }
              }
            },
          ),

        _buildSettingsTile(
          icon: Icons.help_outline,
          iconColor: Colors.purple,
          title: 'Help & Support',
          subtitle: 'Get help with the app',
          isDarkMode: isDarkMode,
          onTap: () {
            // Navigate to help screen
          },
        ),

        _buildSettingsTile(
          icon: Icons.privacy_tip_outlined,
          iconColor: Colors.teal,
          title: 'Privacy Policy',
          subtitle: 'Learn how we protect your data',
          isDarkMode: isDarkMode,
          onTap: () {
            // Open privacy policy
          },
        ),
      ],
    );
  }

  Widget _buildLogoutButton(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed: _handleLogout,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          minimumSize: const Size(double.infinity, 50),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Logout',
              style: AppTextStyles.buttonSwitzer.copyWith(
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDarkMode,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? AppColors.borderDark : AppColors.borderPrimary,
        ),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: AppTextStyles.cardTitle.copyWith(
            color:
                isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.bodySmall.copyWith(
            color:
                isDarkMode
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
          ),
        ),
        trailing:
            trailing ??
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color:
                  isDarkMode
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
            ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required bool isDarkMode,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? AppColors.borderDark : AppColors.borderPrimary,
        ),
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: AppTextStyles.cardTitle.copyWith(
            color:
                isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.bodySmall.copyWith(
            color:
                isDarkMode
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
      ),
    );
  }

  // Bottom navigation is now handled by MainScaffold via AppShell.
}
