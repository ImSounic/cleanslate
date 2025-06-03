// lib/main.dart
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cleanslate/data/services/supabase_service.dart';
import 'package:cleanslate/data/services/household_service.dart';
import 'package:cleanslate/data/services/notification_service.dart';
import 'package:cleanslate/features/auth/screens/landing_screen.dart';
import 'package:cleanslate/features/auth/screens/login_screen.dart';
import 'package:cleanslate/features/auth/screens/signup_screen.dart';
import 'package:cleanslate/features/auth/screens/forgot_password_screen.dart';
import 'package:cleanslate/features/home/screens/home_screen.dart';
import 'package:cleanslate/core/theme/app_theme.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:cleanslate/core/providers/theme_provider.dart';
import 'package:flutter/foundation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar to be transparent
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  // Get configuration
  late final String supabaseUrl;
  late final String supabaseAnonKey;

  if (kDebugMode) {
    // Try to load from .env first in debug mode
    try {
      await dotenv.load();
      supabaseUrl =
          dotenv.env['SUPABASE_URL'] ??
          const String.fromEnvironment('SUPABASE_URL');
      supabaseAnonKey =
          dotenv.env['SUPABASE_ANON_KEY'] ??
          const String.fromEnvironment('SUPABASE_ANON_KEY');

      print(
        'Debug mode: Loaded Supabase URL: ${supabaseUrl.substring(0, 20)}...',
      );
    } catch (e) {
      print('Warning: Could not load .env file, using dart-define values');
      // Fallback to dart-define values
      supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
      supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');
    }
  } else {
    // In release mode, only use dart-define values
    supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
    supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');
  }

  // Validate configuration
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw Exception(
      'Supabase configuration missing! '
      'Please provide SUPABASE_URL and SUPABASE_ANON_KEY via --dart-define',
    );
  }

  // Initialize Supabase
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        // Add NotificationService as a provider at the app level
        ChangeNotifierProvider(
          create: (context) => NotificationService(),
          lazy: false, // Create immediately
        ),
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

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final SupabaseService _supabaseService = SupabaseService();
  final HouseholdService _householdService = HouseholdService();
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle changes if needed
    if (state == AppLifecycleState.resumed) {
      // App came to foreground
      if (_isLoggedIn) {
        // Refresh notifications when app resumes
        final notificationService = context.read<NotificationService>();
        notificationService.loadNotifications();
      }
    }
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

        // Initialize notification service for logged in user
        if (mounted) {
          final notificationService = context.read<NotificationService>();
          await notificationService.initialize();
        }
      } catch (e) {
        print('Error initializing app: $e');
        // Continue even if initialization fails
        // The user will see appropriate UI options in the screens
      }
    }

    setState(() {
      _isLoggedIn = isLoggedIn;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // Apply system UI overlay based on current theme
        if (themeProvider.isDarkMode) {
          SystemChrome.setSystemUIOverlayStyle(
            const SystemUiOverlayStyle(
              statusBarBrightness: Brightness.dark, // iOS
              statusBarIconBrightness: Brightness.light, // Android
            ),
          );
        } else {
          SystemChrome.setSystemUIOverlayStyle(
            const SystemUiOverlayStyle(
              statusBarBrightness: Brightness.light, // iOS
              statusBarIconBrightness: Brightness.dark, // Android
            ),
          );
        }

        return MaterialApp(
          title: 'CleanSlate',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          debugShowCheckedModeBanner: false, // Remove debug banner
          home:
              _isLoading
                  ? Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                  : _isLoggedIn
                  ? const HomeScreen()
                  : const LandingScreen(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignupScreen(),
            '/forgot-password': (context) => const ForgotPasswordScreen(),
            '/home': (context) => const HomeScreen(),
          },
        );
      },
    );
  }
}
