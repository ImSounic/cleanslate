// lib/features/settings/screens/edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:cleanslate/core/utils/theme_utils.dart';
import 'package:cleanslate/data/services/supabase_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: ${e.toString()}')),
        );
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

      // Then update user profile data
      await _supabaseService.updateUserProfile(
        fullName: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        bio: _bioController.text.trim(),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showPhotoOptions() {
    // Check if dark mode is enabled
    final isDarkMode = ThemeUtils.isDarkMode(context);

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: ${e.toString()}')),
        );
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
                                ? AppColors.surfaceDark.withOpacity(0.5)
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

                    // Delete Account button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _showDeleteAccountConfirmation(isDarkMode);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Delete Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: 'VarelaRound',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      // Removed the bottomNavigationBar to fix the duplicate navigation issue
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

  void _showDeleteAccountConfirmation(bool isDarkMode) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
          title: Text(
            'Delete Account',
            style: TextStyle(
              color:
                  isDarkMode
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
            ),
          ),
          content: Text(
            'Are you sure you want to delete your account? This action cannot be undone.',
            style: TextStyle(
              color:
                  isDarkMode
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color:
                      isDarkMode
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteAccount();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteAccount() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _supabaseService.deleteAccount();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account successfully deleted')),
        );

        // Navigate to login screen and clear all previous routes
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (Route<dynamic> route) => false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting account: ${e.toString()}')),
        );
      }
    }
  }
}
