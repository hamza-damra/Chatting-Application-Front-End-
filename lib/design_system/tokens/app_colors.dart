import 'package:flutter/material.dart';

/// Abstract interface for app color tokens.
/// Defines all color tokens required by the design system.
abstract class AppColors {
  // Background colors
  Color get background;
  Color get surface;
  Color get surfaceElevated;
  Color get surfaceHighest;

  // Text colors
  Color get textPrimary;
  Color get textSecondary;
  Color get textTertiary;
  Color get textOnPrimary;

  // Brand colors
  Color get primary;
  Color get primaryLight;
  Color get secondary;

  // Semantic colors
  Color get success;
  Color get warning;
  Color get error;
  Color get info;

  // Border/Outline colors
  Color get outline;
  Color get outlineVariant;
  Color get divider;

  // Shimmer colors
  Color get shimmerBase;
  Color get shimmerHighlight;

  // Message bubble colors
  Color get sentMessage;
  Color get receivedMessage;
  Color get sentMessageText;
  Color get receivedMessageText;

  // Online status
  Color get online;
  Color get offline;
}

/// Light theme color tokens implementation.
class LightAppColors implements AppColors {
  const LightAppColors();

  // Background colors
  @override
  Color get background => const Color(0xFFF8F9FC);
  @override
  Color get surface => Colors.white;
  @override
  Color get surfaceElevated => const Color(0xFFFAFAFA);
  @override
  Color get surfaceHighest => const Color(0xFFF5F5F5);

  // Text colors
  @override
  Color get textPrimary => const Color(0xFF1F2937);
  @override
  Color get textSecondary => const Color(0xFF6B7280);
  @override
  Color get textTertiary => const Color(0xFF9CA3AF);
  @override
  Color get textOnPrimary => Colors.white;

  // Brand colors
  @override
  Color get primary => const Color(0xFF4A6FE5);
  @override
  Color get primaryLight => const Color(0xFF7B9AEF);
  @override
  Color get secondary => const Color(0xFF2A3F65);

  // Semantic colors
  @override
  Color get success => const Color(0xFF10B981);
  @override
  Color get warning => const Color(0xFFF59E0B);
  @override
  Color get error => const Color(0xFFE53935);
  @override
  Color get info => const Color(0xFF3B82F6);

  // Border/Outline colors
  @override
  Color get outline => const Color(0xFFE5E7EB);
  @override
  Color get outlineVariant => const Color(0xFFD1D5DB);
  @override
  Color get divider => const Color(0xFFE5E7EB);

  // Shimmer colors
  @override
  Color get shimmerBase => const Color(0xFFE0E0E0);
  @override
  Color get shimmerHighlight => const Color(0xFFF5F5F5);

  // Message bubble colors
  @override
  Color get sentMessage => const Color(0xFF4A6FE5);
  @override
  Color get receivedMessage => const Color(0xFFF3F4F6);
  @override
  Color get sentMessageText => Colors.white;
  @override
  Color get receivedMessageText => const Color(0xFF1F2937);

  // Online status
  @override
  Color get online => const Color(0xFF10B981);
  @override
  Color get offline => const Color(0xFF9CA3AF);
}

/// Dark theme color tokens implementation.
/// Uses layered surfaces with subtle elevation differences instead of flat black.
class DarkAppColors implements AppColors {
  const DarkAppColors();

  // Background colors - layered surfaces, not pure black
  @override
  Color get background => const Color(0xFF121212);
  @override
  Color get surface => const Color(0xFF1E1E1E);
  @override
  Color get surfaceElevated => const Color(0xFF2A2A2A);
  @override
  Color get surfaceHighest => const Color(0xFF353535);

  // Text colors
  @override
  Color get textPrimary => const Color(0xFFF3F4F6);
  @override
  Color get textSecondary => const Color(0xFFD1D5DB);
  @override
  Color get textTertiary => const Color(0xFF9CA3AF);
  @override
  Color get textOnPrimary => Colors.white;

  // Brand colors
  @override
  Color get primary => const Color(0xFF4A6FE5);
  @override
  Color get primaryLight => const Color(0xFF7B9AEF);
  @override
  Color get secondary => const Color(0xFF5A7FD5);

  // Semantic colors
  @override
  Color get success => const Color(0xFF34D399);
  @override
  Color get warning => const Color(0xFFFBBF24);
  @override
  Color get error => const Color(0xFFEF5350);
  @override
  Color get info => const Color(0xFF60A5FA);

  // Border/Outline colors
  @override
  Color get outline => const Color(0xFF3A3A3A);
  @override
  Color get outlineVariant => const Color(0xFF4A4A4A);
  @override
  Color get divider => const Color(0xFF3A3A3A);

  // Shimmer colors - improved contrast for dark mode
  @override
  Color get shimmerBase => const Color(0xFF3A3A3A);
  @override
  Color get shimmerHighlight => const Color(0xFF4A4A4A);

  // Message bubble colors
  @override
  Color get sentMessage => const Color(0xFF4A6FE5);
  @override
  Color get receivedMessage => const Color(0xFF2D2D2D);
  @override
  Color get sentMessageText => Colors.white;
  @override
  Color get receivedMessageText => const Color(0xFFF3F4F6);

  // Online status
  @override
  Color get online => const Color(0xFF34D399);
  @override
  Color get offline => const Color(0xFF6B7280);
}
