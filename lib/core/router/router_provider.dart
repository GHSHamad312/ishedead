import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:is_he_dead/features/auth/auth_provider.dart';
import 'package:is_he_dead/features/auth/login_screen.dart';
import 'package:is_he_dead/features/auth/register_screen.dart';
import 'package:is_he_dead/features/auth/complete_profile_screen.dart';
import 'package:is_he_dead/features/onboarding/screens/onboarding_screen.dart';
import 'package:is_he_dead/features/profile/screens/profile_screen.dart';
import 'package:is_he_dead/features/profile/screens/edit_contact_screen.dart';
import 'package:is_he_dead/features/profile/models/emergency_contact.dart';
import 'package:is_he_dead/features/profile/screens/upload_document_screen.dart';
import 'package:is_he_dead/features/profile/services/profile_service.dart';
import 'package:is_he_dead/features/medical/screens/medical_id_screen.dart';
import 'package:is_he_dead/features/home/screens/protocol_status_screen.dart';
import 'package:is_he_dead/features/settings/screens/settings_screen.dart';
import 'package:is_he_dead/core/widgets/scaffold_with_nav_bar.dart';
import 'package:is_he_dead/core/providers/onboarding_provider.dart';
import 'package:is_he_dead/features/home/screens/home_screen.dart';

import 'package:is_he_dead/features/profile/screens/legacy_message_screen.dart';
import 'package:is_he_dead/features/settings/screens/account_settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // We use read() here because we want the GoRouter to persist.
  // We don't want routerProvider to rebuild when the notifier triggers,
  // because that would create a new GoRouter and reset the navigation history.
  // The GoRouter itself will listen to the notifier via refreshListenable.
  final notifier = ref.read(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: notifier, // Listens to ChangeNotifier
    redirect: notifier.redirect, // Delegate logic
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          // Wrap with StatefulNavigationShell adapter if we want to keep using ScaffoldWithNavBar
          // But ScaffoldWithNavBar expects StatefulNavigationShell.
          // We need to modify ScaffoldWithNavBar or wrap 'child' directly.
          // For simplicity, let's assume we update ScaffoldWithNavBar to accept 'child'.
          // Actually, ShellRoute builder gives us a 'child' widget which IS the current route.
          // We need a wrapper that acts like the bottom nav bar.
          // Let's modify ScaffoldWithNavBar to handle ShellRoute.
          return ScaffoldWithNavBar(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (BuildContext context, GoRouterState state) =>
                const HomePage(),
          ),
          GoRoute(
            path: '/profile',
            builder: (BuildContext context, GoRouterState state) =>
                const ProfileScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (BuildContext context, GoRouterState state) =>
                const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/complete-profile',
        builder: (context, state) => const CompleteProfileScreen(),
      ),

      GoRoute(
        path: '/edit-contact',
        builder: (context, state) {
          final contact = state.extra as EmergencyContact?;
          return EditContactScreen(contact: contact);
        },
      ),
      GoRoute(
        path: '/upload-doc',
        builder: (context, state) => const UploadDocumentScreen(),
      ),
      GoRoute(
        path: '/medical-id',
        builder: (context, state) {
          return const MedicalIdScreen();
        },
      ),
      GoRoute(
        path: '/setup-contacts',
        builder: (context, state) => const ProfileScreen(isSetupMode: true),
      ),
      GoRoute(
        path: '/protocol-status',
        builder: (context, state) => const ProtocolStatusScreen(),
      ),
      GoRoute(
        path: '/legacy-message',
        builder: (context, state) => const LegacyMessageScreen(),
      ),
      GoRoute(
        path: '/account-settings',
        builder: (context, state) => const AccountSettingsScreen(),
      ),
    ],
  );
});

final routerNotifierProvider = ChangeNotifierProvider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) => _notify());
    _ref.listen(userProfileProvider, (_, __) => _notify());
    _ref.listen(onboardingProvider, (_, __) => _notify());
  }

  /// Wraps notifyListeners in a microtask to ensure we don't
  /// trigger updates while the provider tree is locked/dirty.
  void _notify() {
    Future.microtask(() => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final path = state.uri.path;
    final isAuthRoute =
        path == '/login' || path == '/register' || path == '/onboarding';

    // Reading providers here is safe because we are outside the build/notify cycle
    // thanks to the microtask delay in _notify.
    final authState = _ref.read(authStateProvider);
    final userProfileState = _ref.read(userProfileProvider);
    final seenOnboarding = _ref.read(onboardingProvider);

    final isAuthenticated = authState.value != null;
    final isLoading = authState.isLoading || userProfileState.isLoading;

    if (isLoading) return null;

    // Fix: Only force onboarding if NOT authenticated.
    // Otherwise, authenticated users with !seenOnboarding get stuck in a loop (/onboarding -> / -> /onboarding)
    if (!isAuthenticated && !seenOnboarding && path != '/onboarding') {
      return '/onboarding';
    }

    if (!isAuthenticated) {
      if (path == '/onboarding' && !seenOnboarding) return null;
      if (isAuthRoute) return null;
      return '/login';
    }

    if (isAuthenticated) {
      final profile = userProfileState.value;
      final isProfileDocsCheckPassed = profile != null;
      final isSetupComplete =
          isProfileDocsCheckPassed && (profile.isSetupComplete);

      if (!isSetupComplete) {
        final setupRoutes = [
          '/complete-profile',
          '/medical-id',
          '/upload-doc',
          '/setup-contacts',
          '/edit-contact',
          '/legacy-message',
        ];

        if (setupRoutes.contains(path)) return null;
        return '/complete-profile';
      }

      if (path == '/complete-profile') {
        return '/';
      }

      if (isAuthRoute) {
        return '/';
      }
    }

    return null;
  }
}
