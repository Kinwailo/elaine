import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// The [AppTheme] defines light and dark themes for the app.
///
/// Theme setup for FlexColorScheme package v8.
/// Use same major flex_color_scheme package version. If you use a
/// lower minor version, some properties may not be supported.
/// In that case, remove them after copying this theme to your
/// app or upgrade the package to version 8.3.1.
///
/// Use it in a [MaterialApp] like this:
///
/// MaterialApp(
///   theme: AppTheme.light,
///   darkTheme: AppTheme.dark,
/// );
abstract final class AppTheme {
  // The FlexColorScheme defined light mode ThemeData.
  static ThemeData light = FlexThemeData.light(
    // User defined custom colors made with FlexSchemeColor() API.
    colors: const FlexSchemeColor(
      primary: Color(0xFF303F9F),
      primaryContainer: Color(0xFFAEB9F4),
      secondary: Color(0xFF512DA8),
      secondaryContainer: Color(0xFFE9DDFF),
      tertiary: Color(0xFF311B92),
      tertiaryContainer: Color(0xFFD1C5FF),
      appBarColor: Color(0xFFE9DDFF),
      error: Color(0xFFB00020),
      errorContainer: Color(0xFFFFDAD6),
    ),
    // Component theme configurations for light mode.
    subThemesData: const FlexSubThemesData(
      interactionEffects: true,
      tintedDisabledControls: true,
      useM2StyleDividerInM3: true,
      adaptiveSplash: FlexAdaptive.all(),
      splashType: FlexSplashType.inkSparkle,
      adaptiveRadius: FlexAdaptive.all(),
      elevatedButtonRadius: 34.0,
      inputDecoratorIsFilled: true,
      inputDecoratorBorderType: FlexInputBorderType.outline,
      inputDecoratorUnfocusedHasBorder: false,
      alignedDropdown: true,
      appBarBackgroundSchemeColor: SchemeColor.inversePrimary,
      appBarForegroundSchemeColor: SchemeColor.primary,
      navigationBarHeight: 55.0,
      navigationBarLabelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
      navigationRailUseIndicator: true,
    ),
    // Direct ThemeData properties.
    visualDensity: VisualDensity.adaptivePlatformDensity,
    cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
  );

  // The FlexColorScheme defined dark mode ThemeData.
  static ThemeData dark = FlexThemeData.dark(
    // User defined custom colors made with FlexSchemeColor() API.
    colors: const FlexSchemeColor(
      primary: Color(0xFF7986CB),
      primaryContainer: Color(0xFF283593),
      primaryLightRef: Color(0xFF303F9F), // The color of light mode primary
      secondary: Color(0xFF9575CD),
      secondaryContainer: Color(0xFF502CA7),
      secondaryLightRef: Color(0xFF512DA8), // The color of light mode secondary
      tertiary: Color(0xFF7E57C2),
      tertiaryContainer: Color(0xFF4433A4),
      tertiaryLightRef: Color(0xFF311B92), // The color of light mode tertiary
      appBarColor: Color(0xFFE9DDFF),
      error: Color(0xFFCF6679),
      errorContainer: Color(0xFF93000A),
    ),
    // Input color modifiers.
    swapColors: true,
    // Component theme configurations for dark mode.
    subThemesData: const FlexSubThemesData(
      interactionEffects: true,
      tintedDisabledControls: true,
      blendOnColors: true,
      useM2StyleDividerInM3: true,
      adaptiveSplash: FlexAdaptive.all(),
      splashType: FlexSplashType.inkSparkle,
      adaptiveRadius: FlexAdaptive.all(),
      elevatedButtonRadius: 34.0,
      inputDecoratorIsFilled: true,
      inputDecoratorBorderType: FlexInputBorderType.outline,
      inputDecoratorUnfocusedHasBorder: false,
      alignedDropdown: true,
      appBarBackgroundSchemeColor: SchemeColor.inversePrimary,
      appBarForegroundSchemeColor: SchemeColor.primary,
      navigationBarHeight: 55.0,
      navigationBarLabelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
      navigationRailUseIndicator: true,
    ),
    // Direct ThemeData properties.
    visualDensity: VisualDensity.adaptivePlatformDensity,
    cupertinoOverrideTheme: const CupertinoThemeData(applyThemeToAll: true),
  );
}
