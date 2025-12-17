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
        pageBuilder: (context, state) => _buildPageWithTransition(
          context: context,
          state: state,
          child: const AuthScreen(),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) {
          final location = state.uri.toString();
          int currentIndex = 0;
          
          if (location == '/' || location == '') {
            currentIndex = 0;
          } else if (location.startsWith('/booking')) {
            currentIndex = 1;
          } else if (location.startsWith('/calendar')) {
            currentIndex = 2;
          } else if (location.startsWith('/profile')) {
             currentIndex = (user?.role == UserRole.client) ? 2 : 3;
          } else if (location.startsWith('/admin')) {
            currentIndex = 3;
          }

          return MainLayout(
            currentIndex: currentIndex,
            child: child,
          );
        },
        routes: [
           GoRoute(
            path: '/',
            pageBuilder: (context, state) => _buildPageWithTransition(
              context: context,
              state: state,
              child: const HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/booking',
            pageBuilder: (context, state) => _buildPageWithTransition(
              context: context,
              state: state,
              child: const BookingScreen(),
            ),
          ),
          GoRoute(
            path: '/calendar',
            pageBuilder: (context, state) => _buildPageWithTransition(
              context: context,
              state: state,
              child: const CalendarScreen(),
            ),
          ),
          GoRoute(
            path: '/admin',
            pageBuilder: (context, state) => _buildPageWithTransition(
              context: context,
              state: state,
              child: const AdminDashboard(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => _buildPageWithTransition(
              context: context,
              state: state,
              child: const ProfileScreen(),
            ),
          ),
        ],
      ),
    ],
  );
});

CustomTransitionPage _buildPageWithTransition({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 400),
  );
}

