import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Nền cosmic (theo mockup Welcome)
  static const bgTop = Color(0xFF0D0A2E);
  static const bgMid = Color(0xFF1C1240);
  static const bgBottom = Color(0xFF120D35);

  // Accent
  static const purple = Color(0xFF8B3FE8);
  static const cyan = Color(0xFF00CFFF);

  // Onboarding (thiết lập hồ sơ, GPS...)
  static const onboardingBg = Color(0xFF160D35);
  static const magenta = Color(0xFFC040E8);
  static const deepPurple = Color(0xFF5B2D9E);
  static const fieldBg = Color(0xFF1E1455);

  // Text
  static const textPrimary = Color(0xFFE3DFFF);
  static const textMuted = Color(0xFF94A3B8);

  // Radar Discover
  static const lilac = Color(0xFFD7BAFF);
  static const statusOnline = Color(0xFF22C55E);

  // Màu báo lỗi (đỏ)
  static const error = Color(0xFFFF3B3B);

  static const primaryGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [purple, cyan],
  );
}
