// lib/core/widgets/pro_badge.dart

import 'package:flutter/material.dart';

/// A small "PRO" chip with gradient gold styling.
/// Only shown when the user's subscription tier is Pro.
class ProBadge extends StatelessWidget {
  final double fontSize;

  const ProBadge({super.key, this.fontSize = 10});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: fontSize * 0.7,
        vertical: fontSize * 0.25,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB800), Color(0xFFE5A600)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(fontSize * 0.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFB800).withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        'PRO',
        style: TextStyle(
          fontSize: fontSize,
          fontFamily: 'Switzer',
          fontWeight: FontWeight.w800,
          color: Colors.black87,
          letterSpacing: 0.5,
          height: 1.2,
        ),
      ),
    );
  }
}
