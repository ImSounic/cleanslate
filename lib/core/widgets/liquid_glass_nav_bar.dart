// lib/core/widgets/liquid_glass_nav_bar.dart
// Liquid Glass style navigation bar with blur effect

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cleanslate/core/constants/app_colors.dart';

/// Tab item data for the navigation bar
class NavBarItem {
  final String icon;      // SF Symbol name for iOS
  final IconData flutterIcon; // Flutter icon for Android/fallback
  final String label;
  final int badge;

  const NavBarItem({
    required this.icon,
    required this.flutterIcon,
    required this.label,
    this.badge = 0,
  });

  Map<String, dynamic> toMap() => {
    'icon': icon,
    'label': label,
    'badge': badge,
  };
}

/// Liquid Glass Navigation Bar
/// 
/// Uses native SwiftUI with Liquid Glass effect on iOS 26+
/// Falls back to Flutter BottomNavigationBar on Android and older iOS
class LiquidGlassNavBar extends StatefulWidget {
  final List<NavBarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final Color? selectedColor;
  final Color? unselectedColor;

  const LiquidGlassNavBar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
    this.selectedColor,
    this.unselectedColor,
  });

  @override
  State<LiquidGlassNavBar> createState() => _LiquidGlassNavBarState();
}

class _LiquidGlassNavBarState extends State<LiquidGlassNavBar> {
  @override
  Widget build(BuildContext context) {
    // Use Flutter glass effect implementation on all platforms
    // Native SwiftUI platform view can be enabled later by adding Swift files to Xcode
    return _FlutterNavBar(
      items: widget.items,
      selectedIndex: widget.selectedIndex,
      onItemSelected: widget.onItemSelected,
      selectedColor: widget.selectedColor,
      unselectedColor: widget.unselectedColor,
    );
  }
}

/// Flutter glass navigation bar with blur effect
class _FlutterNavBar extends StatelessWidget {
  final List<NavBarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final Color? selectedColor;
  final Color? unselectedColor;

  const _FlutterNavBar({
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
    this.selectedColor,
    this.unselectedColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveSelectedColor = selectedColor ?? AppColors.primary;
    final effectiveUnselectedColor = unselectedColor ?? AppColors.textSecondary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              // Translucent background for glass effect
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isSelected = index == selectedIndex;

                return Expanded(
                  child: InkWell(
                    onTap: () => onItemSelected(index),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? effectiveSelectedColor.withValues(alpha: 0.15)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  item.flutterIcon,
                                  size: 24,
                                  color: isSelected
                                      ? effectiveSelectedColor
                                      : effectiveUnselectedColor,
                                ),
                              ),
                              if (item.badge > 0)
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    constraints: const BoxConstraints(minWidth: 16),
                                    child: Text(
                                      item.badge > 99 ? '99+' : '${item.badge}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected
                                  ? effectiveSelectedColor
                                  : effectiveUnselectedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
