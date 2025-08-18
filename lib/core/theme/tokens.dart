import 'package:flutter/material.dart';

@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  final double spacingXs;
  final double spacingSm;
  final double spacingMd;
  final double spacingLg;
  final double spacingXl;

  final double radiusSm;
  final double radiusMd;
  final double radiusLg;

  final double elevationSm;
  final double elevationMd;
  final double elevationLg;

  const AppTokens({
    this.spacingXs = 4,
    this.spacingSm = 8,
    this.spacingMd = 16,
    this.spacingLg = 24,
    this.spacingXl = 32,
    this.radiusSm = 8,
    this.radiusMd = 12,
    this.radiusLg = 16,
    this.elevationSm = 2,
    this.elevationMd = 4,
    this.elevationLg = 8,
  });

  @override
  AppTokens copyWith({
    double? spacingXs,
    double? spacingSm,
    double? spacingMd,
    double? spacingLg,
    double? spacingXl,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    double? elevationSm,
    double? elevationMd,
    double? elevationLg,
  }) {
    return AppTokens(
      spacingXs: spacingXs ?? this.spacingXs,
      spacingSm: spacingSm ?? this.spacingSm,
      spacingMd: spacingMd ?? this.spacingMd,
      spacingLg: spacingLg ?? this.spacingLg,
      spacingXl: spacingXl ?? this.spacingXl,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
      elevationSm: elevationSm ?? this.elevationSm,
      elevationMd: elevationMd ?? this.elevationMd,
      elevationLg: elevationLg ?? this.elevationLg,
    );
  }

  @override
  AppTokens lerp(ThemeExtension<AppTokens>? other, double t) {
    if (other is! AppTokens) return this;
    return AppTokens(
      spacingXs: lerpDouble(spacingXs, other.spacingXs, t),
      spacingSm: lerpDouble(spacingSm, other.spacingSm, t),
      spacingMd: lerpDouble(spacingMd, other.spacingMd, t),
      spacingLg: lerpDouble(spacingLg, other.spacingLg, t),
      spacingXl: lerpDouble(spacingXl, other.spacingXl, t),
      radiusSm: lerpDouble(radiusSm, other.radiusSm, t),
      radiusMd: lerpDouble(radiusMd, other.radiusMd, t),
      radiusLg: lerpDouble(radiusLg, other.radiusLg, t),
      elevationSm: lerpDouble(elevationSm, other.elevationSm, t),
      elevationMd: lerpDouble(elevationMd, other.elevationMd, t),
      elevationLg: lerpDouble(elevationLg, other.elevationLg, t),
    );
  }

  static double lerpDouble(double a, double b, double t) => a + (b - a) * t;
}
