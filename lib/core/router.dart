import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/user_model.dart';
import '../features/auth/auth_screen.dart';
import '../features/home/home_screen.dart';
import '../features/booking/booking_screen.dart';
import '../features/calendar/calendar_screen.dart';
import '../features/admin/admin_dashboard.dart';
import '../features/profile/profile_screen.dart';
import '../services/auth_service.dart';
import 'main_layout.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final userAsync = ref.watch(currentUserProfileProvider);
  final user = userAsync.value;

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    errorBuilder: (context, state) => const Scaffold(
      body: Center(child: Text('Route Error. Please restart.')),
    ),
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isLoggingIn = state.matchedLocation == '/auth';

      if (!isLoggedIn && !isLoggingIn) {
        return '/auth';
      }
      if (isLoggedIn && isLoggingIn) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const MainLayout(
          currentIndex: 0,
          child: HomeScreen(),
        ),
      ),
      GoRoute(
        path: '/booking',
        builder: (context, state) => const MainLayout(
          currentIndex: 1,
          child: BookingScreen(),
        ),
      ),
      GoRoute(
        path: '/calendar',
        builder: (context, state) => const MainLayout(
          currentIndex: 2,
          child: CalendarScreen(),
        ),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const MainLayout(
          currentIndex: 3,
          child: AdminDashboard(),
        ),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) {
          final isClient = user?.role == UserRole.client;
          // Barbers use index 3 for profile. Admins don't have profile tab, 
          // but if they navigate here manually, we can just show it with index 3 (which highlights Admin tab? No, that's weird).
          // Let's just use 3 for non-clients.
          return MainLayout(
            currentIndex: isClient ? 2 : 3,
            child: const ProfileScreen(),
          );
        },
      ),
    ],
  );
});
