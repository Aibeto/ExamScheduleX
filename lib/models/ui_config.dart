import 'dart:convert';
import 'package:flutter/services.dart';

class LiquidGlassConfig {
  final double thickness;
  final double blur;
  final Color glassColor;
  final String specularSharpness;
  final double visibility;
  final double chromaticAberration;
  final double lightAngle;
  final double lightIntensity;
  final double ambientStrength;
  final double refractiveIndex;
  final double saturation;

  const LiquidGlassConfig({
    this.thickness = 20,
    this.blur = 5,
    this.glassColor = const Color(0x00FFFFFF),
    this.specularSharpness = 'medium',
    this.visibility = 1.0,
    this.chromaticAberration = 0.01,
    this.lightAngle = 0.785,
    this.lightIntensity = 0.5,
    this.ambientStrength = 0,
    this.refractiveIndex = 1.2,
    this.saturation = 1.5,
  });

  factory LiquidGlassConfig.fromJson(Map<String, dynamic> json) {
    return LiquidGlassConfig(
      thickness: (json['thickness'] as num?)?.toDouble() ?? 20,
      blur: (json['blur'] as num?)?.toDouble() ?? 5,
      glassColor: _parseColor(json['glassColor'] as String? ?? '#00FFFFFF'),
      specularSharpness: json['specularSharpness'] as String? ?? 'medium',
      visibility: (json['visibility'] as num?)?.toDouble() ?? 1.0,
      chromaticAberration:
          (json['chromaticAberration'] as num?)?.toDouble() ?? 0.01,
      lightAngle: (json['lightAngle'] as num?)?.toDouble() ?? 0.785,
      lightIntensity: (json['lightIntensity'] as num?)?.toDouble() ?? 0.5,
      ambientStrength: (json['ambientStrength'] as num?)?.toDouble() ?? 0,
      refractiveIndex: (json['refractiveIndex'] as num?)?.toDouble() ?? 1.2,
      saturation: (json['saturation'] as num?)?.toDouble() ?? 1.5,
    );
  }
}

class FluidBackgroundConfig {
  final double velocity;
  final double bubblesSize;
  final List<double> sizeChangingRange;
  final bool allowColorChanging;
  final int bubbleMutationDurationSeconds;
  final List<Color> initialColors;

  const FluidBackgroundConfig({
    this.velocity = 1,
    this.bubblesSize = 500,
    this.sizeChangingRange = const [300, 600],
    this.allowColorChanging = true,
    this.bubbleMutationDurationSeconds = 4,
    this.initialColors = const [
      Color(0xFF4D9EF0),
      Color(0xFFA06CD5),
      Color(0xFFF06292),
      Color(0xFF4DB6AC),
      Color(0xFFFFD54F),
      Color(0xFF81C784),
      Color(0xFF4FC3F7),
      Color(0xFFFF8A65),
      Color(0xFF9575CD),
      Color(0xFF4DD0E1),
    ],
  });

  factory FluidBackgroundConfig.fromJson(Map<String, dynamic> json) {
    return FluidBackgroundConfig(
      velocity: (json['velocity'] as num?)?.toDouble() ?? 1,
      bubblesSize: (json['bubblesSize'] as num?)?.toDouble() ?? 500,
      sizeChangingRange: (json['sizeChangingRange'] as List?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [300, 600],
      allowColorChanging: json['allowColorChanging'] as bool? ?? true,
      bubbleMutationDurationSeconds:
          (json['bubbleMutationDurationSeconds'] as num?)?.toInt() ?? 4,
      initialColors: (json['initialColors'] as List?)
              ?.map((e) => _parseColor(e as String))
              .toList() ??
          [
            const Color(0xFF4D9EF0),
            const Color(0xFFA06CD5),
            const Color(0xFFF06292),
            const Color(0xFF4DB6AC)
          ],
    );
  }
}

class LayoutConfig {
  final double bannerHeightRatio;
  final double messageCardMaxHeightRatio;
  final double clockTextWidthRatio;
  final double clockPaddingVerticalRatio;
  final List<int> leftRightRatio;
  final double padding;
  final double spacing;

  const LayoutConfig({
    this.bannerHeightRatio = 0.1,
    this.messageCardMaxHeightRatio = 0.2,
    this.clockTextWidthRatio = 0.4,
    this.clockPaddingVerticalRatio = 0.05,
    this.leftRightRatio = const [5, 5],
    this.padding = 16,
    this.spacing = 8,
  });

