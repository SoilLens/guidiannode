import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radii.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/status_widgets.dart';
import 'permissions_education_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  final _slides = const [
    _OnboardingSlide(
      title: 'Send help requests in seconds',
      message:
          'Your emergency action stays visible, direct, and usable even under stress.',
      icon: Icons.sos_rounded,
      tone: StatusTone.error,
    ),
    _OnboardingSlide(
      title: 'Share live location only when it matters',
      message:
          'GuardianNode uses your location to notify nearby people and guide responders faster.',
      icon: Icons.location_searching_rounded,
      tone: StatusTone.info,
    ),
    _OnboardingSlide(
      title: 'Build trust through community response',
      message:
          'Nearby residents can follow active alerts, see route guidance, and move toward safer outcomes.',
      icon: Icons.people_alt_outlined,
      tone: StatusTone.success,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continue() {
    if (_currentPage == _slides.length - 1) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => const PermissionsEducationScreen(),
        ),
      );
      return;
    }

    _controller.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentPage];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const StatusBadge(
                    label: 'Bamenda emergency network',
                    tone: StatusTone.info,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (_) => const PermissionsEducationScreen(),
                        ),
                      );
                    },
                    child: const Text('Skip'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemBuilder: (context, index) {
                    final page = _slides[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: AppColors.emergencyGradient,
                              ),
                              borderRadius: AppRadii.card,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: AppColors.cleanWhite.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: AppRadii.card,
                                  ),
                                  child: Icon(
                                    page.icon,
                                    size: 34,
                                    color: AppColors.cleanWhite,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  page.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayMedium
                                      ?.copyWith(color: AppColors.cleanWhite),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  page.message,
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
                                        color: AppColors.cleanWhite.withValues(
                                          alpha: 0.92,
                                        ),
                                        height: 1.45,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 26 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? slide.color
                          : AppColors.disabled,
                      borderRadius: AppRadii.pill,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              PrimaryButton(
                text: _currentPage == _slides.length - 1
                    ? 'Continue to permissions'
                    : 'Continue',
                onPressed: _continue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.title,
    required this.message,
    required this.icon,
    required this.tone,
  });

  final String title;
  final String message;
  final IconData icon;
  final StatusTone tone;

  Color get color => switch (tone) {
    StatusTone.success => AppColors.safetyGreen,
    StatusTone.warning => AppColors.communityYellow,
    StatusTone.error => AppColors.error,
    StatusTone.info => AppColors.trustBlue,
    StatusTone.action => AppColors.engagementOrange,
  };
}
