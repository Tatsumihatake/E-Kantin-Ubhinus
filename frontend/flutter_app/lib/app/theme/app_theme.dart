import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

class AppColors {
  const AppColors._();

  static const primary = Color(0xFFEA580C);
  static const primaryDark = Color(0xFFC2410C);
  static const primaryContainer = Color(0xFFFFEDD5);
  static const canvas = Color(0xFFFAF8FF);
  static const surface = Colors.white;
  static const slate900 = Color(0xFF0F172A);
  static const slate600 = Color(0xFF475569);
  static const slate400 = Color(0xFF94A3B8);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate100 = Color(0xFFF1F5F9);
  static const success = Color(0xFF16A34A);
  static const successSoft = Color(0xFFDCFCE7);
  static const warning = Color(0xFFD97706);
  static const warningSoft = Color(0xFFFEF3C7);
  static const danger = Color(0xFFDC2626);
  static const dangerSoft = Color(0xFFFEE2E2);
  static const info = Color(0xFF0284C7);
  static const infoSoft = Color(0xFFE0F2FE);
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: const Color(0xFFF97316),
      surface: AppColors.surface,
      onSurface: AppColors.slate900,
    );

    final textTheme = GoogleFonts.plusJakartaSansTextTheme().apply(
      bodyColor: AppColors.slate900,
      displayColor: AppColors.slate900,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.canvas,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.slate900,
        ),
        iconTheme: const IconThemeData(color: AppColors.slate900),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: AppColors.slate400, fontSize: 14),
        labelStyle: const TextStyle(color: AppColors.slate600, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.slate200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.slate200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.slate600,
          minimumSize: const Size(0, 48),
          side: const BorderSide(color: AppColors.slate200),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      dividerColor: AppColors.slate200,
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: AppColors.primaryContainer,
        side: const BorderSide(color: AppColors.slate200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
