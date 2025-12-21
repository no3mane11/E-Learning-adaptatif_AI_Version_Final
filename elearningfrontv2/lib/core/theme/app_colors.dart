import 'package:flutter/material.dart';

/// Palette de couleurs complète de l'application
class AppColors {
  AppColors._();

  // Gradients
  static final primaryGradient = LinearGradient(
    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final secondaryGradient = LinearGradient(
    colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final successGradient = LinearGradient(
    colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static final warningGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Couleurs solides
  static const primary = Color(0xFF667EEA);
  static const primaryDark = Color(0xFF5568D3);
  static const primaryLight = Color(0xFF8B9AFF);

  static const secondary = Color(0xFFF093FB);
  static const secondaryDark = Color(0xFFE17BF0);
  static const secondaryLight = Color(0xFFFFA5FF);

  static const success = Color(0xFF10B981);
  static const successDark = Color(0xFF059669);
  static const successLight = Color(0xFF34D399);

  static const warning = Color(0xFFF59E0B);
  static const warningDark = Color(0xFFD97706);
  static const warningLight = Color(0xFFFBBF24);

  static const error = Color(0xFFEF4444);
  static const errorDark = Color(0xFFDC2626);
  static const errorLight = Color(0xFFF87171);

  // Background & Surface
  static const background = Color(0xFFF8F9FA);
  static const backgroundDark = Color(0xFF111827);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFF1F2937);
  static const surfaceElevated = Color(0xFFFFFFFF);

  // Text
  static const textPrimary = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary = Color(0xFF9CA3AF);
  static const textInverse = Color(0xFFFFFFFF);

  // Borders & Dividers
  static const border = Color(0xFFE5E7EB);
  static const borderLight = Color(0xFFF3F4F6);
  static const divider = Color(0xFFE5E7EB);

  // Overlay
  static const overlay = Color(0x80000000);
  static const overlayLight = Color(0x40000000);

  // Emotion Colors
  static const emotionHappy = Color(0xFF10B981);
  static const emotionNeutral = Color(0xFF6B7280);
  static const emotionSad = Color(0xFF3B82F6);
  static const emotionAngry = Color(0xFFEF4444);
  static const emotionSurprised = Color(0xFFF59E0B);
}



