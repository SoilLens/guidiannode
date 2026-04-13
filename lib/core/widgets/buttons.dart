import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/colors.dart';
import '../theme/motion.dart';
import '../theme/radii.dart';
import '../theme/spacing.dart';

enum AppButtonTone { primary, secondary, outline, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.tone = AppButtonTone.primary,
    this.expand = true,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonTone tone;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: AppSpacing.xs),
              ],
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          );

    final button = switch (tone) {
      AppButtonTone.primary => ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: child,
      ),
      AppButtonTone.secondary => FilledButton.tonal(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          foregroundColor: AppColors.trustBlueDark,
          backgroundColor: AppColors.trustBlueSurface,
          minimumSize: const Size(double.infinity, 56),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.button),
          textStyle: Theme.of(context).textTheme.titleSmall,
        ),
        child: child,
      ),
      AppButtonTone.outline => OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        child: child,
      ),
      AppButtonTone.danger => ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: AppColors.cleanWhite,
        ),
        child: child,
      ),
    };

    if (!expand) {
      return button;
    }

    return SizedBox(width: double.infinity, child: button);
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: text,
      icon: icon,
      onPressed: onPressed,
      isLoading: isLoading,
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
  });

  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: text,
      icon: icon,
      onPressed: onPressed,
      tone: AppButtonTone.secondary,
    );
  }
}

class OutlineActionButton extends StatelessWidget {
  const OutlineActionButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
  });

  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: text,
      icon: icon,
      onPressed: onPressed,
      tone: AppButtonTone.outline,
    );
  }
}

class DangerButton extends StatelessWidget {
  const DangerButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return AppButton(
      label: text,
      icon: icon,
      onPressed: onPressed,
      isLoading: isLoading,
      tone: AppButtonTone.danger,
    );
  }
}

class CommunityActionButton extends StatelessWidget {
  const CommunityActionButton({
    super.key,
    required this.onPressed,
    this.label = 'I Am Coming',
  });

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Notify the victim that you are responding',
      child: AppButton(
        label: label,
        icon: Icons.route_rounded,
        onPressed: onPressed,
        tone: AppButtonTone.secondary,
      ),
    );
  }
}

class SosButton extends StatefulWidget {
  const SosButton({
    super.key,
    required this.onPressed,
    this.isSafeState = false,
    this.isBusy = false,
    this.label,
    this.subtitle,
  });

  final VoidCallback onPressed;
  final bool isSafeState;
  final bool isBusy;
  final String? label;
  final String? subtitle;

  @override
  State<SosButton> createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
      lowerBound: 0.95,
      upperBound: 1.02,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSafe = widget.isSafeState;
    final accentColor = isSafe ? AppColors.safetyGreen : AppColors.error;
    final ringColor = accentColor.withValues(alpha: 0.16);
    final label = widget.label ?? (isSafe ? 'Protected' : 'SOS');
    final subtitle =
        widget.subtitle ??
        (isSafe ? 'Location sharing is active' : 'Send emergency alert now');

    return Semantics(
      button: true,
      label: isSafe
          ? 'Emergency safeguards are active'
          : 'Send SOS emergency alert',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = widget.isBusy ? 1.0 : _controller.value;
          return Transform.scale(
            scale: scale,
            child: GestureDetector(
              onTap: widget.isBusy
                  ? null
                  : () {
                      HapticFeedback.heavyImpact();
                      widget.onPressed();
                    },
              child: SizedBox(
                width: 252,
                height: 252,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _PulseRing(size: 252, color: ringColor),
                    _PulseRing(
                      size: 214,
                      color: ringColor.withValues(alpha: 0.26),
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            accentColor.withValues(alpha: 0.94),
                            accentColor,
                          ],
                        ),
                        border: Border.all(
                          color: AppColors.cleanWhite.withValues(alpha: 0.28),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withValues(alpha: 0.28),
                            blurRadius: 28,
                            spreadRadius: 6,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: SizedBox(
                        width: 176,
                        height: 176,
                        child: Center(
                          child: widget.isBusy
                              ? const CircularProgressIndicator(
                                  color: AppColors.cleanWhite,
                                  strokeWidth: 3,
                                )
                              : Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      label.toUpperCase(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .displayLarge
                                          ?.copyWith(
                                            color: AppColors.cleanWhite,
                                            fontSize: 40,
                                          ),
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                      ),
                                      child: Text(
                                        subtitle,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.cleanWhite
                                                  .withValues(alpha: 0.92),
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PulseRing extends StatelessWidget {
  const _PulseRing({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: math.max(1, size * 0.015)),
      ),
      child: SizedBox.square(dimension: size),
    );
  }
}
