import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:is_he_dead/core/providers/onboarding_provider.dart';
// import 'package:is_he_dead/core/theme/vault_styles.dart'; // Keeping for primary color logic if needed, but unused now.

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingContent> _contents = [
    OnboardingContent(
      title: "Secure Your\nLegacy",
      description:
          "Ensuring your digital life, passwords, and messages reach the right people—on your terms.",
      icon: Icons.shield_moon_outlined,
    ),
    OnboardingContent(
      title: "Automated\nProtection",
      description:
          "We check in on you. A simple tap confirms you're okay. Silence triggers your safety protocol.",
      icon: Icons.timer_outlined,
    ),
    OnboardingContent(
      title: "Emergency\nProtocol",
      description:
          "If you don't respond, we automatically notify your trusted contacts and release your vault.",
      icon: Icons.notification_important_outlined,
    ),
    OnboardingContent(
      title: "The Secure\nVault",
      description:
          "Military-grade encryption for your Will, travel plans, and critical medical info.",
      icon: Icons.lock_outline_rounded,
    ),
  ];

  Future<void> _completeOnboarding() async {
    await ref.read(onboardingServiceProvider).completeOnboarding();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.primaryColor;
    final backgroundColor = isDark ? const Color(0xFF0A0A0A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar (Skip)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TextButton(
                  onPressed: _completeOnboarding,
                  child: Text(
                    "Skip",
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Main Content Area
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _contents.length,
                itemBuilder: (context, index) {
                  final content = _contents[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white10
                                : primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            content.icon,
                            size: 64,
                            color: isDark ? Colors.white : primaryColor,
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Title
                        Text(
                          content.title,
                          style: TextStyle(
                            fontSize: 40,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1.0,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Description
                        Text(
                          content.description,
                          style: TextStyle(
                            fontSize: 18,
                            height: 1.5,
                            color: subTextColor,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Controls
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  // Page Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: List.generate(
                      _contents.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 8),
                        height: 6,
                        width: _currentPage == index ? 32 : 6,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? primaryColor
                              : (isDark ? Colors.white24 : Colors.black12),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Big Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage == _contents.length - 1) {
                          _completeOnboarding();
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.fastOutSlowIn,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _currentPage == _contents.length - 1
                            ? "Get Started"
                            : "Continue",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingContent {
  final String title;
  final String description;
  final IconData icon;

  OnboardingContent({
    required this.title,
    required this.description,
    required this.icon,
  });
}
