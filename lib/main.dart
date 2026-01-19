import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:is_he_dead/core/services/notification_service.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:is_he_dead/core/providers/theme_provider.dart';
import 'package:is_he_dead/core/providers/onboarding_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/router/router_provider.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); //initializing for codes that run before the runapp.
  usePathUrlStrategy();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final container = ProviderContainer();

  // Initialize Services
  container.read(notificationServiceProvider).init();

  // Load Onboarding State
  final prefs = await SharedPreferences.getInstance();
  final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;
  container.read(onboardingProvider.notifier).state = seenOnboarding;

  if (kDebugMode) {
    try {
      // Connect to auth emulator
      await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);

      // Connect to firestore emulator
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8090);

      // Connect to storage emulator
      FirebaseStorage.instance.useStorageEmulator('localhost', 9199);

      // Connect to functions emulator
      FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);

      print('Connected to Firebase Emulators');
    } catch (e) {
      print('Error connecting to emulators: $e');
    }
  }

  runApp(UncontrolledProviderScope(container: container, child: const MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Is He Dead',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
