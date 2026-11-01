import 'package:flutter/material.dart';

/// Design tokens and color constants for Wey Birre following Stitch UI specifications.
class AppColors {
  AppColors._();

  // Primary palette (Highland Teal)
  static const Color primary = Color(0xFF005C55);
  static const Color primaryContainer = Color(0xFF0F766E);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFA3FAEF);
  static const Color primaryFixed = Color(0xFF9CF2E8);
  static const Color onPrimaryFixed = Color(0xFF00201D);
  static const Color primaryFixedDim = Color(0xFF80D5CB);

  // Secondary palette (Emerald / Mint)
  static const Color secondary = Color(0xFF006C49);
  static const Color secondaryContainer = Color(0xFF6CF8BB);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF00714D);
  static const Color secondaryFixed = Color(0xFF6FFBBE);
  static const Color secondaryFixedDim = Color(0xFF4EDEA3);
  static const Color onSecondaryFixed = Color(0xFF002113);

  // Tertiary palette (Warm Amber / Gold)
  static const Color tertiary = Color(0xFF734700);
  static const Color tertiaryContainer = Color(0xFF945D00);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryFixed = Color(0xFFFFDDB8);
  static const Color tertiaryFixedDim = Color(0xFFFFB95F);
  static const Color onTertiaryFixed = Color(0xFF2A1700);

  // Semantic
  static const Color deposit = Color(0xFF16A34A);
  static const Color withdrawal = Color(0xFFBA1A1A);
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  // Neutrals & Surfaces (Light)
  static const Color background = Color(0xFFFAF8FF);
  static const Color surface = Color(0xFFFAF8FF);
  static const Color surfaceDim = Color(0xFFD2D9F4);
  static const Color surfaceBright = Color(0xFFFAF8FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF2F3FF);
  static const Color surfaceContainer = Color(0xFFEAEDFF);
  static const Color surfaceContainerHigh = Color(0xFFE2E7FF);
  static const Color surfaceContainerHighest = Color(0xFFDAE2FD);

  // Typography & Borders
  static const Color onSurface = Color(0xFF131B2E);
  static const Color onSurfaceVariant = Color(0xFF3E4947);
  static const Color outline = Color(0xFF6E7977);
  static const Color outlineVariant = Color(0xFFBDC9C6);

  // Inverse
  static const Color inverseSurface = Color(0xFF283044);
  static const Color inverseOnSurface = Color(0xFFEEF0FF);
  static const Color inversePrimary = Color(0xFF80D5CB);

  // Ethiopian Bank Institution Tokens
  static const Color cbeText = Color(0xFF6B21A8);
  static const Color cbeBg = Color(0xFFF3E8FF);
  static const Color cbeDot = Color(0xFF8E24AA);

  static const Color telebirrText = Color(0xFF0277BD);
  static const Color telebirrBg = Color(0xFFE0F2FE);
  static const Color telebirrDot = Color(0xFF0288D1);

  static const Color awashText = Color(0xFFE65100);
  static const Color awashBg = Color(0xFFFEF3C7);
  static const Color awashDot = Color(0xFFF57C00);

  static const Color dashenText = Color(0xFF005236);
  static const Color dashenBg = Color(0xFFE2E7FF);
  static const Color dashenDot = Color(0xFF006C49);

  static const Color boaText = Color(0xFF374151);
  static const Color boaBg = Color(0xFFF1F5F9);
  static const Color boaDot = Color(0xFF64748B);

  static const Color cashText = Color(0xFF065F46);
  static const Color cashBg = Color(0xFFECFDF5);
  static const Color cashDot = Color(0xFF10B981);
}
