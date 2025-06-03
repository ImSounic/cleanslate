// lib/features/settings/screens/settings_screen.dart
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:cleanslate/core/utils/theme_utils.dart';
import 'package:cleanslate/data/services/supabase_service.dart';
import 'package:cleanslate/features/auth/screens/login_screen.dart';
import 'package:cleanslate/features/members/screens/members_screen.dart';
import 'package:cleanslate/features/settings/screens/edit_profile_screen.dart';
import 'package:cleanslate/features/settings/screens/add_password_screen.dart';
import 'package:cleanslate/features/schedule/screens/schedule_screen.dart';
import 'package:cleanslate/features/home/screens/home_screen.dart';
import 'package:provider/provider.dart';
import 'package:cleanslate/core/providers/theme_provider.dart';

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
  int _selectedNavIndex = 3; // Settings tab selected
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
        });
      }
    } catch (e) {
      // Handle error
      print('Error loading user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkGoogleLinkStatus() async {
    try {
      final hasGoogle = await _supabaseService.hasGoogleLinked();
      setState(() {
        _hasGoogleLinked = hasGoogle;
      });
    } catch (e) {
      print('Error checking Google link status: $e');
    }
  }

  Future<void> _handleGoogleLink() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_hasGoogleLinked) {
        // Unlink Google account
        await _supabaseService.unlinkGoogleAccount();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Google account unlinked successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        // Link Google account
        await _supabaseService.linkGoogleAccount();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Google account linked successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }

      // Refresh user data and Google link status
      await _loadUserData();
      await _checkGoogleLinkStatus();
    } catch (e) {
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.contains('Exception: ')) {
          errorMessage = errorMessage.split('Exception: ').last;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access the theme provider to check if dark mode is enabled
    final isDarkMode = ThemeUtils.isDarkMode(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

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
          'Settings',
          style: TextStyle(
            color: isDarkMode ? AppColors.textPrimaryDark : AppColors.primary,
            fontFamily: 'Switzer',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  color: isDarkMode ? AppColors.primaryDark : AppColors.primary,
                ),
              )
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Profile Card
                      _buildProfileCard(isDarkMode),
                      const SizedBox(height: 24),

                      // Account Section
                      _buildSectionTitle('Account', isDarkMode),
                      _buildSectionSubtitle(
                        'Manage your account settings',
                        isDarkMode,
                      ),
                      const SizedBox(height: 12),

                      // Show authentication status based on provider
                      _buildAuthenticationStatus(isDarkMode),

                      const SizedBox(height: 24),

                      // Notifications Section
                      _buildSectionTitle('Notifications', isDarkMode),
                      _buildSectionSubtitle(
                        'Manage your notification preferences',
                        isDarkMode,
                      ),
                      const SizedBox(height: 12),
                      _buildToggleItem(
                        icon: Icons.notifications_outlined,
                        title: 'Push Notifications',
                        value: _pushNotifications,
                        onChanged: (value) {
                          setState(() {
                            _pushNotifications = value;
                          });
                        },
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 12),
                      _buildToggleItem(
                        icon: Icons.alarm,
                        title: 'Reminders',
                        value: _reminders,
                        onChanged: (value) {
                          setState(() {
                            _reminders = value;
                          });
                        },
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 24),

                      // Appearance Section
                      _buildSectionTitle('Others', isDarkMode),
                      const SizedBox(height: 12),
                      _buildToggleItem(
                        icon: Icons.dark_mode_outlined,
                        title: 'Dark Mode',
                        value: isDarkMode,
                        onChanged: (value) {
                          themeProvider.toggleTheme();
                        },
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 12),

                      // Other Settings
                      _buildNavigationItem(
                        icon: Icons.people_outline,
                        title: 'Members',
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MembersScreen(),
                            ),
                          );
                        },
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 12),

                      // Schedule Item
                      _buildNavigationItem(
                        icon: Icons.calendar_today_outlined,
                        title: 'Schedule',
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ScheduleScreen(),
                            ),
                          );
                        },
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 12),

                      _buildNavigationItem(
                        icon: Icons.language,
                        title: 'Language',
                        trailing: 'English (US)',
                        onTap: () {
                          // Show language selection dialog
                        },
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 12),
                      _buildNavigationItem(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        onTap: () {
                          // Navigate to Help & Support screen
                        },
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 12),
                      _buildNavigationItem(
                        icon: Icons.logout,
                        title: 'Log Out',
                        isDestructive: true,
                        onTap: () async {
                          await _handleLogout();
                        },
                        isDarkMode: isDarkMode,
                      ),
                      const SizedBox(height: 32),

                      // Footer
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'CleanSlate v1.0.0',
                              style: TextStyle(
                                color:
                                    isDarkMode
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondary,
                                fontSize: 12,
                                fontFamily: 'VarelaRound',
                              ),
                            ),
                            Text(
                              '© 2025 CleanSlate. All rights reserved.',
                              style: TextStyle(
                                color:
                                    isDarkMode
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondary,
                                fontSize: 12,
                                fontFamily: 'VarelaRound',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDarkMode ? AppColors.borderDark : AppColors.border,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedNavIndex,
          onTap: (index) {
            if (index != _selectedNavIndex) {
              setState(() {
                _selectedNavIndex = index;
              });

              // Handle navigation
              if (index == 0) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
              } else if (index == 1) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MembersScreen(),
                  ),
                );
              } else if (index == 2) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ScheduleScreen(),
                  ),
                );
              }
            }
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor:
              isDarkMode ? AppColors.navSelectedDark : AppColors.navSelected,
          unselectedItemColor:
              isDarkMode
                  ? AppColors.navUnselectedDark
                  : AppColors.navUnselected,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          backgroundColor:
              isDarkMode ? AppColors.backgroundDark : AppColors.background,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/images/icons/home.svg',
                height: 24,
                width: 24,
                colorFilter: ColorFilter.mode(
                  _selectedNavIndex == 0
                      ? (isDarkMode
                          ? AppColors.navSelectedDark
                          : AppColors.navSelected)
                      : (isDarkMode
                          ? AppColors.navUnselectedDark
                          : AppColors.navUnselected),
                  BlendMode.srcIn,
                ),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/images/icons/members.svg',
                height: 24,
                width: 24,
                colorFilter: ColorFilter.mode(
                  _selectedNavIndex == 1
                      ? (isDarkMode
                          ? AppColors.navSelectedDark
                          : AppColors.navSelected)
                      : (isDarkMode
                          ? AppColors.navUnselectedDark
                          : AppColors.navUnselected),
                  BlendMode.srcIn,
                ),
              ),
              label: 'Members',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/images/icons/schedule.svg',
                height: 24,
                width: 24,
                colorFilter: ColorFilter.mode(
                  _selectedNavIndex == 2
                      ? (isDarkMode
                          ? AppColors.navSelectedDark
                          : AppColors.navSelected)
                      : (isDarkMode
                          ? AppColors.navUnselectedDark
                          : AppColors.navUnselected),
                  BlendMode.srcIn,
                ),
              ),
              label: 'Calendar',
            ),
            BottomNavigationBarItem(
              icon: SvgPicture.asset(
                'assets/images/icons/settings.svg',
                height: 24,
                width: 24,
                colorFilter: ColorFilter.mode(
                  _selectedNavIndex == 3
                      ? (isDarkMode
                          ? AppColors.navSelectedDark
                          : AppColors.navSelected)
                      : (isDarkMode
                          ? AppColors.navUnselectedDark
                          : AppColors.navUnselected),
                  BlendMode.srcIn,
                ),
              ),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthenticationStatus(bool isDarkMode) {
    // Determine what to show based on auth provider
    if (_authProvider == 'google') {
      // User signed in with Google only
      return Column(
        children: [
          _buildGoogleOnlyStatus(isDarkMode),
          const SizedBox(height: 12),
          _buildAddPasswordOption(isDarkMode),
        ],
      );
    } else if (_authProvider == 'email') {
      // User signed in with email, can link Google
      return _buildGoogleLinkItem(isDarkMode);
    } else if (_authProvider == 'email_and_google') {
      // User has both methods available
      return _buildGoogleLinkItem(isDarkMode);
    } else {
      // Unknown state, show current auth method
      return Container();
    }
  }

  Widget _buildGoogleOnlyStatus(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? AppColors.borderDark : AppColors.borderPrimary,
        ),
      ),
      child: ListTile(
        leading: SvgPicture.asset(
          'assets/images/google_logo.svg',
          height: 24,
          width: 24,
        ),
        title: Text(
          'Signed in with Google',
          style: TextStyle(
            fontFamily: 'Switzer',
            color:
                isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          'You\'re using Google Sign-In for this account',
          style: TextStyle(
            fontFamily: 'VarelaRound',
            fontSize: 12,
            color:
                isDarkMode
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
          ),
        ),
        trailing: Icon(Icons.check_circle, color: AppColors.success),
      ),
    );
  }

  Widget _buildAddPasswordOption(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? AppColors.borderDark : AppColors.borderPrimary,
        ),
      ),
      child: ListTile(
        leading: Icon(
          Icons.lock_outline,
          color: isDarkMode ? AppColors.textPrimaryDark : AppColors.primary,
        ),
        title: Text(
          'Add Password',
          style: TextStyle(
            fontFamily: 'Switzer',
            color:
                isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          'Add a password to sign in without Google',
          style: TextStyle(
            fontFamily: 'VarelaRound',
            fontSize: 12,
            color:
                isDarkMode
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color:
              isDarkMode
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
        ),
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPasswordScreen()),
          );

          if (result == true) {
            // Reload user data to reflect the change
            await _loadUserData();
            await _checkGoogleLinkStatus();
          }
        },
      ),
    );
  }

  Widget _buildGoogleLinkItem(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? AppColors.borderDark : AppColors.borderPrimary,
        ),
      ),
      child: ListTile(
        leading: SvgPicture.asset(
          'assets/images/google_logo.svg',
          height: 24,
          width: 24,
        ),
        title: Text(
          _hasGoogleLinked ? 'Google Account Linked' : 'Link Google Account',
          style: TextStyle(
            fontFamily: 'Switzer',
            color:
                isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          _hasGoogleLinked
              ? 'Sign in with Google or email/password'
              : 'Connect for easier sign-in',
          style: TextStyle(
            fontFamily: 'VarelaRound',
            fontSize: 12,
            color:
                isDarkMode
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
          ),
        ),
        trailing:
            _isLoading
                ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color:
                        isDarkMode ? AppColors.primaryDark : AppColors.primary,
                  ),
                )
                : TextButton(
                  onPressed: _handleGoogleLink,
                  child: Text(
                    _hasGoogleLinked ? 'Unlink' : 'Link',
                    style: TextStyle(
                      color:
                          _hasGoogleLinked
                              ? AppColors.error
                              : (isDarkMode
                                  ? AppColors.primaryDark
                                  : AppColors.primary),
                      fontFamily: 'VarelaRound',
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildProfileCard(bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? AppColors.borderDark : AppColors.borderPrimary,
        ),
      ),
      child: Row(
        children: [
          _buildProfileImage(isDarkMode),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'Switzer',
                    fontWeight: FontWeight.bold,
                    color:
                        isDarkMode
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _userEmail,
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'VarelaRound',
                    color:
                        isDarkMode
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                  ),
                ),
                if (_authProvider != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(
                          _authProvider == 'google'
                              ? Icons.g_mobiledata
                              : (_authProvider == 'email_and_google'
                                  ? Icons.link
                                  : Icons.email),
                          size: 14,
                          color:
                              isDarkMode
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _authProvider == 'google'
                              ? 'Google Account'
                              : (_authProvider == 'email_and_google'
                                  ? 'Email & Google'
                                  : 'Email Account'),
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'VarelaRound',
                            color:
                                isDarkMode
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              ).then((result) {
                if (result == true) {
                  _loadUserData();
                }
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDarkMode ? AppColors.primaryDark : AppColors.primary,
              foregroundColor: AppColors.textLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text(
              'Edit',
              style: TextStyle(fontFamily: 'VarelaRound', fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage(bool isDarkMode) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isDarkMode ? AppColors.primaryDark : AppColors.primary,
          width: 2,
        ),
      ),
      child:
          _profileImageUrl != null
              ? ClipOval(
                child: Image.network(
                  _profileImageUrl!,
                  fit: BoxFit.cover,
                  width: 60,
                  height: 60,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value:
                            loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                        color:
                            isDarkMode
                                ? AppColors.primaryDark
                                : AppColors.primary,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.person,
                      size: 30,
                      color:
                          isDarkMode
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                    );
                  },
                ),
              )
              : Icon(
                Icons.person,
                size: 30,
                color:
                    isDarkMode
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
              ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontFamily: 'Switzer',
        fontWeight: FontWeight.bold,
        color: isDarkMode ? AppColors.textPrimaryDark : AppColors.primary,
      ),
    );
  }

  Widget _buildSectionSubtitle(String subtitle, bool isDarkMode) {
    return Text(
      subtitle,
      style: TextStyle(
        fontSize: 14,
        fontFamily: 'VarelaRound',
        color:
            isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
      ),
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
    required bool isDarkMode,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? AppColors.borderDark : AppColors.borderPrimary,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDarkMode ? AppColors.textPrimaryDark : AppColors.primary,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Switzer',
            color:
                isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: isDarkMode ? AppColors.primaryDark : AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildNavigationItem({
    required IconData icon,
    required String title,
    String? trailing,
    bool isDestructive = false,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? AppColors.borderDark : AppColors.borderPrimary,
        ),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color:
              isDestructive
                  ? AppColors.error
                  : (isDarkMode
                      ? AppColors.textPrimaryDark
                      : AppColors.primary),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontFamily: 'Switzer',
            color:
                isDestructive
                    ? AppColors.error
                    : (isDarkMode
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary),
          ),
        ),
        trailing:
            trailing != null
                ? Text(
                  trailing,
                  style: TextStyle(
                    fontFamily: 'VarelaRound',
                    color:
                        isDarkMode
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                  ),
                )
                : Icon(
                  Icons.chevron_right,
                  color:
                      isDarkMode
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                ),
        onTap: onTap,
      ),
    );
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }
}
