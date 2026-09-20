import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/auth/auth_provider.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/onboarding_screen.dart';
import 'features/auth/otp_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/auth/splash_screen.dart';
import 'features/applications/applications_screen.dart';
import 'features/cms/cms_page_screen.dart';
import 'features/cms/contact_screen.dart';
import 'features/employer/employer_jobs_screen.dart';
import 'features/employer/employer_my_jobs_screen.dart';
import 'features/home/home_screen.dart';
import 'features/jobs/job_alerts_screen.dart';
import 'features/jobs/job_detail_screen.dart';
import 'features/jobs/job_list_screen.dart';
import 'features/jobs/saved_jobs_screen.dart';
import 'features/notifications/notifications_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/profile/resume_screen.dart';
import 'features/settings/settings_screen.dart';
import 'shared/widgets/main_shell.dart';

// One key per tab branch + the root navigator
final _rootKey     = GlobalKey<NavigatorState>();
final _homeKey     = GlobalKey<NavigatorState>();
final _jobsKey     = GlobalKey<NavigatorState>();
final _appsKey     = GlobalKey<NavigatorState>();
final _profileKey  = GlobalKey<NavigatorState>();
final _settingsKey = GlobalKey<NavigatorState>();

// Notifies GoRouter to re-run redirect whenever auth state changes,
// without recreating the GoRouter instance itself.
class _AuthRefreshNotifier extends ChangeNotifier {
  _AuthRefreshNotifier(Ref ref) {
    ref.listen<AsyncValue<AuthState>>(authProvider, (_, __) {
      notifyListeners();
    });
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthRefreshNotifier(ref);

  final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/splash',
    // Re-runs redirect when auth changes — no new GoRouter instance needed.
    refreshListenable: notifier,
    redirect: (context, state) {
      // Always read fresh state inside redirect (not a stale closure value).
      final authAsync = ref.read(authProvider);
      final loc       = state.matchedLocation;

      if (loc == '/splash' || loc == '/onboarding') return null;
      if (authAsync.isLoading) return '/splash';

      final auth     = authAsync.valueOrNull;
      final loggedIn = auth?.isAuthenticated ?? false;
      final onAuth   = loc == '/login'         ||
                       loc == '/register'      ||
                       loc == '/forgot-password' ||
                       loc == '/verify-otp';

      if (!loggedIn && !onAuth) return '/login';
      if (loggedIn && onAuth) {
        return auth!.role == AuthRole.employer ? '/employer' : '/home';
      }
      return null;
    },
    routes: [
      // ── Full-screen routes (no shell, no bottom nav) ──────────────────────
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/verify-otp',
        builder: (_, state) => OtpScreen(email: state.extra as String? ?? ''),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/employer',
        builder: (_, __) => const EmployerJobsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/jobs/:id',
        builder: (_, state) => JobDetailScreen(
          jobId: int.parse(state.pathParameters['id']!),
          isEmployerView: state.uri.queryParameters['employer'] == '1',
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/employer/my-jobs',
        builder: (_, __) => const EmployerMyJobsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/notifications',
        builder: (_, __) => const NotificationsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/saved-jobs',
        builder: (_, __) => const SavedJobsScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/resume',
        builder: (_, state) => ResumeScreen(resumeUrl: state.extra as String?),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/cms/:slug',
        builder: (_, state) =>
            CmsPageScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/contact',
        builder: (_, __) => const ContactScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootKey,
        path: '/job-alerts',
        builder: (_, __) => const JobAlertsScreen(),
      ),

      // ── Shell (persistent bottom nav across 5 tabs) ───────────────────────
      StatefulShellRoute.indexedStack(
        builder: (_, __, shell) => MainShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _homeKey,
            routes: [
              GoRoute(
                path: '/home',
                builder: (_, __) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _jobsKey,
            routes: [
              GoRoute(
                path: '/jobs',
                builder: (_, state) => JobListScreen(
                  initialCategory: state.uri.queryParameters['category'],
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _appsKey,
            routes: [
              GoRoute(
                path: '/applications',
                builder: (_, __) => const ApplicationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _profileKey,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, __) => const ProfileScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _settingsKey,
            routes: [
              GoRoute(
                path: '/settings',
                builder: (_, __) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri}')),
    ),
  );

  ref.onDispose(notifier.dispose);
  return router;
});
