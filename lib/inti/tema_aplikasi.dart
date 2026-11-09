import 'package:flutter/material.dart';

class WarnaAplikasi {
  static const primary = Color(0xFF2563EB);
  static const primaryDark = Color(0xFF1E40AF);
  static const primaryLight = Color(0xFFDBEAFE);
  static const accent = Color(0xFF0EA5E9);
  static const ink = Color(0xFF0F2742);
  static const muted = Color(0xFF64748B);
  static const background = Color(0xFFF4F7FC);
  static const cream = Color(0xFFEEF4FF);
  static const border = Color(0xFFDCE6F3);
  static const success = Color(0xFF16A34A);
  static const successSoft = Color(0xFFE7F8EE);
  static const danger = Color(0xFFDC2626);
  static const dangerSoft = Color(0xFFFDECEC);
  static const info = Color(0xFF3B82F6);
  static const infoSoft = Color(0xFFEAF2FF);
  static const warning = Color(0xFFD97706);
  static const warningSoft = Color(0xFFFEF3C7);
}

class TemaAplikasi {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: WarnaAplikasi.primary).copyWith(
      primary: WarnaAplikasi.primary,
      onPrimary: Colors.white,
      secondary: WarnaAplikasi.accent,
      onSecondary: Colors.white,
      surface: Colors.white,
      onSurface: WarnaAplikasi.ink,
      error: WarnaAplikasi.danger,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: WarnaAplikasi.background,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: WarnaAplikasi.background,
        foregroundColor: WarnaAplikasi.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: WarnaAplikasi.ink,
          letterSpacing: -0.3,
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: WarnaAplikasi.ink,
          letterSpacing: -0.4,
        ),
        titleMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: WarnaAplikasi.ink,
        ),
        bodyMedium: TextStyle(fontSize: 14, color: WarnaAplikasi.ink, height: 1.4),
        bodySmall: TextStyle(
          fontSize: 12,
          color: WarnaAplikasi.muted,
          height: 1.35,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: WarnaAplikasi.border),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: WarnaAplikasi.border,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: const TextStyle(color: WarnaAplikasi.muted, fontSize: 14),
        prefixIconColor: WarnaAplikasi.muted,
        suffixIconColor: WarnaAplikasi.muted,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: WarnaAplikasi.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: WarnaAplikasi.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: WarnaAplikasi.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: WarnaAplikasi.danger),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: WarnaAplikasi.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: WarnaAplikasi.ink,
          side: const BorderSide(color: WarnaAplikasi.border, width: 1.4),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: WarnaAplikasi.primaryDark,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        height: 68,
        indicatorColor: WarnaAplikasi.primary.withValues(alpha: 0.16),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            size: 24,
            color: selected ? WarnaAplikasi.primaryDark : WarnaAplikasi.muted,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? WarnaAplikasi.primaryDark : WarnaAplikasi.muted,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: WarnaAplikasi.ink,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: WarnaAplikasi.primary.withValues(alpha: 0.16),
        side: const BorderSide(color: WarnaAplikasi.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        labelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: WarnaAplikasi.ink,
        ),
      ),
    );
  }
}

