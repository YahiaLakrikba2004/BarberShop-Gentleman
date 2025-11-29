import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'features/splash/splash_screen.dart';
import 'services/auth_service.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/notification_service.dart';
import 'services/seed_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: kIsWeb ? "assets/.env" : ".env");
  } catch (e) {
    debugPrint("Error loading .env file: $e");
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(
        NotificationService.firebaseMessagingBackgroundHandler);

    await initializeDateFormatting('it_IT', null);

    runApp(
      ProviderScope(
        child: const BarberShopApp(),
      ),
    );
  } catch (e, stackTrace) {
    debugPrint("Firebase Initialization Error: $e");
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  const Text("Errore di Inizializzazione",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(e.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  Text(stackTrace.toString(),
                      style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BarberShopApp extends ConsumerStatefulWidget {
  const BarberShopApp({super.key});

  @override
  ConsumerState<BarberShopApp> createState() => _BarberShopAppState();
}

class _BarberShopAppState extends ConsumerState<BarberShopApp> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Initialize notifications
    ref.read(notificationServiceProvider).initialize();
    // Fix barber schedules (Temporary fix)
    ref.read(seedServiceProvider).fixBarberSchedules();
  }

  @override
  Widget build(BuildContext context) {
    // Warm up auth state and router
    final authState = ref.watch(authStateProvider);

    // Keep splash screen if manually showing OR if auth is still loading
    if (_showSplash || authState.isLoading) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: SplashScreen(
          onComplete: () {
            setState(() => _showSplash = false);
          },
        ),
      );
    }

    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'The Gentleman Barberstyle',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
