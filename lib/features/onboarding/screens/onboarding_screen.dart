import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:is_he_dead/core/providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  Future<void> _onIntroEnd(BuildContext context, WidgetRef ref) async {
    // specific to Onboarding
    await ref.read(onboardingServiceProvider).completeOnboarding();

    if (context.mounted) {
      // The router redirect should handle this automatically now that provider state changed
      // But explicit navigation is safe too
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const bodyStyle = TextStyle(fontSize: 16.0, color: Colors.grey);
    const titleStyle = TextStyle(
      fontSize: 28.0,
      fontWeight: FontWeight.bold,
      color: Colors.black87,
    );

    final pageDecoration = PageDecoration(
      titleTextStyle: titleStyle,
      bodyTextStyle: bodyStyle,
      bodyPadding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      pageColor: Colors.white,
      imagePadding: const EdgeInsets.only(top: 40),
      imageFlex: 2,
    );

    return Scaffold(
      body: IntroductionScreen(
        globalBackgroundColor: Colors.white,
        allowImplicitScrolling: true,
        autoScrollDuration: 3000,
        pages: [
          PageViewModel(
            title: "Automated Wellness Checks",
            body:
                "We check in on you daily so you don't have to worry. Confirm you are okay with a single tap.",
            image: _buildImage('onboarding_1.png'),
            decoration: pageDecoration,
          ),
          PageViewModel(
            title: "Tiered Alerts",
            body:
                "If you don't respond, we intelligently notify your trusted contacts via Email, SMS, or Voice Call.",
            image: _buildImage('onboarding_2.png'),
            decoration: pageDecoration,
          ),
          PageViewModel(
            title: "Peace of Mind",
            body:
                "Securely store your Will, Travel Plans, and Medical Info. Accessible only when it matters most.",
            image: _buildImage('onboarding_3.png', isBackupIcon: true),
            decoration: pageDecoration,
          ),
        ],
        onDone: () => _onIntroEnd(context, ref),
        onSkip: () => _onIntroEnd(context, ref),
        showSkipButton: true,
        skipOrBackFlex: 0,
        nextFlex: 0,
        showBackButton: false,
        back: const Icon(Icons.arrow_back),

        // Premium Controls
        skip: const Text(
          'Skip',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.deepPurple,
          ),
        ),

        next: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.deepPurple.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_forward_rounded,
            color: Colors.deepPurple,
          ),
        ),

        done: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.deepPurple,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurple.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Text(
            'Get Started',
            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ),

        curve: Curves.fastLinearToSlowEaseIn,
        controlsMargin: const EdgeInsets.all(16),
        controlsPadding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
        dotsDecorator: DotsDecorator(
          size: const Size(10.0, 10.0),
          color: Colors.grey[300]!,
          activeColor: Colors.deepPurple,
          activeSize: const Size(22.0, 10.0),
          activeShape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(25.0)),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(
    String assetName, {
    bool isBackupIcon = false,
    double width = 300,
  }) {
    if (isBackupIcon) {
      return const Icon(
        Icons.security_rounded,
        size: 120,
        color: Colors.deepPurple,
      );
    }
    // Return asset or placeholder if missing
    return Image.asset(
      'assets/images/$assetName',
      width: width,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(
          Icons.image_not_supported,
          size: 80,
          color: Colors.grey,
        );
      },
    );
  }
}
