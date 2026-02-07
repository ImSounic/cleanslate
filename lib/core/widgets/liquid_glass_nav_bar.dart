// lib/core/widgets/liquid_glass_nav_bar.dart
// Flutter wrapper for iOS 26 Liquid Glass navigation bar

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  MethodChannel? _channel;
  bool _platformViewCreated = false;
  
  /// Check if device supports Liquid Glass (iOS 26+)
  static bool get supportsLiquidGlass {
    if (!Platform.isIOS) return false;
    // For now, we'll use the platform view on all iOS
    // The native code handles version checking internally
    return true;
  }

  @override
  void didUpdateWidget(LiquidGlassNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update native view when selection changes
    if (_platformViewCreated && widget.selectedIndex != oldWidget.selectedIndex) {
      _channel?.invokeMethod('selectTab', {'index': widget.selectedIndex});
    }
    
    // Update badges if changed
    for (int i = 0; i < widget.items.length; i++) {
      if (i < oldWidget.items.length && 
          widget.items[i].badge != oldWidget.items[i].badge) {
        _channel?.invokeMethod('updateBadge', {
          'index': i,
          'count': widget.items[i].badge,
        });
      }
    }
  }

  void _onPlatformViewCreated(int viewId) {
    _channel = MethodChannel('com.cleanslate/liquid_glass_tab_bar_$viewId');
    _channel!.setMethodCallHandler(_handleMethodCall);
    _platformViewCreated = true;
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onTabSelected':
        final args = call.arguments as Map<dynamic, dynamic>;
        final index = args['index'] as int;
        widget.onItemSelected(index);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use native platform view on iOS, Flutter widget on Android
    if (Platform.isIOS && supportsLiquidGlass) {
      return SizedBox(
        height: 80,
        child: UiKitView(
          viewType: 'com.cleanslate/liquid_glass_tab_bar',
          creationParams: {
            'tabs': widget.items.map((e) => e.toMap()).toList(),
            'selectedIndex': widget.selectedIndex,
          },
          creationParamsCodec: const StandardMessageCodec(),
          onPlatformViewCreated: _onPlatformViewCreated,
        ),
      );
    } else {
      // Fallback Flutter implementation
      return _FlutterNavBar(
        items: widget.items,
        selectedIndex: widget.selectedIndex,
        onItemSelected: widget.onItemSelected,
        selectedColor: widget.selectedColor,
        unselectedColor: widget.unselectedColor,
      );
    }
  }
}

/// Flutter fallback navigation bar (for Android and older iOS)
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

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surfaceDark.withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isSelected = index == selectedIndex;

            return Expanded(
              child: InkWell(
                onTap: () => onItemSelected(index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(
                            item.flutterIcon,
                            size: 24,
                            color: isSelected
                                ? effectiveSelectedColor
                                : effectiveUnselectedColor,
                          ),
                          if (item.badge > 0)
                            Positioned(
                              right: -8,
                              top: -4,
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
    );
  }
}
