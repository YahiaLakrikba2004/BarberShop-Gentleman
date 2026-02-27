import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/initialization.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'features/splash/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('it_IT', null);
  
  // Register background handler early
  FirebaseMessaging.onBackgroundMessage(
      NotificationService.firebaseMessagingBackgroundHandler);

  runApp(
    const ProviderScope(
      child: BarberShopApp(),
    ),
  );
}

class BarberShopApp extends ConsumerStatefulWidget {
  const BarberShopApp({super.key});

  @override
  ConsumerState<BarberShopApp> createState() => _BarberShopAppState();
}

class _BarberShopAppState extends ConsumerState<BarberShopApp> {
  bool _isSplashVisible = true;
  bool _isSplashAnimationComplete = false;

  @override
  void initState() {
    super.initState();
  }

  void _onSplashAnimationComplete() {
    if (mounted) {
      setState(() {
        _isSplashAnimationComplete = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final initializationState = ref.watch(appInitializationProvider);
    final authState = ref.watch(authStateProvider);
    final userProfileState = ref.watch(currentUserProfileProvider);
    final router = ref.watch(routerProvider);

    // Initialize notifications when app is ready
    ref.listen(appInitializationProvider, (previous, next) {
      if (next.hasValue) {
        ref.read(notificationServiceProvider).initialize();
      }
    });

    // Re-Initialize/Update Token on Auth Change (Login/Logout)
    ref.listen(authStateProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
         // User logged in: Ensure token is uploaded
         ref.read(notificationServiceProvider).initialize();
      }
    });

    // Handle notification navigation (Background/Terminated Open)
    ref.listen(notificationOpenProvider, (previous, next) {
      next.whenData((path) {
        if (path != null) {
          router.go(path);
        }
      });
    });

    // Check if critical data is ready
    final isInitialized = initializationState.hasValue;
    final isAuthReady = !authState.isLoading;
    final isProfileReady = !userProfileState.isLoading;
    
    // We are ready to remove splash when:
    // 1. App initialization is done
    // 2. Auth check is done
    // 3. Profile is loaded (if logged in)
    // 4. Splash animation reported completion
    final isAppReady = isInitialized && isAuthReady && isProfileReady;
    final shouldDismissSplash = isAppReady && _isSplashAnimationComplete;

    // Handle Initialization Error
    if (initializationState.hasError) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    "Errore di Inizializzazione",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    initializationState.error.toString(),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return MaterialApp.router(
      title: 'Gentlemen',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('it', 'IT'),
        Locale('en', 'US'),
      ],
      locale: const Locale('it', 'IT'),
      builder: (context, child) {
        return Stack(
          children: [
            // The actual app content
            if (child != null) child,

            // Splash Screen Overlay
            // We keep it in the tree until it's fully faded out or dismissed
            if (_isSplashVisible)
              AnimatedOpacity(
                opacity: shouldDismissSplash ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeInOut,
                onEnd: () {
                  if (shouldDismissSplash) {
                    setState(() {
                      _isSplashVisible = false;
                    });
                  }
                },
                child: IgnorePointer(
                  ignoring: shouldDismissSplash, // Allow touches to pass through when fading
                  child: SplashScreen(
                    onComplete: _onSplashAnimationComplete,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
