import 'package:flutter/material.dart';

abstract final class LifeLinkColors {
  static const red = Color(0xffcf2929);
  static const redSoft = Color(0xffffe8e8);
  static const canvas = Color(0xfff6f7fa);
  static const surface = Colors.white;
  static const ink = Color(0xff17233b);
  static const muted = Color(0xff758198);
  static const border = Color(0xffe7e9ef);
}

abstract final class LifeLinkTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: LifeLinkColors.red,
      brightness: Brightness.light,
    ).copyWith(
      primary: LifeLinkColors.red,
      onPrimary: Colors.white,
      secondary: LifeLinkColors.red,
      onSecondary: Colors.white,
      surface: LifeLinkColors.surface,
      onSurface: LifeLinkColors.ink,
      error: LifeLinkColors.red,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: LifeLinkColors.canvas,
      appBarTheme: const AppBarTheme(
        backgroundColor: LifeLinkColors.surface,
        foregroundColor: LifeLinkColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: LifeLinkColors.ink,
          fontSize: 17,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: LifeLinkColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: LifeLinkColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LifeLinkColors.canvas,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: LifeLinkColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: LifeLinkColors.red, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          side: const BorderSide(color: LifeLinkColors.border),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: LifeLinkColors.surface,
        indicatorColor: LifeLinkColors.redSoft,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? LifeLinkColors.red
                : LifeLinkColors.muted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 22,
            color: states.contains(WidgetState.selected)
                ? LifeLinkColors.red
                : LifeLinkColors.muted,
          ),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: LifeLinkColors.surface,
        modalBackgroundColor: LifeLinkColors.surface,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: LifeLinkColors.muted,
        showDragHandle: true,
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: LifeLinkColors.surface,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
