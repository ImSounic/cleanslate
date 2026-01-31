// lib/features/members/widgets/share_code_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:cleanslate/data/services/household_service.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cleanslate/core/utils/theme_utils.dart';

class ShareCodeDialog extends StatelessWidget {
  const ShareCodeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final household = HouseholdService().currentHousehold;
    final code = household?.code ?? '';
    final isDarkMode = ThemeUtils.isDarkMode(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDarkMode ? AppColors.surfaceDark : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Share Household',
              style: TextStyle(
                fontSize: 24,
                fontFamily: 'Switzer',
                fontWeight: FontWeight.bold,
                color:
                    isDarkMode
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scan this QR code or share the code below',
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'VarelaRound',
                color:
                    isDarkMode
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // QR Code
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: code,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Colors.black,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                  errorStateBuilder: (cxt, err) {
                    return Center(
                      child: Text(
                        'Error generating QR code',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.error),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Code display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary),
              ),
              child: Center(
                child: SelectableText(
                  code,
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: 'Switzer',
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: code));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Code copied to clipboard'),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy Code'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // Share functionality
                      final text =
                          'Join my household on CleanSlate!\n\nCode: $code';
                      await Clipboard.setData(ClipboardData(text: text));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invite text copied!')),
                        );
                      }
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textLight,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(
                  color:
                      isDarkMode
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
