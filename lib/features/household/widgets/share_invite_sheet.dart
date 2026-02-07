// lib/features/household/widgets/share_invite_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:cleanslate/core/utils/theme_utils.dart';
import 'package:cleanslate/data/repositories/household_repository.dart';
import 'package:cleanslate/core/services/error_service.dart';

/// Deep link scheme for CleanSlate app
const String kDeepLinkScheme = 'cleanslate';
const String kDeepLinkHost = 'join';

/// Generates a deep link URL for joining a household
String generateInviteLink(String code) {
  return '$kDeepLinkScheme://$kDeepLinkHost/$code';
}

class ShareInviteSheet extends StatefulWidget {
  final String householdId;
  final String householdName;
  final String initialCode;
  final bool isAdmin;

  const ShareInviteSheet({
    super.key,
    required this.householdId,
    required this.householdName,
    required this.initialCode,
    this.isAdmin = false,
  });

  /// Show the share invite bottom sheet. Returns the new code if regenerated.
  static Future<String?> show(
    BuildContext context, {
    required String householdId,
    required String householdName,
    required String code,
    bool isAdmin = false,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ShareInviteSheet(
        householdId: householdId,
        householdName: householdName,
        initialCode: code,
        isAdmin: isAdmin,
      ),
    );
  }

  @override
  State<ShareInviteSheet> createState() => _ShareInviteSheetState();
}

class _ShareInviteSheetState extends State<ShareInviteSheet> {
  final _repository = HouseholdRepository();
  late String _code;
  bool _isRegenerating = false;

  @override
  void initState() {
    super.initState();
    _code = widget.initialCode;
  }

  Future<void> _regenerateCode() async {
    setState(() => _isRegenerating = true);
    try {
      final newCode = await _repository.regenerateCode(widget.householdId);
      setState(() => _code = newCode);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invite code regenerated'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) ErrorService.showError(context, e, operation: 'regenerateCode');
    } finally {
      if (mounted) setState(() => _isRegenerating = false);
    }
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareCode() {
    final inviteLink = generateInviteLink(_code);
    final box = context.findRenderObject() as RenderBox?;
    final sharePositionOrigin = box != null 
        ? box.localToGlobal(Offset.zero) & box.size 
        : null;
    
    Share.share(
      'Join my household "${widget.householdName}" on CleanSlate!\n\n'
      '📱 Tap to join: $inviteLink\n\n'
      'Or enter code manually: $_code',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ThemeUtils.isDarkMode(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.borderDark : AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Share Invite Code',
              style: TextStyle(
                fontSize: 20,
                fontFamily: 'Switzer',
                fontWeight: FontWeight.bold,
                color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Share this code with people you want to invite to "${widget.householdName}"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'VarelaRound',
                color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // QR Code display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  QrImageView(
                    data: generateInviteLink(_code),
                    version: QrVersions.auto,
                    size: 180,
                    backgroundColor: Colors.white,
                    eyeStyle: QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: AppColors.primary,
                    ),
                    dataModuleStyle: QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Code display below QR
                  GestureDetector(
                    onTap: _copyCode,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? AppColors.backgroundDark
                            : const Color(0xFFF4F3EE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _code,
                            style: TextStyle(
                              fontSize: 20,
                              fontFamily: 'Switzer',
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.copy_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copyCode,
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copy'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _shareCode,
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Share'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textLight,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Regenerate button - admin only
            if (widget.isAdmin) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _isRegenerating ? null : _regenerateCode,
                icon: _isRegenerating
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      )
                    : Icon(Icons.refresh_rounded, size: 18, color: AppColors.textSecondary),
                label: Text(
                  'Regenerate Code',
                  style: TextStyle(
                    fontFamily: 'VarelaRound',
                    color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
