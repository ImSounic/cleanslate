// lib/features/stats/screens/chore_stats_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:cleanslate/core/constants/app_text_styles.dart';
import 'package:cleanslate/core/utils/debug_logger.dart';
import 'package:cleanslate/data/services/chore_stats_service.dart';
import 'package:cleanslate/data/services/household_service.dart';
import 'package:provider/provider.dart';
import 'package:cleanslate/core/providers/theme_provider.dart';

class ChoreStatsScreen extends StatefulWidget {
  const ChoreStatsScreen({super.key});

  @override
  State<ChoreStatsScreen> createState() => _ChoreStatsScreenState();
}

class _ChoreStatsScreenState extends State<ChoreStatsScreen> {
  final _statsService = ChoreStatsService();
  bool _isLoading = true;

  List<MemberStats> _weeklyStats = [];
  List<MemberStats> _monthlyStats = [];
  List<MemberStats> _allTimeStats = [];
  Map<String, int> _distribution = {};
  PersonalStats? _personalStats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final householdId = HouseholdService().currentHousehold?.id;
    if (householdId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
      final monthStart = DateTime(now.year, now.month, 1);

      final results = await Future.wait([
        _statsService.getMemberStats(householdId, from: weekStartDate),
        _statsService.getMemberStats(householdId, from: monthStart),
        _statsService.getMemberStats(householdId),
        _statsService.getChoreTypeDistribution(householdId),
        _statsService.getPersonalStats(householdId),
      ]);

      setState(() {
        _weeklyStats = results[0] as List<MemberStats>;
        _monthlyStats = results[1] as List<MemberStats>;
        _allTimeStats = results[2] as List<MemberStats>;
        _distribution = results[3] as Map<String, int>;
        _personalStats = results[4] as PersonalStats;
        _isLoading = false;
      });
    } catch (e) {
      debugLog('ChoreStatsScreen._loadStats error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppColors.backgroundDark : AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDarkMode ? AppColors.iconPrimaryDark : AppColors.iconPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Household Stats',
          style: AppTextStyles.heading3.copyWith(
            color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: isDarkMode ? AppColors.primaryDark : AppColors.primary,
              ),
            )
          : _buildBody(isDarkMode),
    );
  }

  Widget _buildBody(bool isDarkMode) {
    final hasAnyData = _weeklyStats.isNotEmpty ||
        _monthlyStats.isNotEmpty ||
        _allTimeStats.isNotEmpty;

    if (!hasAnyData && _personalStats?.totalCompleted == 0) {
      return _buildEmptyState(isDarkMode);
    }

    return RefreshIndicator(
      onRefresh: _loadStats,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: This Week
            _buildSectionHeader('This Week', _weekDateRange(), isDarkMode),
            const SizedBox(height: 12),
            _buildMemberBars(_weeklyStats, isDarkMode),
            const SizedBox(height: 28),

            // Section 2: This Month
            _buildSectionHeader('This Month', _monthDateRange(), isDarkMode),
            const SizedBox(height: 12),
            _buildMemberBars(_monthlyStats, isDarkMode),
            const SizedBox(height: 28),

            // Section 3: Chore Distribution
            if (_distribution.isNotEmpty) ...[
              _buildSectionHeader('Chore Distribution', null, isDarkMode),
              const SizedBox(height: 12),
              _buildDistributionChart(isDarkMode),
              const SizedBox(height: 28),
            ],

            // Section 4: All-Time Leaderboard
            _buildSectionHeader('All-Time Leaderboard', null, isDarkMode),
            const SizedBox(height: 12),
            _buildLeaderboard(isDarkMode),
            const SizedBox(height: 28),

            // Section 5: Personal Stats
            if (_personalStats != null) ...[
              _buildSectionHeader('Your Stats', null, isDarkMode),
              const SizedBox(height: 12),
              _buildPersonalStatsCard(isDarkMode),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bar_chart_rounded,
            size: 80,
            color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No stats yet',
            style: AppTextStyles.dialogTitle.copyWith(
              color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete some chores to see statistics!',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────

  String _weekDateRange() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));
    final fmt = DateFormat('MMM d');
    return '${fmt.format(weekStart)} – ${fmt.format(weekEnd)}';
  }

  String _monthDateRange() {
    final now = DateTime.now();
    return DateFormat('MMMM yyyy').format(now);
  }

  Widget _buildSectionHeader(String title, String? subtitle, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.heading3.copyWith(
            color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
      ],
    );
  }

  // ── Section 1 & 2: Member bar charts ────────────────────────

  Widget _buildMemberBars(List<MemberStats> stats, bool isDarkMode) {
    if (stats.isEmpty) {
      return _buildCardContainer(
        isDarkMode,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No completed chores in this period',
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    final maxCount = stats.fold<int>(0, (m, s) => s.completedCount > m ? s.completedCount : m);

    return _buildCardContainer(
      isDarkMode,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: stats.map((member) {
            final fraction = maxCount > 0 ? member.completedCount / maxCount : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.avatarColorFor(member.userId),
                    backgroundImage: member.profileImageUrl != null
                        ? NetworkImage(member.profileImageUrl!)
                        : null,
                    child: member.profileImageUrl == null
                        ? Text(
                            member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontFamily: 'VarelaRound',
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  // Name
                  SizedBox(
                    width: 80,
                    child: Text(
                      member.name.split(' ').first,
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'VarelaRound',
                        color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Bar
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: fraction,
                        minHeight: 18,
                        backgroundColor: isDarkMode
                            ? AppColors.surfaceDark.withValues(alpha: 0.5)
                            : AppColors.primary.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.avatarColorFor(member.userId),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Count
                  Text(
                    '${member.completedCount}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Switzer',
                      color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Section 3: Pie chart ────────────────────────────────────

  static const List<Color> _chartPalette = [
    Color(0xFF586AAF),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFFF44336),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
    Color(0xFFFFEB3B),
    Color(0xFF795548),
    Color(0xFFE91E63),
    Color(0xFF607D8B),
  ];

  Widget _buildDistributionChart(bool isDarkMode) {
    final total = _distribution.values.fold<int>(0, (a, b) => a + b);
    final entries = _distribution.entries.toList();

    return _buildCardContainer(
      isDarkMode,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: List.generate(entries.length, (i) {
                    final pct = total > 0 ? (entries[i].value / total * 100) : 0.0;
                    return PieChartSectionData(
                      value: entries[i].value.toDouble(),
                      title: '${pct.round()}%',
                      color: _chartPalette[i % _chartPalette.length],
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'VarelaRound',
                      ),
                    );
                  }),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Legend
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: List.generate(entries.length, (i) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _chartPalette[i % _chartPalette.length],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${entries[i].key} (${entries[i].value})',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'VarelaRound',
                        color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section 4: Leaderboard ──────────────────────────────────

  Widget _buildLeaderboard(bool isDarkMode) {
    if (_allTimeStats.isEmpty) {
      return _buildCardContainer(
        isDarkMode,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No completed chores yet',
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    const rankColors = [
      Color(0xFFFFD700), // Gold
      Color(0xFFC0C0C0), // Silver
      Color(0xFFCD7F32), // Bronze
    ];

    return _buildCardContainer(
      isDarkMode,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: List.generate(_allTimeStats.length, (i) {
            final member = _allTimeStats[i];
            final rank = i + 1;
            final isTopThree = i < 3;

            return ListTile(
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      '#$rank',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Switzer',
                        color: isTopThree
                            ? rankColors[i]
                            : isDarkMode
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.avatarColorFor(member.userId),
                    backgroundImage: member.profileImageUrl != null
                        ? NetworkImage(member.profileImageUrl!)
                        : null,
                    child: member.profileImageUrl == null
                        ? Text(
                            member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontFamily: 'VarelaRound',
                            ),
                          )
                        : null,
                  ),
                ],
              ),
              title: Text(
                member.name,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'VarelaRound',
                  fontWeight: isTopThree ? FontWeight.bold : FontWeight.normal,
                  color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                ),
              ),
              trailing: Text(
                '${member.completedCount}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Switzer',
                  color: isTopThree
                      ? rankColors[i]
                      : isDarkMode
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── Section 5: Personal Stats ───────────────────────────────

  Widget _buildPersonalStatsCard(bool isDarkMode) {
    final stats = _personalStats!;

    return _buildCardContainer(
      isDarkMode,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatTile(
                    '🏆',
                    '${stats.totalCompleted}',
                    'Total Completed',
                    isDarkMode,
                  ),
                ),
                Expanded(
                  child: _buildStatTile(
                    '🔥',
                    '${stats.currentStreak}',
                    'Day Streak',
                    isDarkMode,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatTile(
                    '📅',
                    '${stats.thisWeekCount}',
                    'This Week',
                    isDarkMode,
                  ),
                ),
                Expanded(
                  child: _buildStatTile(
                    '📆',
                    '${stats.thisMonthCount}',
                    'This Month',
                    isDarkMode,
                  ),
                ),
              ],
            ),
            if (stats.mostCommonType != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Text(
                      'Most common: ${stats.mostCommonType}',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'VarelaRound',
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String emoji, String value, String label, bool isDarkMode) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            fontFamily: 'Switzer',
            color: isDarkMode ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'VarelaRound',
            color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ── Card container ──────────────────────────────────────────

  Widget _buildCardContainer(bool isDarkMode, {required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: child,
    );
  }
}
