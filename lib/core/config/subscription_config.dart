// lib/core/config/subscription_config.dart

/// Hard limits for each subscription tier.
class SubscriptionConfig {
  // Free tier
  static const int freeMaxMembers = 4;
  static const int freeMaxActiveChores = 15;
  static const int freeMaxRecurringChores = 5;
  static const int freeStatsHistoryDays = 7;

  // Pro tier (effectively unlimited)
  static const int proMaxMembers = 50;
  static const int proMaxActiveChores = 500;
  static const int proMaxRecurringChores = 100;
  static const int proStatsHistoryDays = 365;

  // Display pricing
  static const double proMonthlyPrice = 4.99;
  static const double proAnnualPrice = 39.99;
  static const double studentMonthlyPrice = 2.99;
  static const double studentAnnualPrice = 24.99;
}

enum SubscriptionTier {
  free,
  pro,
  studentPro;

  bool get isPro => this == pro || this == studentPro;

  String get displayName {
    switch (this) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.pro:
        return 'Pro';
      case SubscriptionTier.studentPro:
        return 'Student Pro';
    }
  }

  int get maxMembers =>
      isPro ? SubscriptionConfig.proMaxMembers : SubscriptionConfig.freeMaxMembers;
  int get maxActiveChores =>
      isPro ? SubscriptionConfig.proMaxActiveChores : SubscriptionConfig.freeMaxActiveChores;
  int get maxRecurringChores =>
      isPro ? SubscriptionConfig.proMaxRecurringChores : SubscriptionConfig.freeMaxRecurringChores;
  int get statsHistoryDays =>
      isPro ? SubscriptionConfig.proStatsHistoryDays : SubscriptionConfig.freeStatsHistoryDays;
}
