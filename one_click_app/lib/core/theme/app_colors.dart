import 'package:flutter/material.dart';

class AppColors {
  // Bright Electric Sun Yellow Neo-Brutalism Grid Canvas base
  static const Color background   = Color(0xFFFFF8E1); // Bright Electric Yellow Tint
  static const Color darkBackground = Color(0xFF12141C); // Deep Electric Obsidian
  static const Color surface      = Color(0xFFFFFFFF); 
  static const Color darkSurface  = Color(0xFF1E2433); 
  static const Color surfaceLight = Color(0xFFFFFDE7); 

  // Neo-Brutalism Electric Palette
  static const Color neoYellow  = Color(0xFFFFE600); // Electric Sun Yellow
  static const Color neoPink    = Color(0xFFFF2A85); // Hot Pink
  static const Color neoCyan    = Color(0xFF00E5FF); // Electric Cyan
  static const Color neoLime    = Color(0xFF00E676); // Vivid Lime Green
  static const Color neoPurple  = Color(0xFF7C4DFF); // Electric Purple
  static const Color neoOrange  = Color(0xFFFF6D00); // Electric Orange

  // Legacy mappings mapped to high-contrast vibrant tokens
  static const Color primary      = Color(0xFF7C4DFF); // Electric Purple
  static const Color primaryDark  = Color(0xFF6200EA); 

  static const Color neonCyan    = Color(0xFF00E5FF); 
  static const Color neonPurple  = Color(0xFF7C4DFF); 
  static const Color neonPink    = Color(0xFFFF2A85); 
  static const Color neonRose    = Color(0xFFFF1744); 
  static const Color neonYellow  = Color(0xFFFFE600); 
  static const Color neonGreen   = Color(0xFF00E676); 

  // Semantic colors
  static const Color success = Color(0xFF00E676); 
  static const Color warning = Color(0xFFFFE600); 
  static const Color error   = Color(0xFFFF1744); 
  static const Color info    = Color(0xFF2979FF); 

  // High contrast Neo-Brutalism Text
  static const Color textPrimary   = Color(0xFF000000); // Jet Black
  static const Color textSecondary = Color(0xFF2D3748); // Dark Charcoal
  static const Color textDisabled  = Color(0xFF718096); 

  // Neo-Brutalist Thick Borders & Hard Shadows
  static const Color border      = Color(0xFF000000); // Solid Black Outline
  static const Color borderLight = Color(0xFF000000); 
  static const Color shadow      = Color(0xFF000000); // Solid Hard Shadow

  // Adaptive theme getters
  static Color getCanvasBg(bool isDark) => isDark ? darkBackground : background;
  static Color getCardBg(bool isDark) => isDark ? darkSurface : surface;
  static Color getTextPrimary(bool isDark) => isDark ? Colors.white : textPrimary;
  static Color getTextSecondary(bool isDark) => isDark ? const Color(0xFF94A3B8) : textSecondary;
  static Color getBorder(bool isDark) => isDark ? Colors.black : border;

  AppColors._();
}
