import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Background and Panels (Dark / Premium)
  static const Color background = Color(0xFF050505);
  static const Color panel = Color(0xFF111827);
  
  // Background and Panels (Light / Tajamar)
  static const Color lightBackground = Color(0xFFF3F4F6);
  static const Color lightPanel = Color(0xFFFFFFFF);
  
  // Background and Panels (Midnight Blue)
  static const Color midnightBackground = Color(0xFF0B0F19);
  static const Color midnightPanel = Color(0xFF1E293B);

  // Primary and Secondary (TAJAMAR brand)
  static const Color primary = Color(0xFF2563EB);
  static const Color secondary = Color(0xFF60A5FA);
  
  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CA3AF);
  
  static const Color textPrimaryLight = Color(0xFF1F2937);
  static const Color textSecondaryLight = Color(0xFF4B5563);
  
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
