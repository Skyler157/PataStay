import 'package:flutter/material.dart';

/// PataStay brand palette.
///
/// "Coast Teal & Saffron". Deep teal (primary) is calm and trustworthy
/// without being another travel-app blue or mobile-money green. Saffron is a
/// warm accent kept for small moments (the logo sun, Featured, selected area
/// tiles) and is always used as a fill with dark text. Clay marks a saved
/// heart. Sand is the page background. Verified uses the classic trust blue so
/// the badge never blends into the brand colour.
/// All text/background pairs meet WCAG AA (4.5:1) contrast.
abstract final class PataColors {
  static const teal = Color(0xFF0E6B70);
  static const tealDeep = Color(0xFF053A3D);
  static const tealContainer = Color(0xFFD3EFEE);
  static const tealLight = Color(0xFF6FD3CF);

  static const saffron = Color(0xFFF6B53D);
  static const saffronContainer = Color(0xFFFCEBC4);
  static const saffronDeep = Color(0xFF5A3A00);

  static const clay = Color(0xFFB9502A);
  static const clayContainer = Color(0xFFFBE4DA);
  static const clayLight = Color(0xFFF0A07E);

  static const sand = Color(0xFFF7F4EF);
  static const sandDeep = Color(0xFFEFEAE2);
  static const white = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1B1A17);
  static const inkMuted = Color(0xFF5E5950);
  static const line = Color(0xFFE2DDD4);

  static const night = Color(0xFF111318);
  static const nightSurface = Color(0xFF191C22);
  static const nightSurfaceHigh = Color(0xFF23272F);
  static const nightLine = Color(0xFF343A45);
  static const mist = Color(0xFFEDEAE4);
  static const mistMuted = Color(0xFFB3AEA5);
}

/// 4-point spacing scale.
abstract final class Space {
  static const xxs = 2.0;
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;
  static const xxxl = 48.0;

  /// Standard horizontal page gutter.
  static const gutter = 20.0;
}

abstract final class Radii {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const pill = 999.0;
}

/// Minimum interactive size (Material/Apple accessibility guidance).
const kMinTouchTarget = 48.0;

/// Semantic colours that ColorScheme does not cover.
@immutable
class PataPalette extends ThemeExtension<PataPalette> {
  const PataPalette({
    required this.verified,
    required this.verifiedContainer,
    required this.success,
    required this.successContainer,
    required this.warning,
    required this.warningContainer,
    required this.danger,
    required this.dangerContainer,
    required this.neutralContainer,
    required this.mutedText,
    required this.price,
  });

  final Color verified;
  final Color verifiedContainer;
  final Color success;
  final Color successContainer;
  final Color warning;
  final Color warningContainer;
  final Color danger;
  final Color dangerContainer;
  final Color neutralContainer;
  final Color mutedText;
  final Color price;

  static const light = PataPalette(
    verified: Color(0xFF1C5BC7),
    verifiedContainer: Color(0xFFDDE8FB),
    success: Color(0xFF14713A),
    successContainer: Color(0xFFDCF2E3),
    warning: Color(0xFF8A5A00),
    warningContainer: Color(0xFFFCEFCF),
    danger: Color(0xFFB42318),
    dangerContainer: Color(0xFFFDE3E1),
    neutralContainer: PataColors.sandDeep,
    mutedText: PataColors.inkMuted,
    price: PataColors.ink,
  );

  static const dark = PataPalette(
    verified: Color(0xFF8DB4FF),
    verifiedContainer: Color(0xFF1C2B47),
    success: Color(0xFF7FD6A0),
    successContainer: Color(0xFF173323),
    warning: Color(0xFFF2C46B),
    warningContainer: Color(0xFF3A2D10),
    danger: Color(0xFFFF9C92),
    dangerContainer: Color(0xFF43191A),
    neutralContainer: PataColors.nightSurfaceHigh,
    mutedText: PataColors.mistMuted,
    price: PataColors.mist,
  );

  @override
  PataPalette copyWith({
    Color? verified,
    Color? verifiedContainer,
    Color? success,
    Color? successContainer,
    Color? warning,
    Color? warningContainer,
    Color? danger,
    Color? dangerContainer,
    Color? neutralContainer,
    Color? mutedText,
    Color? price,
  }) {
    return PataPalette(
      verified: verified ?? this.verified,
      verifiedContainer: verifiedContainer ?? this.verifiedContainer,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      danger: danger ?? this.danger,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      neutralContainer: neutralContainer ?? this.neutralContainer,
      mutedText: mutedText ?? this.mutedText,
      price: price ?? this.price,
    );
  }

  @override
  PataPalette lerp(ThemeExtension<PataPalette>? other, double t) {
    if (other is! PataPalette) return this;
    return PataPalette(
      verified: Color.lerp(verified, other.verified, t)!,
      verifiedContainer: Color.lerp(verifiedContainer, other.verifiedContainer, t)!,
      success: Color.lerp(success, other.success, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      warningContainer: Color.lerp(warningContainer, other.warningContainer, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      dangerContainer: Color.lerp(dangerContainer, other.dangerContainer, t)!,
      neutralContainer: Color.lerp(neutralContainer, other.neutralContainer, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      price: Color.lerp(price, other.price, t)!,
    );
  }
}

extension PataThemeContext on BuildContext {
  PataPalette get palette => Theme.of(this).extension<PataPalette>() ?? PataPalette.light;
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
}
