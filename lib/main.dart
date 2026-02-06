// lib/main.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cleanslate/data/services/supabase_service.dart';
import 'package:cleanslate/data/services/household_service.dart';
import 'package:cleanslate/data/services/notification_service.dart';
import 'package:cleanslate/features/auth/screens/landing_screen.dart';
import 'package:cleanslate/features/auth/screens/login_screen.dart';
import 'package:cleanslate/features/auth/screens/signup_screen.dart';
import 'package:cleanslate/features/auth/screens/forgot_password_screen.dart';
import 'package:cleanslate/features/app_shell.dart';
import 'package:cleanslate/core/theme/app_theme.dart';
import 'package:cleanslate/core/constants/app_colors.dart';
import 'package:cleanslate/core/providers/theme_provider.dart';
import 'package:cleanslate/core/config/env_config.dart';
import 'package:cleanslate/features/calendar/screens/calendar_connection_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cleanslate/core/utils/debug_logger.dart';
import 'package:cleanslate/features/onboarding/screens/onboarding_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Global initialization error to show in UI if startup fails
String? _initializationError;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    debugPrint('📱 Background message: ${message.messageId}');
  } catch (e) {
    debugPrint('📱 Background handler error: $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar to be transparent (safe, can't fail)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );

  // ================================================================
  // STEP 1: Initialize Firebase (with timeout and error handling)
  // ================================================================
  try {
    await Firebase.initializeApp().timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        debugPrint('⚠️ Firebase init timeout - continuing without Firebase');
        throw TimeoutException('Firebase initialization timeout');
      },
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Crashlytics: catch all uncaught Flutter errors
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    
    // Crashlytics: catch all uncaught async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    
    debugLog('✅ Firebase initialized');
  } catch (e) {
    debugPrint('⚠️ Firebase init failed: $e');
    // Continue without Firebase - app should still work for core features
  }

  // ================================================================
  // STEP 2: Load environment configuration
  // ================================================================
  try {
    await EnvConfig.ensureLoaded();
    if (kDebugMode) {
      EnvConfig.debugPrintConfig();
    }
  } catch (e) {
    debugPrint('⚠️ EnvConfig load error: $e');
    // Continue - EnvConfig has fallbacks
  }

  // ================================================================
  // STEP 3: Validate and initialize Supabase
  // ================================================================
  final supabaseUrl = EnvConfig.supabaseUrl;
  final supabaseAnonKey = EnvConfig.supabaseAnonKey;
  
  if (!EnvConfig.isConfigured) {
    debugPrint('❌ Supabase not configured properly');
    debugPrint('   URL: $supabaseUrl');
    debugPrint('   Key: ${supabaseAnonKey.substring(0, 20.clamp(0, supabaseAnonKey.length))}...');
    _initializationError = 'App not configured. Please contact support.';
    // Still run the app to show error UI
  } else {
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Supabase initialization timeout');
        },
      );
      debugLog('✅ Supabase initialized');
    } catch (e) {
      debugPrint('❌ Supabase init failed: $e');
      _initializationError = 'Could not connect to server. Please check your internet connection.';
    }
  }

  // ================================================================
  // STEP 4: Run the app (always runs, even with errors)
  // ================================================================
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
  late final SupabaseService _supabaseService;
  late final HouseholdService _householdService;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _onboardingComplete = true; // default true to avoid flash
  StreamSubscription<AuthState>? _authSubscription;
  bool _servicesInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Only initialize services if Supabase is available
    if (_initializationError == null) {
      try {
        _supabaseService = SupabaseService();
        _householdService = HouseholdService();
        _servicesInitialized = true;
        _listenToAuthStateChanges();
        _initializeApp();
      } catch (e) {
        debugPrint('❌ Service initialization failed: $e');
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      // Show error state immediately
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Listen for auth state changes (sign-out, token refresh failures)
  /// and redirect to login when the session becomes invalid.
  void _listenToAuthStateChanges() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) {
        final event = data.event;
        debugLog('🔐 Auth state changed: $event');

        if (event == AuthChangeEvent.signedOut ||
            event == AuthChangeEvent.tokenRefreshed && data.session == null) {
          // Session expired or user signed out — redirect to login
          if (mounted) {
            setState(() {
              _isLoggedIn = false;
            });
            _navigatorKey.currentState?.pushNamedAndRemoveUntil(
              '/login',
              (_) => false,
            );
          }
        } else if (event == AuthChangeEvent.signedIn && !_isLoggedIn) {
          // User signed in from another flow
          if (mounted) {
            setState(() {
              _isLoggedIn = true;
            });
          }
        }
      },
    );
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
    if (!_servicesInitialized) {
      setState(() {
        _isLoading = false;
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    // Check onboarding status
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_complete') ?? false;

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
        debugLog('Error initializing app: $e');
        // Continue even if initialization fails
        // The user will see appropriate UI options in the screens
      }
    }

    setState(() {
      _isLoggedIn = isLoggedIn;
      _onboardingComplete = onboardingDone;
      _isLoading = false;
    });
  }

  /// Build the appropriate home screen based on app state
  Widget _buildHomeScreen() {
    // Show loading spinner while initializing
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        ),
      );
    }
    
    // Show error screen if initialization failed
    if (_initializationError != null) {
      return _ErrorScreen(
        message: _initializationError!,
        onRetry: () {
          // Restart the app by popping to root and reinitializing
          setState(() {
            _isLoading = true;
          });
          // Give user feedback then restart
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _initializeApp();
            }
          });
        },
      );
    }
    
    // Normal flow
    if (_isLoggedIn) {
      return const AppShell();
    } else if (!_onboardingComplete) {
      return const OnboardingScreen();
    } else {
      return const LandingScreen();
    }
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
          navigatorKey: _navigatorKey,
          title: 'CleanSlate',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          debugShowCheckedModeBanner: false, // Remove debug banner
          home: _buildHomeScreen(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignupScreen(),
            '/forgot-password': (context) => const ForgotPasswordScreen(),
            '/home': (context) => const AppShell(),
            '/calendar-connection': (context) => const CalendarConnectionScreen(),
          },
        );
      },
    );
  }
}

/// Error screen shown when app initialization fails
class _ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  
  const _ErrorScreen({
    required this.message,
    required this.onRetry,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 24),
              Text(
                'Oops!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
