// lib/main.dart
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cleanslate/data/services/supabase_service.dart';
import 'package:cleanslate/data/services/household_service.dart';
import 'package:cleanslate/features/auth/screens/landing_screen.dart';
import 'package:cleanslate/features/auth/screens/login_screen.dart';
import 'package:cleanslate/features/main_navigation_screen.dart';
import 'package:cleanslate/core/theme/app_theme.dart';
import 'package:cleanslate/core/providers/theme_provider.dart';
import 'package:cleanslate/core/providers/navigation_provider.dart';
import 'package:cleanslate/core/constants/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load();

  // Initialize Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => NavigationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final SupabaseService _supabaseService = SupabaseService();
  final HouseholdService _householdService = HouseholdService();
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    setState(() {
      _isLoading = true;
    });

    final isLoggedIn = _supabaseService.isAuthenticated;

    if (isLoggedIn) {
      // Initialize household data if user is logged in
      try {
        await _householdService.initializeHousehold();
      } catch (e) {
        print('Error initializing household: $e');
        // Continue even if household initialization fails
        // The user will see appropriate UI options in the members screen
      }
    }

    setState(() {
      _isLoggedIn = isLoggedIn;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ensure we use Consumer to rebuild everything when theme changes
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'CleanSlate',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home:
              _isLoading
                  ? Center(
                    child: CircularProgressIndicator(
                      color:
                          themeProvider.isDarkMode
                              ? AppColors.primaryDark
                              : AppColors.primary,
                    ),
                  )
                  : _isLoggedIn
                  ? const MainNavigationScreen() // Use the new main navigation screen
                  : const LandingScreen(),
          routes: {'/login': (context) => const LoginScreen()},
        );
      },
    );
  }
}
