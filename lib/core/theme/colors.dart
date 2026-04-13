import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color safetyGreen = Color(0xFF009639);
  static const Color trustBlue = Color(0xFF1D4289);
  static const Color engagementOrange = Color(0xFFDC582A);
  static const Color communityYellow = Color(0xFFFFC845);
  static const Color cleanWhite = Color(0xFFFFFFFF);

  static const Color trustBlueDark = Color(0xFF142D62);
  static const Color trustBlueSurface = Color(0xFFE9EFFB);
  static const Color safetyGreenSurface = Color(0xFFE8F6EE);
  static const Color engagementOrangeSurface = Color(0xFFFDEAE3);
  static const Color communityYellowSurface = Color(0xFFFFF6D8);

  static const Color background = Color(0xFFF3F6FB);
  static const Color backgroundAlt = Color(0xFFE9EEF7);
  static const Color surface = cleanWhite;
  static const Color surfaceMuted = Color(0xFFF8FAFD);
  static const Color surfaceTint = Color(0xFFF0F5FF);

  static const Color textPrimary = Color(0xFF10213F);
  static const Color textSecondary = Color(0xFF52637F);
  static const Color textTertiary = Color(0xFF73829B);
  static const Color textOnDark = cleanWhite;

  static const Color border = Color(0xFFD6DFEA);
  static const Color divider = Color(0xFFE5EBF2);
  static const Color disabled = Color(0xFFB6C2D4);
  static const Color shadow = Color(0xFF10213F);

  static const Color error = Color(0xFFB42318);
  static const Color errorSurface = Color(0xFFFEE4E2);
  static const Color success = safetyGreen;
  static const Color warning = communityYellow;
  static const Color warningSurface = communityYellowSurface;
  static const Color info = trustBlue;
  static const Color infoSurface = trustBlueSurface;

  static const List<Color> emergencyGradient = [
    Color(0xFF19386E),
    Color(0xFF1D4289),
    Color(0xFFDC582A),
  ];
}
