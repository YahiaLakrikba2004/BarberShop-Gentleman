import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

  return GoRouter(
    initialLocation: '/',
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
        builder: (context, state) => const MainLayout(
          currentIndex: 2, // Profile is now the 3rd tab (index 2) for customers
          child: ProfileScreen(),
        ),
      ),
    ],
  );
});