  factory LayoutConfig.fromJson(Map<String, dynamic> json) {
    return LayoutConfig(
      bannerHeightRatio: (json['bannerHeightRatio'] as num?)?.toDouble() ?? 0.1,
      messageCardMaxHeightRatio:
          (json['messageCardMaxHeightRatio'] as num?)?.toDouble() ?? 0.2,
      clockTextWidthRatio:
          (json['clockTextWidthRatio'] as num?)?.toDouble() ?? 0.4,
      clockPaddingVerticalRatio:
          (json['clockPaddingVerticalRatio'] as num?)?.toDouble() ?? 0.05,
      leftRightRatio: (json['leftRightRatio'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [5, 5],
      padding: (json['padding'] as num?)?.toDouble() ?? 16,
      spacing: (json['spacing'] as num?)?.toDouble() ?? 8,
    );
  }
}

class TypographyConfig {
  final double bannerFontSize;
  final double messageFontSize;
  final double messageMinFontSize;
  final double clockFontSize;
  final double subjectCardTitleFontSize;
  final double subjectCardDetailFontSize;
  final double scheduleHeaderFontSize;
  final double scheduleRowFontSize;

  const TypographyConfig({
    this.bannerFontSize = 30,
    this.messageFontSize = 28,
    this.messageMinFontSize = 14,
    this.clockFontSize = 64,
    this.subjectCardTitleFontSize = 32,
    this.subjectCardDetailFontSize = 26,
    this.scheduleHeaderFontSize = 24,
    this.scheduleRowFontSize = 22,
  });

  factory TypographyConfig.fromJson(Map<String, dynamic> json) {
    return TypographyConfig(
      bannerFontSize: (json['bannerFontSize'] as num?)?.toDouble() ?? 30,
      messageFontSize: (json['messageFontSize'] as num?)?.toDouble() ?? 28,
      messageMinFontSize:
          (json['messageMinFontSize'] as num?)?.toDouble() ?? 14,
      clockFontSize: (json['clockFontSize'] as num?)?.toDouble() ?? 64,
      subjectCardTitleFontSize:
          (json['subjectCardTitleFontSize'] as num?)?.toDouble() ?? 32,
      subjectCardDetailFontSize:
          (json['subjectCardDetailFontSize'] as num?)?.toDouble() ?? 26,
      scheduleHeaderFontSize:
          (json['scheduleHeaderFontSize'] as num?)?.toDouble() ?? 24,
      scheduleRowFontSize:
          (json['scheduleRowFontSize'] as num?)?.toDouble() ?? 22,
    );
  }
}

class UiConfig {
  final String fontFamily;
  final LiquidGlassConfig liquidGlass;
  final FluidBackgroundConfig fluidBackground;
  final LayoutConfig layout;
  final TypographyConfig typography;

  const UiConfig({
    this.fontFamily = 'Harmony',
    this.liquidGlass = const LiquidGlassConfig(),
    this.fluidBackground = const FluidBackgroundConfig(),
    this.layout = const LayoutConfig(),
    this.typography = const TypographyConfig(),
  });

  factory UiConfig.fromJson(Map<String, dynamic> json) {
    return UiConfig(
      fontFamily: json['fontFamily'] as String? ?? 'Harmony',
      liquidGlass: json['liquidGlass'] != null
          ? LiquidGlassConfig.fromJson(
              json['liquidGlass'] as Map<String, dynamic>)
          : const LiquidGlassConfig(),
      fluidBackground: json['fluidBackground'] != null
          ? FluidBackgroundConfig.fromJson(
              json['fluidBackground'] as Map<String, dynamic>)
          : const FluidBackgroundConfig(),
      layout: json['layout'] != null
          ? LayoutConfig.fromJson(json['layout'] as Map<String, dynamic>)
          : const LayoutConfig(),
      typography: json['typography'] != null
          ? TypographyConfig.fromJson(
              json['typography'] as Map<String, dynamic>)
          : const TypographyConfig(),
    );
  }

  static Future<UiConfig> load() async {
    try {
      final jsonString = await rootBundle.loadString('assets/ui_config.json');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      return UiConfig.fromJson(jsonData);
    } catch (_) {
      return const UiConfig();
    }
  }
}

Color _parseColor(String hexString) {
  final hex = hexString.replaceFirst('#', '');
  if (hex.length == 6) {
    return Color(int.parse('FF$hex', radix: 16));
  }
  if (hex.length == 8) {
    return Color(int.parse(hex, radix: 16));
  }
  return const Color(0x1AFFFFFF);
}
