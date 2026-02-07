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
import 'package:cleanslate/core/services/deep_link_service.dart';
import 'package:cleanslate/data/repositories/household_repository.dart';

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
  final DeepLinkService _deepLinkService = DeepLinkService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize deep link service
    _initializeDeepLinks();
    
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
  
  /// Initialize deep link handling
  Future<void> _initializeDeepLinks() async {
    try {
      await _deepLinkService.initialize();
      
      // Set up callback for join codes
      _deepLinkService.onJoinCodeReceived = (code) {
        debugLog('🔗 Received join code from deep link: $code');
        _handleJoinCode(code);
      };
      
      // Check for pending code (app was launched via deep link)
      final pendingCode = _deepLinkService.consumePendingJoinCode();
      if (pendingCode != null) {
        // Wait for app to be ready before handling
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _handleJoinCode(pendingCode);
          }
        });
      }
    } catch (e) {
      debugPrint('⚠️ Deep link init error: $e');
    }
  }
  
  /// Handle a join code from deep link
  Future<void> _handleJoinCode(String code) async {
    // Wait until we know if user is logged in
    while (_isLoading && mounted) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    if (!mounted) return;
    
    final context = _navigatorKey.currentContext;
    if (context == null) return;
    
    if (!_isLoggedIn) {
      // User not logged in - show dialog to login first
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Join Household'),
          content: Text(
            'You received an invite to join a household!\n\n'
            'Code: $code\n\n'
            'Please log in first to join.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                // Store the code for after login
                _pendingJoinCodeAfterLogin = code;
                _navigatorKey.currentState?.pushNamed('/login');
              },
              child: const Text('Log In'),
            ),
          ],
        ),
      );
    } else {
      // User is logged in - show join confirmation dialog
      _showJoinConfirmationDialog(context, code);
    }
  }
  
  String? _pendingJoinCodeAfterLogin;
  
  /// Show dialog to confirm joining a household
  Future<void> _showJoinConfirmationDialog(BuildContext context, String code) async {
    final householdRepo = HouseholdRepository();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.home_rounded, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Join Household'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You\'ve been invited to join a household!'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Code: ',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    code,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              
              // Show loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              
              try {
                final household = await householdRepo.joinHouseholdWithCode(code);
                _householdService.setCurrentHousehold(household);
                
                if (mounted) {
                  Navigator.of(context).pop(); // Close loading
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Welcome to ${household.name}!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  
                  // Navigate to home
                  _navigatorKey.currentState?.pushNamedAndRemoveUntil(
                    '/home',
                    (_) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.of(context).pop(); // Close loading
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to join: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _deepLinkService.dispose();
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
            
            // Check for pending join code after login
            if (_pendingJoinCodeAfterLogin != null) {
              final code = _pendingJoinCodeAfterLogin!;
              _pendingJoinCodeAfterLogin = null;
              
              // Wait a bit for navigation to complete
              Future.delayed(const Duration(milliseconds: 500), () {
                final ctx = _navigatorKey.currentContext;
                if (ctx != null && mounted) {
                  _showJoinConfirmationDialog(ctx, code);
                }
              });
            }
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
