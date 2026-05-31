import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:enbridge/features/auth/auth_provider.dart';
import 'package:enbridge/screens/splash_screen.dart';
import 'package:enbridge/screens/onboarding_screen.dart';
import 'package:enbridge/screens/login_screen.dart';
import 'package:enbridge/screens/register_screen.dart';
import 'package:enbridge/screens/reset_password_screen.dart';
import 'package:enbridge/screens/dashboard_screen.dart';
import 'package:enbridge/screens/tasks_screen.dart';
import 'package:enbridge/screens/focus_screen.dart';
import 'package:enbridge/screens/habits_screen.dart';
import 'package:enbridge/screens/profile_screen.dart';
import 'package:enbridge/screens/aiva_screen.dart';
import 'package:enbridge/screens/calendar_screen.dart';
import 'package:enbridge/screens/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authStatusAsync = ref.watch(authStatusProvider);
  final authStatus = authStatusAsync.value ?? AuthStatus.loading;

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuth = authStatus == AuthStatus.authenticated;
      final isLoading = authStatus == AuthStatus.loading;
      final isRecovery = authStatus == AuthStatus.passwordRecovery;
      final loc = state.matchedLocation;

      final onAuthPage = loc.startsWith('/login') ||
          loc.startsWith('/register') ||
          loc.startsWith('/splash') ||
          loc.startsWith('/onboarding') ||
          loc.startsWith('/reset-password');

      if (isLoading) return null;
      if (isRecovery) return '/reset-password';
      if (loc == '/splash') return null;
      if (loc == '/onboarding') return null;
      if (loc == '/reset-password') return null;

      if (!isAuth && !onAuthPage) return '/login';
      if (isAuth && onAuthPage && loc != '/reset-password') return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => SplashScreen(
          onComplete: () => context.go('/onboarding'),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => OnboardingScreen(
          onComplete: () => context.go('/login'),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) {
          final cat = state.extra is String ? state.extra as String : 'Personal';
          return RegisterScreen(category: cat);
        },
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/tasks',
            builder: (context, state) => const TasksScreen(),
          ),
          // ── NEW: AIVA AI tab ──────────────────────────────────────────
          GoRoute(
            path: '/aiva',
            builder: (context, state) => const AIVAScreen(),
          ),
          // ── NEW: Calendar tab ─────────────────────────────────────────
          GoRoute(
            path: '/calendar',
            builder: (context, state) => const CalendarScreen(),
          ),
          GoRoute(
            path: '/focus',
            builder: (context, state) => const FocusScreen(),
          ),
          GoRoute(
            path: '/habits',
            builder: (context, state) => const HabitsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
});
