import 'package:flutter/material.dart';

class AppColors {
  // Ultra-deep obsidian black base inspired by modern high-contrast dark dashboards
  static const Color background   = Color(0xFF07090E); // Deepest obsidian black
  static const Color surface      = Color(0xFF0F131C); // Rich obsidian glass panel
  static const Color surfaceLight = Color(0xFF161C28); // Elevated obsidian card

  // Primary accent — Neon Electric Indigo
  static const Color primary      = Color(0xFF6366F1); // Indigo-500
  static const Color primaryDark  = Color(0xFF4F46E5); // Indigo-600

  // Neon accents
  static const Color neonCyan    = Color(0xFF06B6D4); // Cyan-500
  static const Color neonPurple  = Color(0xFFA855F7); // Purple-500
  static const Color neonPink    = Color(0xFFEC4899); // Pink-500
  static const Color neonRose    = Color(0xFFF43F5E); // Rose-500
  static const Color neonYellow  = Color(0xFFF59E0B); // Amber-500
  static const Color neonGreen   = Color(0xFF10B981); // Emerald-500

  // Semantic colors
  static const Color success = Color(0xFF10B981); // Emerald-500
  static const Color warning = Color(0xFFF59E0B); // Amber-500
  static const Color error   = Color(0xFFEF4444); // Red-500
  static const Color info    = Color(0xFF3B82F6); // Blue-500

  // Text
  static const Color textPrimary   = Color(0xFFF8FAFC); // Slate-50
  static const Color textSecondary = Color(0xFF94A3B8); // Slate-400
  static const Color textDisabled  = Color(0xFF475569); // Slate-600

  // Borders
  static const Color border      = Color(0xFF1E2638); // Dark obsidian border
  static const Color borderLight = Color(0xFF2A344B); // Subtle card outline

  AppColors._();
}
