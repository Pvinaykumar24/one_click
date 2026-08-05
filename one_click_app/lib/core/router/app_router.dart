import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../screens/main_screen.dart';
import '../../screens/home_dashboard_screen.dart';
import '../../screens/timetable_manager_screen.dart';
import '../../screens/assignment_hub_screen.dart';
import '../../screens/money_manager/money_manager_screen.dart';
import '../../screens/profile_screen.dart';
import '../../screens/login_screen.dart';
import '../../providers/auth_provider.dart';
import '../../screens/attendance_screen.dart';
import '../../screens/gpa_predictor_screen.dart';
import '../../screens/mess_menu_screen.dart';
import '../../screens/academic_calendar_screen.dart';
import '../../services/onboarding_service.dart';
import '../../screens/onboarding/onboarding_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ValueNotifier<void>(null);

  ref.listen(authProvider, (previous, next) {
    notifier.value = null;
  });

  ref.listen(onboardingProvider, (previous, next) {
    notifier.value = null;
  });

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/loading',
    refreshListenable: notifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final onboardingState = ref.read(onboardingProvider);
      final isAuthenticated = authState.maybeWhen(
        data: (user) => user != null,
        orElse: () => false,
      );

      final isLoggingIn = state.matchedLocation == '/login';
      final isOnboarding = state.matchedLocation == '/onboarding';

      final onboardingLoading = onboardingState.isLoading || (onboardingState.valueOrNull?.isLoading ?? false);

      if (authState.isLoading || onboardingLoading) {
        return '/loading';
      }

      final hasCompletedOnboarding = onboardingState.valueOrNull?.hasCompletedOnboarding ?? false;

      if (state.matchedLocation == '/loading' && !(authState.isLoading || onboardingLoading)) {
        return isAuthenticated ? '/dashboard' : '/login';
      }

      if (!isAuthenticated && !isLoggingIn) {
        return '/login';
      }
      
      if (isAuthenticated) {
        if (!hasCompletedOnboarding && !isOnboarding) {
          return '/onboarding';
        }
        if (hasCompletedOnboarding && (isLoggingIn || isOnboarding)) {
          return '/dashboard';
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/loading',
        builder: (context, state) => const Scaffold(
          backgroundColor: Color(0xFF1A1A1A),
          body: Center(
            child: CircularProgressIndicator(color: Colors.white70),
          ),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/attendance',
        builder: (context, state) => const AttendanceScreen(),
      ),
      GoRoute(
        path: '/cgpa',
        builder: (context, state) => const GpaPredictorScreen(),
      ),
      GoRoute(
        path: '/mess',
        builder: (context, state) => const MessMenuScreen(),
      ),
      GoRoute(
        path: '/academic-calendar',
        builder: (context, state) => const AcademicCalendarScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (context, state) => const HomeDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/schedule',
                builder: (context, state) => const TimetableManagerScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/assignments',
                builder: (context, state) => const AssignmentHubScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/finance',
                builder: (context, state) => const MoneyManagerScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  return router;
});
