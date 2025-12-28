import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand Primary Colors
  static const Color primaryBlue = Color(0xFF2563EB); // Brand blue
  static const Color primaryBlueDark = Color(0xFF1D4ED8);
  static const Color primaryBlueLight = Color(0xFF3B82F6);

  // Medical Context Accents
  static const Color softTeal = Color(
    0xFF14B8A6,
  ); // Soft teal for medical context
  static const Color softTealLight = Color(0xFF5EEAD4);
  static const Color softTealDark = Color(0xFF0F766E);

  // Neutral Grays for Structure
  static const Color grayNeutral50 = Color(0xFFF9FAFB);
  static const Color grayNeutral100 = Color(0xFFF3F4F6);
  static const Color grayNeutral200 = Color(0xFFE5E7EB);
  static const Color grayNeutral300 = Color(0xFFD1D5DB);
  static const Color grayNeutral400 = Color(0xFF9CA3AF);
  static const Color grayNeutral500 = Color(0xFF6B7280);
  static const Color grayNeutral600 = Color(0xFF4B5563);
  static const Color grayNeutral700 = Color(0xFF374151);
  static const Color grayNeutral800 = Color(0xFF1F2937);
  static const Color grayNeutral900 = Color(0xFF111827);

  // Background Colors
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundGray = Color(0xFFF8FAFC);
  static const Color backgroundCard = Color(0xFFFFFFFF);

  // Status Colors
  static const Color successGreen = Color(
    0xFF10B981,
  ); // Available stock/success
  static const Color successGreenLight = Color(0xFF34D399);
  static const Color successGreenDark = Color(0xFF059669);

  static const Color errorRed = Color(
    0xFFEF4444,
  ); // Errors/missing items/overdue
  static const Color errorRedLight = Color(0xFFF87171);
  static const Color errorRedDark = Color(0xFFDC2626);

  static const Color warningYellow = Color(0xFFF59E0B);
  static const Color warningYellowLight = Color(0xFFFBBF24);
  static const Color warningYellowDark = Color(0xFFD97706);

  // Text Colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // Shadow Colors
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowMedium = Color(0x26000000);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryBlue, primaryBlueDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient medicalGradient = LinearGradient(
    colors: [softTeal, softTealDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [successGreen, successGreenDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
