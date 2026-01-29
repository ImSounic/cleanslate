// lib/core/constants/app_text_styles.dart
import 'package:flutter/material.dart';

class AppTextStyles {
  // ── Headings ──────────────────────────────────────────────────────
  /// 48px Switzer w600, letterSpacing -3 — used for the Home greeting.
  static const TextStyle greeting = TextStyle(
    fontSize: 48,
    fontFamily: 'Switzer',
    fontWeight: FontWeight.w600,
    letterSpacing: -3,
  );

  /// 38px Switzer w600 — screen titles (Members).
  static const TextStyle screenTitle = TextStyle(
    fontSize: 38,
    fontFamily: 'Switzer',
    fontWeight: FontWeight.w600,
  );

  /// 32px Switzer bold — large section headings (Schedule, Admin).
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontFamily: 'Switzer',
    fontWeight: FontWeight.bold,
  );

  /// 24px Switzer bold — dialog/section headings.
  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontFamily: 'Switzer',
    fontWeight: FontWeight.bold,
  );

  /// 20px Switzer bold — sub-headings (settings header name, recurring title).
  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontFamily: 'Switzer',
    fontWeight: FontWeight.bold,
  );

  /// 18px Switzer bold — dialog titles, empty-state titles, section titles.
  static const TextStyle dialogTitle = TextStyle(
    fontSize: 18,
    fontFamily: 'Switzer',
    fontWeight: FontWeight.bold,
  );

  /// 16px Switzer w600 — card titles, profile names, setting tile titles.
  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontFamily: 'Switzer',
    fontWeight: FontWeight.w600,
  );

  /// 14px Switzer w600 — section labels (settings section titles).
  static const TextStyle sectionLabel = TextStyle(
    fontSize: 14,
    fontFamily: 'Switzer',
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  // ── Body text ─────────────────────────────────────────────────────
  /// 23px VarelaRound — subtitle / greeting subtitle.
  static const TextStyle subtitle = TextStyle(
    fontSize: 23,
    fontFamily: 'VarelaRound',
  );

  /// 20px VarelaRound — household name under Members title.
  static const TextStyle subtitleLarge = TextStyle(
    fontSize: 20,
    fontFamily: 'VarelaRound',
  );

  /// 16px VarelaRound — body large, empty-state descriptions.
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontFamily: 'VarelaRound',
  );

  /// 14px VarelaRound — body default, descriptions, tab buttons.
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontFamily: 'VarelaRound',
  );

  /// 12px VarelaRound — metadata, priority labels, badges, captions.
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontFamily: 'VarelaRound',
  );

  /// 10px — tiny labels (connected/not connected badges).
  static const TextStyle bodyTiny = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.bold,
  );

  // ── Special purpose ───────────────────────────────────────────────
  /// 14px VarelaRound w600 — button labels.
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontFamily: 'VarelaRound',
    fontWeight: FontWeight.w600,
  );

  /// 16px VarelaRound w600 — large button labels (e.g. Logout).
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 16,
    fontFamily: 'VarelaRound',
    fontWeight: FontWeight.w600,
  );

  /// 16px Switzer w600 — logout / large CTA buttons with Switzer.
  static const TextStyle buttonSwitzer = TextStyle(
    fontSize: 16,
    fontFamily: 'Switzer',
    fontWeight: FontWeight.w600,
  );

  /// 8px bold — notification badge count.
  static const TextStyle badge = TextStyle(
    fontSize: 8,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
}
