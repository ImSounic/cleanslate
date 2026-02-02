// lib/features/subscription/screens/upgrade_screen.dart

import 'package:flutter/material.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:cleanslate/core/constants/app_text_styles.dart';
import 'package:cleanslate/core/config/subscription_config.dart';
import 'package:cleanslate/core/utils/theme_utils.dart';
import 'package:cleanslate/data/services/subscription_service.dart';

class UpgradeScreen extends StatefulWidget {
  final String householdId;

  const UpgradeScreen({super.key, required this.householdId});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  SubscriptionUsage? _usage;
  bool _isLoading = true;
  int _selectedPlanIndex = 1; // default to annual

  static const Color _goldColor = Color(0xFFFFB800);
  static const Color _goldDark = Color(0xFFE5A600);

  @override
  void initState() {
    super.initState();
    _loadUsage();
  }

  Future<void> _loadUsage() async {
    try {
      final usage =
          await _subscriptionService.getUsage(widget.householdId);
      if (mounted) {
        setState(() {
          _usage = usage;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Coming soon — in-app purchases will be available in the next update',
        ),
        duration: Duration(seconds: 3),
      ),
    );
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
          icon: Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Upgrade Plan',
          style: AppTextStyles.heading3.copyWith(
            color:
                isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Plan Card
                  _buildCurrentPlanCard(isDarkMode),
                  const SizedBox(height: 24),

                  // Feature Comparison
                  Text(
                    'Compare Plans',
                    style: AppTextStyles.dialogTitle.copyWith(
                      color: isDarkMode
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureComparison(isDarkMode),
                  const SizedBox(height: 24),

                  // Pricing Cards
                  Text(
                    'Choose Your Plan',
                    style: AppTextStyles.dialogTitle.copyWith(
                      color: isDarkMode
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPricingCards(isDarkMode),
                  const SizedBox(height: 16),

                  // Upgrade button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed:
                          _usage?.tier.isPro == true ? null : _showComingSoon,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _goldColor,
                        foregroundColor: Colors.black87,
                        disabledBackgroundColor: isDarkMode
                            ? AppColors.surfaceDark
                            : Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _usage?.tier.isPro == true
                            ? 'Already on Pro'
                            : 'Upgrade to Pro',
                        style: AppTextStyles.buttonLarge.copyWith(
                          color: _usage?.tier.isPro == true
                              ? (isDarkMode
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary)
                              : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Restore purchases
                  Center(
                    child: TextButton(
                      onPressed: _showComingSoon,
                      child: Text(
                        'Restore Purchase',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDarkMode
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  // ── Current Plan Card ────────────────────────────────────────────

  Widget _buildCurrentPlanCard(bool isDarkMode) {
    final usage = _usage;
    if (usage == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: usage.tier.isPro
              ? _goldColor.withValues(alpha: 0.5)
              : (isDarkMode ? AppColors.borderDark : AppColors.border),
        ),
        boxShadow: usage.tier.isPro
            ? [
                BoxShadow(
                  color: _goldColor.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tier badge
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: usage.tier.isPro
                      ? const LinearGradient(
                          colors: [_goldColor, _goldDark],
                        )
                      : null,
                  color: usage.tier.isPro ? null : AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      usage.tier.isPro
                          ? Icons.workspace_premium_rounded
                          : Icons.person_rounded,
                      color: usage.tier.isPro ? Colors.black87 : Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${usage.tier.displayName} Plan',
                      style: AppTextStyles.bodySmall.copyWith(
                        color:
                            usage.tier.isPro ? Colors.black87 : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (!usage.tier.isPro)
                Text(
                  'Current Plan',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDarkMode
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Usage bars
          _buildUsageBar(
            label: 'Members',
            current: usage.memberCount,
            limit: usage.memberLimit,
            percent: usage.memberUsagePercent,
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 12),
          _buildUsageBar(
            label: 'Active Chores',
            current: usage.choreCount,
            limit: usage.choreLimit,
            percent: usage.choreUsagePercent,
            isDarkMode: isDarkMode,
          ),
          const SizedBox(height: 12),
          _buildUsageBar(
            label: 'Recurring Chores',
            current: usage.recurringCount,
            limit: usage.recurringLimit,
            percent: usage.recurringUsagePercent,
            isDarkMode: isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildUsageBar({
    required String label,
    required int current,
    required int limit,
    required double percent,
    required bool isDarkMode,
  }) {
    final isAtLimit = current >= limit;
    final barColor = isAtLimit ? AppColors.error : AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDarkMode
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
            ),
            Text(
              '$current / $limit',
              style: AppTextStyles.bodySmall.copyWith(
                color: isAtLimit
                    ? AppColors.error
                    : (isDarkMode
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: isDarkMode
                ? AppColors.borderDark
                : AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
      ],
    );
  }

  // ── Feature Comparison ───────────────────────────────────────────

  Widget _buildFeatureComparison(bool isDarkMode) {
    final features = [
      _FeatureRow('Household members', '${SubscriptionConfig.freeMaxMembers}',
          '${SubscriptionConfig.proMaxMembers}'),
      _FeatureRow('Active chores', '${SubscriptionConfig.freeMaxActiveChores}',
          '${SubscriptionConfig.proMaxActiveChores}'),
      _FeatureRow(
          'Recurring chores',
          '${SubscriptionConfig.freeMaxRecurringChores}',
          '${SubscriptionConfig.proMaxRecurringChores}'),
      _FeatureRow('Stats history', '7 days', '1 year'),
      _FeatureRow('Priority support', '✗', '✓'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          // Header row
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Feature',
                    style: AppTextStyles.sectionLabel.copyWith(
                      color: isDarkMode
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Free',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.sectionLabel.copyWith(
                      color: isDarkMode
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Pro ✨',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.sectionLabel.copyWith(
                      color: _goldColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Feature rows
          ...features.asMap().entries.map((entry) {
            final index = entry.key;
            final feature = entry.value;
            final isLast = index == features.length - 1;

            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : Border(
                        bottom: BorderSide(
                          color: isDarkMode
                              ? AppColors.borderDark
                              : AppColors.border,
                          width: 0.5,
                        ),
                      ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      feature.name,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDarkMode
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      feature.free,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDarkMode
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      feature.pro,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Pricing Cards ────────────────────────────────────────────────

  Widget _buildPricingCards(bool isDarkMode) {
    final plans = [
      _PricingPlan(
        title: 'Monthly',
        price: '\$${SubscriptionConfig.proMonthlyPrice.toStringAsFixed(2)}',
        period: '/mo',
        badge: null,
      ),
      _PricingPlan(
        title: 'Annual',
        price: '\$${SubscriptionConfig.proAnnualPrice.toStringAsFixed(2)}',
        period: '/yr',
        badge: 'Save 33%',
      ),
      _PricingPlan(
        title: 'Student',
        price:
            '\$${SubscriptionConfig.studentMonthlyPrice.toStringAsFixed(2)}',
        period: '/mo',
        badge: '.edu required',
      ),
    ];

    return Row(
      children: plans.asMap().entries.map((entry) {
        final index = entry.key;
        final plan = entry.value;
        final isSelected = _selectedPlanIndex == index;

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedPlanIndex = index),
            child: Container(
              margin: EdgeInsets.only(
                left: index == 0 ? 0 : 4,
                right: index == plans.length - 1 ? 0 : 4,
              ),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDarkMode
                        ? _goldColor.withValues(alpha: 0.12)
                        : _goldColor.withValues(alpha: 0.08))
                    : (isDarkMode ? AppColors.surfaceDark : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? _goldColor
                      : (isDarkMode
                          ? AppColors.borderDark
                          : AppColors.border),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    plan.title,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDarkMode
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    plan.price,
                    style: AppTextStyles.heading3.copyWith(
                      color: isSelected
                          ? _goldColor
                          : (isDarkMode
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary),
                    ),
                  ),
                  Text(
                    plan.period,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDarkMode
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                  if (plan.badge != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _goldColor.withValues(alpha: 0.2)
                            : AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        plan.badge!,
                        style: TextStyle(
                          fontSize: 9,
                          fontFamily: 'VarelaRound',
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? _goldDark
                              : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Helper models ─────────────────────────────────────────────────

class _FeatureRow {
  final String name;
  final String free;
  final String pro;
  _FeatureRow(this.name, this.free, this.pro);
}

class _PricingPlan {
  final String title;
  final String price;
  final String period;
  final String? badge;
  _PricingPlan({
    required this.title,
    required this.price,
    required this.period,
    this.badge,
  });
}
