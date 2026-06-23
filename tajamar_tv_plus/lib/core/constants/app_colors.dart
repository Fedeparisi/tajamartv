import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Background and Panels
  static const Color background = Color(0xFF050505);
  static const Color panel = Color(0xFF111827);
  
  // Primary and Secondary (TAJAMAR brand)
  static const Color primary = Color(0xFF2563EB);
  static const Color secondary = Color(0xFF60A5FA);
  
  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CA3AF);
  
  // Status Colors
  static const Color online = Color(0xFF10B981);
  static const Color unstable = Color(0xFFF59E0B);
  static const Color offline = Color(0xFFEF4444);
  
  // Gradients
  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primary,
      secondary,
    ],
  );
  
  // Glassmorphism overlays
  static const Color glassOverlay = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
}
