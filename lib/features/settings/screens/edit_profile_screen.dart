// lib/features/settings/screens/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:cleanslate/core/utils/theme_utils.dart';
import 'package:cleanslate/data/services/supabase_service.dart';
import 'package:cleanslate/features/auth/screens/login_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cleanslate/core/providers/theme_provider.dart';
import 'dart:io';
import 'package:cleanslate/core/utils/input_sanitizer.dart';
import 'package:cleanslate/core/services/error_service.dart';
import 'package:cleanslate/core/utils/debug_logger.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _supabaseService = SupabaseService();

  bool _isLoading = false;
  String? _profileImageUrl;
  File? _localProfileImage;
  bool _photoRemoved = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _supabaseService.currentUser;
      if (user != null) {
        final userData = user.userMetadata;
        setState(() {
          _nameController.text = userData?['full_name'] ?? '';
          _emailController.text = user.email ?? '';
          _phoneController.text = userData?['phone_number'] ?? '';
          _bioController.text = userData?['bio'] ?? '';
          _profileImageUrl = userData?['profile_image_url'];
        });
      }
    } catch (e) {
      if (mounted) {
        ErrorService.showError(context, e, operation: 'loadProfile');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // First handle the profile image if needed
      String? newProfileImageUrl;

      if (_localProfileImage != null) {
        // Upload new image to Supabase
        newProfileImageUrl = await _supabaseService.uploadProfileImage(
          _localProfileImage!.path,
        );
      } else if (_photoRemoved) {
        // Remove the profile image from storage
        await _supabaseService.removeProfileImage();
        newProfileImageUrl = null;
      } else {
        // Keep existing image
        newProfileImageUrl = _profileImageUrl;
      }

      // Sanitize inputs before DB write
      final sanitizedName = sanitizeProfileName(_nameController.text);
      final sanitizedPhone = sanitizePhoneNumber(_phoneController.text);
      final sanitizedBio = sanitizeBio(_bioController.text);

      // Then update user profile data
      await _supabaseService.updateUserProfile(
        fullName: sanitizedName,
        phoneNumber: sanitizedPhone,
        bio: sanitizedBio,
        profileImageUrl: newProfileImageUrl,
      );

      // Force refresh the user session to ensure updated metadata
      await _supabaseService.client.auth.refreshSession();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(
          context,
          true,
        ); // Return true to indicate profile was updated
      }
    } catch (e) {
      if (mounted) {
        ErrorService.showError(context, e, operation: 'saveProfile');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showPhotoOptions() {
    // Check if dark mode is enabled - WITH listen: false to avoid the provider error
    final isDarkMode =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Profile Photo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Switzer',
                      color:
                          isDarkMode
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ListTile(
                    leading: Icon(
                      Icons.photo_library,
                      color:
                          isDarkMode
                              ? AppColors.primaryDark
                              : AppColors.primary,
                    ),
                    title: Text(
                      'Choose from Gallery',
                      style: TextStyle(
                        fontFamily: 'VarelaRound',
                        color:
                            isDarkMode
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.camera_alt,
                      color:
                          isDarkMode
                              ? AppColors.primaryDark
                              : AppColors.primary,
                    ),
                    title: Text(
                      'Take a New Picture',
                      style: TextStyle(
                        fontFamily: 'VarelaRound',
                        color:
                            isDarkMode
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  Divider(
                    color:
                        isDarkMode ? AppColors.dividerDark : AppColors.border,
                  ),
                  ListTile(
                    leading: Icon(Icons.delete, color: AppColors.error),
                    title: Text(
                      'Remove Photo',
                      style: TextStyle(
                        color: AppColors.error,
                        fontFamily: 'VarelaRound',
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _removeProfilePhoto();
                    },
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color:
                            isDarkMode
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                        fontFamily: 'VarelaRound',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _localProfileImage = File(pickedFile.path);
          _photoRemoved = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ErrorService.showError(context, e, operation: 'pickImage');
      }
    }
  }

  void _removeProfilePhoto() {
    setState(() {
      _photoRemoved = true;
      _localProfileImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if dark mode is enabled
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
          'Edit Profile',
          style: TextStyle(
            color: isDarkMode ? AppColors.textPrimaryDark : AppColors.primary,
            fontFamily: 'Switzer',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.check,
              color: isDarkMode ? AppColors.textPrimaryDark : AppColors.primary,
            ),
            onPressed: _isLoading ? null : _saveProfile,
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  color: isDarkMode ? AppColors.primaryDark : AppColors.primary,
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile photo
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color:
                                  isDarkMode
                                      ? AppColors.surfaceDark
                                      : AppColors.background,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    isDarkMode
                                        ? AppColors.primaryDark
                                        : AppColors.primary,
                                width: 2,
                              ),
                            ),
                            child: _buildProfileImage(isDarkMode),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _showPhotoOptions,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color:
                                      isDarkMode
                                          ? AppColors.primaryDark
                                          : AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  size: 20,
                                  color: AppColors.textLight,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Name field
                    Text(
                      'Name',
                      style: TextStyle(
                        color:
                            isDarkMode
                                ? AppColors.textPrimaryDark
                                : AppColors.primary,
                        fontFamily: 'VarelaRound',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      style: TextStyle(
                        color:
                            isDarkMode
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                        fontFamily: 'VarelaRound',
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter your name',
                        hintStyle: TextStyle(
                          color:
                              isDarkMode
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color:
                                isDarkMode
                                    ? AppColors.borderDark
                                    : AppColors.border,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color:
                                isDarkMode
                                    ? AppColors.borderDark
                                    : AppColors.border,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color:
                                isDarkMode
                                    ? AppColors.primaryDark
                                    : AppColors.primary,
                          ),
                        ),
                        filled: true,
                        fillColor:
                            isDarkMode ? AppColors.surfaceDark : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Email field
                    Text(
                      'Email',
                      style: TextStyle(
                        color:
                            isDarkMode
                                ? AppColors.textPrimaryDark
                                : AppColors.primary,
                        fontFamily: 'VarelaRound',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      readOnly: true, // Email can't be changed
                      style: TextStyle(
                        color:
                            isDarkMode
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                        fontFamily: 'VarelaRound',
                      ),
                      decoration: InputDecoration(
                        hintText: 'Your email address',
                        hintStyle: TextStyle(
                          color:
                              isDarkMode
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color:
                                isDarkMode
                                    ? AppColors.borderDark
                                    : AppColors.border,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color:
                                isDarkMode
                                    ? AppColors.borderDark
                                    : AppColors.border,
                          ),
                        ),
                        filled: true,
                        fillColor:
                            isDarkMode
                                ? AppColors.surfaceDark.withValues(alpha: 0.5)
                                : Colors.grey[100],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Phone field
                    Text(
                      'Phone Number',
                      style: TextStyle(
                        color:
                            isDarkMode
                                ? AppColors.textPrimaryDark
                                : AppColors.primary,
                        fontFamily: 'VarelaRound',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phoneController,
                      style: TextStyle(
                        color:
                            isDarkMode
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                        fontFamily: 'VarelaRound',
                      ),
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'Enter your phone number',
                        hintStyle: TextStyle(
                          color:
                              isDarkMode
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color:
                                isDarkMode
                                    ? AppColors.borderDark
                                    : AppColors.border,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color:
                                isDarkMode
                                    ? AppColors.borderDark
                                    : AppColors.border,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color:
                                isDarkMode
                                    ? AppColors.primaryDark
                                    : AppColors.primary,
                          ),
                        ),
                        filled: true,
                        fillColor:
                            isDarkMode ? AppColors.surfaceDark : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Bio field
                    Text(
                      'Bio',
                      style: TextStyle(
                        color:
                            isDarkMode
                                ? AppColors.textPrimaryDark
                                : AppColors.primary,
                        fontFamily: 'VarelaRound',
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _bioController,
                      style: TextStyle(
                        color:
                            isDarkMode
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                        fontFamily: 'VarelaRound',
                      ),
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Tell others about yourself',
                        hintStyle: TextStyle(
                          color:
                              isDarkMode
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color:
                                isDarkMode
                                    ? AppColors.borderDark
                                    : AppColors.border,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color:
                                isDarkMode
                                    ? AppColors.borderDark
                                    : AppColors.border,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color:
                                isDarkMode
                                    ? AppColors.primaryDark
                                    : AppColors.primary,
                          ),
                        ),
                        filled: true,
                        fillColor:
                            isDarkMode ? AppColors.surfaceDark : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Danger Zone
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Danger Zone',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontFamily: 'Switzer',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Permanently delete your account and all associated data. This action cannot be undone.',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontFamily: 'VarelaRound',
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _showDeleteAccountDialog(isDarkMode),
                              icon: const Icon(Icons.delete_forever, color: Colors.white),
                              label: const Text(
                                'Delete Account',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'VarelaRound',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      // Bottom navigation removed — handled by MainScaffold via AppShell.
    );
  }

  Widget _buildProfileImage(bool isDarkMode) {
    if (_localProfileImage != null) {
      // Show the newly selected image
      return ClipOval(
        child: Image.file(
          _localProfileImage!,
          fit: BoxFit.cover,
          width: 120,
          height: 120,
        ),
      );
    } else if (!_photoRemoved && _profileImageUrl != null) {
      // Show the existing profile image from Supabase
      return ClipOval(
        child: Image.network(
          _profileImageUrl!,
          fit: BoxFit.cover,
          width: 120,
          height: 120,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value:
                    loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                color: isDarkMode ? AppColors.primaryDark : AppColors.primary,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Icon(
              Icons.person,
              size: 60,
              color:
                  isDarkMode
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
            );
          },
        ),
      );
    } else {
      // Show placeholder icon
      return Icon(
        Icons.person,
        size: 60,
        color:
            isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
      );
    }
  }

  Future<void> _showDeleteAccountDialog(bool isDarkMode) async {
    final TextEditingController confirmController = TextEditingController();
    bool isDeleting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                  const SizedBox(width: 8),
                  Text(
                    'Delete Account?',
                    style: TextStyle(
                      color: Colors.red,
                      fontFamily: 'Switzer',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This action is permanent and cannot be undone.',
                      style: TextStyle(
                        fontFamily: 'VarelaRound',
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'The following will be permanently deleted:',
                      style: TextStyle(
                        fontFamily: 'VarelaRound',
                        color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDeleteItem('Your profile and personal information'),
                    _buildDeleteItem('All your chore assignments'),
                    _buildDeleteItem('Your chore preferences'),
                    _buildDeleteItem('Households you own (if sole member)'),
                    const SizedBox(height: 16),
                    Text(
                      'Type DELETE to confirm:',
                      style: TextStyle(
                        fontFamily: 'VarelaRound',
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: confirmController,
                      decoration: InputDecoration(
                        hintText: 'DELETE',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.red),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.red, width: 2),
                        ),
                      ),
                      style: TextStyle(
                        fontFamily: 'VarelaRound',
                        color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(dialogContext),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: isDeleting || confirmController.text != 'DELETE'
                      ? null
                      : () async {
                          setDialogState(() => isDeleting = true);
                          await _deleteAccount(dialogContext);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    disabledBackgroundColor: Colors.red.withValues(alpha: 0.3),
                  ),
                  child: isDeleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Delete Account',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDeleteItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(Icons.remove_circle, color: Colors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontFamily: 'VarelaRound',
                fontSize: 13,
                color: Colors.red.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext dialogContext) async {
    // Capture context references before async gap
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final dialogNavigator = Navigator.of(dialogContext);
    
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Call the Supabase RPC function to delete all user data
      await _supabaseService.client.rpc('delete_user_account');

      // Sign out the user
      await _supabaseService.signOut();

      // Close dialog and navigate to login
      if (mounted) {
        dialogNavigator.pop(); // Close dialog
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );

        // Show success message
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugLog('Error deleting account: $e');
      if (mounted) {
        dialogNavigator.pop(); // Close dialog
        ErrorService.showError(context, e, operation: 'deleteAccount');
      }
    }
  }
}
