import 'package:flutter/material.dart';

/// App color palette - Modern 2025 Design System
class AppColors {
  AppColors._();

  // Primary colors (Fresh green with modern teal undertones)
  static const Color primary = Color(0xFF10B981);
  static const Color primaryDark = Color(0xFF059669);
  static const Color primaryLight = Color(0xFF34D399);
  static const Color primarySurface = Color(0xFFD1FAE5);

  // Secondary colors (Warm amber for market vibrancy)
  static const Color secondary = Color(0xFFF59E0B);
  static const Color secondaryDark = Color(0xFFD97706);
  static const Color secondaryLight = Color(0xFFFBBF24);
  static const Color secondarySurface = Color(0xFFFEF3C7);

  // Light theme colors
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  // Dark theme colors
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceVariantDark = Color(0xFF334155);
  static const Color surfaceElevatedDark = Color(0xFF1E293B);

  // Light theme text colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);
  static const Color textDisabled = Color(0xFFCBD5E1);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Dark theme text colors - Improved contrast
  static const Color textPrimaryDark = Color(0xFFFAFAFA);  // Brighter for better readability
  static const Color textSecondaryDark = Color(0xFFCBD5E1);  // Much brighter for better visibility
  static const Color textHintDark = Color(0xFF94A3B8);  // Slightly brighter
  static const Color textDisabledDark = Color(0xFF64748B);

  // Semantic colors
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // Dividers and borders
  static const Color divider = Color(0xFFE2E8F0);
  static const Color dividerDark = Color(0xFF334155);
  static const Color border = Color(0xFFCBD5E1);
  static const Color borderDark = Color(0xFF475569);

  // Status colors for orders
  static const Color statusPending = Color(0xFFF59E0B);
  static const Color statusConfirmed = Color(0xFF3B82F6);
  static const Color statusPreparing = Color(0xFF8B5CF6);
  static const Color statusReady = Color(0xFF10B981);
  static const Color statusInTransit = Color(0xFF06B6D4);
  static const Color statusDelivered = Color(0xFF10B981);
  static const Color statusCancelled = Color(0xFFEF4444);

  // Overlay colors
  static const Color overlay = Color(0x33000000);
  static const Color overlayLight = Color(0x1A000000);
  static const Color overlayDark = Color(0x66000000);

  // Shimmer colors
  static const Color shimmerBase = Color(0xFFE2E8F0);
  static const Color shimmerHighlight = Color(0xFFF8FAFC);
  static const Color shimmerBaseDark = Color(0xFF334155);
  static const Color shimmerHighlightDark = Color(0xFF475569);

  // Gradient colors for modern effects
  static const List<Color> primaryGradient = [
    Color(0xFF10B981),
    Color(0xFF059669),
  ];

  static const List<Color> secondaryGradient = [
    Color(0xFFF59E0B),
    Color(0xFFD97706),
  ];

  static const List<Color> cardGradientLight = [
    Color(0xFFFFFFFF),
    Color(0xFFF8FAFC),
  ];

  static const List<Color> cardGradientDark = [
    Color(0xFF1E293B),
    Color(0xFF0F172A),
  ];
}
