import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'package:is_he_dead/core/providers/theme_provider.dart';
import 'package:is_he_dead/core/router/router_provider.dart';
import 'package:is_he_dead/core/providers/onboarding_provider.dart';
import 'package:is_he_dead/features/security/screens/biometric_lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool seenOnboarding = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    final prefs = await SharedPreferences.getInstance();
    seenOnboarding = prefs.getBool('seen_onboarding') ?? false;
  } catch (e) {
    debugPrint("Initialization failed: $e");
  }

  runApp(
    ProviderScope(
      overrides: [onboardingProvider.overrideWith((ref) => seenOnboarding)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final router = ref.read(routerProvider);

    return MaterialApp.router(
      title: 'Is He Dead?',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
          surface: Colors.white,
          surfaceContainer: Colors.grey[50],
        ),
        scaffoldBackgroundColor: Colors.grey[50],
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
          surface: const Color(0xFF1E1E1E),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
        ),
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
      ),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        return BiometricLockScreen(child: child!);
      },
    );
  }
}
