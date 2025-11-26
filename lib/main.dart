import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'firebase_options.dart';
import 'features/splash/splash_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }

  // Initialize Italian locale for date formatting
  await initializeDateFormatting('it_IT', null);

  runApp(const ProviderScope(child: BarberShopApp()));
}

class BarberShopApp extends ConsumerStatefulWidget {
  const BarberShopApp({super.key});

  @override
  ConsumerState<BarberShopApp> createState() => _BarberShopAppState();
}

class _BarberShopAppState extends ConsumerState<BarberShopApp> {
  bool _showSplash = true;

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
      title: 'Gentleman Barber Shop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
