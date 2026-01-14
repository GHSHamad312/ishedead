import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provides the boolean state of whether onboarding has been seen.
// Initialized in main.dart via overrides.
final onboardingProvider = StateProvider<bool>((ref) => false);

// Service to update the state
final onboardingServiceProvider = Provider((ref) => OnboardingService(ref));

class OnboardingService {
  final Ref _ref;
  OnboardingService(this._ref);

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seen_onboarding', true);
    _ref.read(onboardingProvider.notifier).state = true;
  }
}
