// ============================================================
// 文件: ui_config.dart
// 描述: 考试安排应用的UI配置模型定义
// 功能: 定义所有UI相关的配置类，直接在代码中配置默认值
// 配置项: 字体、液态玻璃效果、流体背景、布局、排版
// ============================================================

import 'package:flutter/material.dart';

/// 液态玻璃效果配置类
///
/// 该类定义了液态玻璃（Liquid Glass）视觉效果的所有可配置参数。
/// 液态玻璃效果模拟真实玻璃的折射、反射和色散等光学特性，
/// 为UI组件提供半透明、模糊和光泽的视觉风格。
///
/// 配置参数说明:
/// - [thickness]: 玻璃厚度，值越大折射和反射效果越明显
/// - [blur]: 背景模糊程度，值越大背景越模糊
/// - [glassColor]: 玻璃叠加颜色，会与背景混合产生色调效果
/// - [specularSharpness]: 高光锐度，控制高光的柔和/锐利程度（'soft'/'medium'/'sharp'）
/// - [visibility]: 玻璃可见度，1.0为完全可见，0.0为完全透明
/// - [chromaticAberration]: 色差，模拟光线折射产生的色彩偏移
/// - [lightAngle]: 光照角度（弧度），影响高光位置
/// - [lightIntensity]: 光照强度，影响高光亮度
/// - [ambientStrength]: 环境光强度，影响整体亮度
/// - [refractiveIndex]: 折射率，影响背景扭曲程度（真实玻璃约1.5）
/// - [saturation]: 饱和度，影响背景色彩的鲜艳程度
class LiquidGlassConfig {
  /// 玻璃厚度，默认值20
  /// 值越大，折射和反射效果越明显，玻璃看起来越厚
  final double thickness;

  /// 背景模糊程度，默认值5
  /// 值越大，透过玻璃看到的背景越模糊
  final double blur;

  /// 玻璃叠加颜色，默认透明白色 (0x00FFFFFF)
  /// 该颜色会叠加在背景上，产生色调效果
  /// 使用ARGB格式，0x00表示完全透明
  final Color glassColor;

  /// 高光锐度，默认值 'medium'
  /// 可选值: 'soft'（柔和）、'medium'（中等）、'sharp'（锐利）
  /// 在 home_page.dart 中会被转换为 [GlassSpecularSharpness] 枚举
  final String specularSharpness;

  /// 玻璃可见度，默认值1.0
  /// 1.0表示完全可见，0.0表示完全透明
  /// 控制玻璃效果的整体强度
  final double visibility;

  /// 色差，默认值0.01
  /// 模拟光线折射产生的色彩偏移效果
  /// 值越大，边缘的色彩分离越明显
  final double chromaticAberration;

  /// 光照角度，默认值0.785（约45度，π/4弧度）
  /// 以弧度为单位，影响高光在玻璃上的位置
  final double lightAngle;

  /// 光照强度，默认值0.5
  /// 控制高光的亮度，值越大高光越亮
  final double lightIntensity;

  /// 环境光强度，默认值0
  /// 控制玻璃的整体基础亮度，值越大整体越亮
  final double ambientStrength;

  /// 折射率，默认值1.2
  /// 影响背景扭曲程度，真实玻璃约1.5，水约1.33
  /// 值越大，透过玻璃看到的背景扭曲越明显
  final double refractiveIndex;

  /// 饱和度，默认值1.5
  /// 控制背景色彩的鲜艳程度
  /// 1.0为原始饱和度，>1.0更鲜艳，<1.0更灰暗
  final double saturation;

  /// 构造函数，所有参数均有默认值
  ///
  /// 默认值经过精心调整，产生中等强度的玻璃效果，
  /// 适合大多数场景使用。修改默认值即可调整全局配置。
  ///
  /// 参数说明:
  /// - [thickness]: 玻璃厚度，值越大折射和反射效果越明显，默认值20
  /// - [blur]: 背景模糊程度，值越大背景越模糊，默认值5
  /// - [glassColor]: 玻璃叠加颜色，会与背景混合产生色调效果，默认透明白色 (0x00FFFFFF)
  /// - [specularSharpness]: 高光锐度，控制高光的柔和/锐利程度（'soft'/'medium'/'sharp'），默认值'medium'
  /// - [visibility]: 玻璃可见度，1.0为完全可见，0.0为完全透明，默认值1.0
  /// - [chromaticAberration]: 色差，模拟光线折射产生的色彩偏移，默认值0.01
  /// - [lightAngle]: 光照角度（弧度），影响高光位置，默认值0.785（约45度）
  /// - [lightIntensity]: 光照强度，影响高光亮度，默认值0.5
  /// - [ambientStrength]: 环境光强度，影响整体亮度，默认值0
  /// - [refractiveIndex]: 折射率，影响背景扭曲程度（真实玻璃约1.5），默认值1.2
  /// - [saturation]: 饱和度，影响背景色彩的鲜艳程度，默认值1.5
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
}

/// 流体动态背景配置类
///
/// 该类定义了流体动态背景（Fluid Background）的所有可配置参数。
/// 流体背景通过多个彩色气泡的浮动动画，创造出流动、生动的视觉效果。
///
/// 配置参数说明:
/// - [velocity]: 气泡移动速度
/// - [bubblesSize]: 气泡基础大小
/// - [sizeChangingRange]: 气泡大小变化范围 [最小值, 最大值]
/// - [allowColorChanging]: 是否允许气泡颜色随时间变化
/// - [bubbleMutationDurationSeconds]: 气泡变化动画持续时间（秒）
/// - [initialColors]: 气泡初始颜色列表
class FluidBackgroundConfig {
  /// 气泡移动速度，默认值1
  /// 值越大，气泡移动越快
  final double velocity;

  /// 气泡基础大小，默认值500
  /// 值越大，气泡越大
  final double bubblesSize;

  /// 气泡大小变化范围，默认值 [300, 600]
  /// 第一个元素为最小值，第二个元素为最大值
  /// 气泡大小会在该范围内随机变化
  final List<double> sizeChangingRange;

  /// 是否允许气泡颜色随时间变化，默认值 true
  /// 开启后气泡颜色会渐变过渡，产生更丰富的视觉效果
  final bool allowColorChanging;

  /// 气泡变化动画持续时间，默认值4秒
  /// 控制气泡大小和颜色变化的过渡动画时长
  final int bubbleMutationDurationSeconds;

  /// 气泡初始颜色列表
  ///
  /// 默认包含10种鲜艳的颜色，提供丰富的视觉层次:
  /// - 0xFF4D9EF0: 天蓝色
  /// - 0xFFA06CD5: 紫色
  /// - 0xFFF06292: 粉红色
  /// - 0xFF4DB6AC: 青绿色
  /// - 0xFFFFD54F: 金黄色
  /// - 0xFF81C784: 浅绿色
  /// - 0xFF4FC3F7: 浅蓝色
  /// - 0xFFFF8A65: 橙色
  /// - 0xFF9575CD: 淡紫色
  /// - 0xFF4DD0E1: 青色
  final List<Color> initialColors;

  /// 构造函数，所有参数均有默认值
  ///
  /// 默认颜色列表经过精心选择，确保视觉效果和谐且丰富。
  const FluidBackgroundConfig({
    this.velocity = 1,
    this.bubblesSize = 500,
    this.sizeChangingRange = const [300, 600],
    this.allowColorChanging = true,
    this.bubbleMutationDurationSeconds = 4,
    this.initialColors = const [
      Color(0xFF4D9EF0), // 天蓝色
      Color(0xFFA06CD5), // 紫色
      Color(0xFFF06292), // 粉红色
      Color(0xFF4DB6AC), // 青绿色
      // Color(0xFFFFD54F), // 金黄色
      // Color(0xFF81C784), // 浅绿色
      // Color(0xFF4FC3F7), // 浅蓝色
      // Color(0xFFFF8A65), // 橙色
      // Color(0xFF9575CD), // 淡紫色
      // Color(0xFF4DD0E1), // 青色
    ],
  });
}

/// 页面布局配置类
///
/// 该类定义了考试安排页面的所有布局参数，包括各组件的高度比例、
/// 宽度比例、内边距和间距等。所有比例值都是相对于屏幕尺寸的比值。
///
/// 配置参数说明:
/// - [bannerHeightRatio]: 横幅高度占屏幕高度的比例
/// - [messageCardMaxHeightRatio]: 消息卡片最大高度占屏幕高度的比例
/// - [clockTextWidthRatio]: 时钟文本宽度占屏幕宽度的比例
/// - [clockPaddingVerticalRatio]: 时钟垂直内边距占屏幕高度的比例
/// - [leftRightRatio]: 左右面板的宽度比例 [左, 右]
/// - [padding]: 页面整体内边距（像素）
/// - [spacing]: 组件之间的间距（像素）
class LayoutConfig {
  /// 横幅高度比例，默认值0.1（屏幕高度的10%）
  /// 横幅显示考试名称，高度不宜过大
  final double bannerHeightRatio;

  /// 消息卡片最大高度比例，默认值0.2（屏幕高度的20%）
  /// 消息卡片显示鼓励语，高度受限制以避免占用过多空间
  final double messageCardMaxHeightRatio;

  /// 时钟文本宽度比例，默认值0.4（屏幕宽度的40%）
  /// 用于计算时钟字体大小的自适应缩放
  final double clockTextWidthRatio;

  /// 时钟垂直内边距比例，默认值0.05（屏幕高度的5%）
  /// 控制时钟卡片上下的留白空间
  final double clockPaddingVerticalRatio;

  /// 左右面板的宽度比例，默认值 [5, 5]（等宽）
  /// 第一个元素为左侧面板比例，第二个为右侧面板比例
  /// 例如 [3, 7] 表示左:右 = 3:7
  final List<int> leftRightRatio;

  /// 页面整体内边距，默认值16像素
  /// 应用于 SafeArea 内的 Padding
  final double padding;

  /// 组件之间的间距，默认值8像素
  /// 用于各卡片之间、行之间的间距
  final double spacing;

  /// 构造函数，所有参数均有默认值
  const LayoutConfig({
    this.bannerHeightRatio = 0.1,
    this.messageCardMaxHeightRatio = 0.2,
    this.clockTextWidthRatio = 0.4,
    this.clockPaddingVerticalRatio = 0.05,
    this.leftRightRatio = const [5, 5],
    this.padding = 16,
    this.spacing = 8,
  });
}

/// 排版配置类
///
/// 该类定义了页面中所有文本组件的字体大小配置。
/// 所有字体大小以逻辑像素（logical pixels）为单位。
///
/// 配置参数说明:
/// - [bannerFontSize]: 横幅标题字体大小
/// - [messageFontSize]: 消息卡片字体大小（初始值，会自适应缩小）
/// - [messageMinFontSize]: 消息卡片最小字体大小（自适应下限）
/// - [clockFontSize]: 时钟字体大小（初始值，会自适应缩小）
/// - [subjectCardTitleFontSize]: 当前科目卡片标题字体大小
/// - [subjectCardDetailFontSize]: 当前科目卡片详情字体大小
/// - [scheduleHeaderFontSize]: 考试时间表表头字体大小
/// - [scheduleRowFontSize]: 考试时间表行字体大小
class TypographyConfig {
  /// 横幅标题字体大小，默认值30
  /// 显示考试名称，通常为页面最大的文本之一
  final double bannerFontSize;

  /// 消息卡片字体大小，默认值28
  /// 显示鼓励语，这是初始值，会根据可用空间自适应缩小
  final double messageFontSize;

  /// 消息卡片最小字体大小，默认值14
  /// 自适应缩小的下限值，防止文本过小无法阅读
  final double messageMinFontSize;

  /// 时钟字体大小，默认值64
  /// 显示当前时间，通常为页面最大的文本
  /// 这是初始值，会根据可用宽度自适应缩小
  final double clockFontSize;

  /// 当前科目卡片标题字体大小，默认值32
  /// 显示当前/下一个考试的科目名称
  final double subjectCardTitleFontSize;

  /// 当前科目卡片详情字体大小，默认值26
  /// 显示考试的开始/结束时间和剩余时间
  final double subjectCardDetailFontSize;

  /// 考试时间表表头字体大小，默认值24
  /// 显示"日期"、"开始时间"、"科目"等表头文本
  final double scheduleHeaderFontSize;

  /// 考试时间表行字体大小，默认值22
  /// 显示每场考试的日期、时间和科目名称
  final double scheduleRowFontSize;

  /// 构造函数，所有参数均有默认值
  const TypographyConfig({
    this.bannerFontSize = 48,
    this.messageFontSize = 28,
    this.messageMinFontSize = 18,
    this.clockFontSize = 128,
    this.subjectCardTitleFontSize = 32,
    this.subjectCardDetailFontSize = 26,
    this.scheduleHeaderFontSize = 42,
    this.scheduleRowFontSize = 38,
  });
}

/// UI总配置类
///
/// 该类是所有UI配置的顶层容器，聚合了以下子配置:
/// - [fontFamily]: 全局字体族名称
/// - [liquidGlass]: 液态玻璃效果配置
/// - [fluidBackground]: 流体动态背景配置
/// - [layout]: 页面布局配置
/// - [typography]: 排版字体大小配置
///
/// 使用方式:
/// ```dart
/// // 直接使用默认配置
/// final uiConfig = UiConfig();
///
/// // 访问子配置
/// final fontSize = uiConfig.typography.clockFontSize;
/// final padding = uiConfig.layout.padding;
/// ```
///
/// 所有配置值直接在此类及其子类中定义，无需外部JSON文件。
/// 修改默认值即可调整全局配置。
class UiConfig {
  /// 全局字体族名称，默认值 'Harmony'
  /// 应用于页面中所有文本组件的 fontFamily 属性
  final String fontFamily;

  /// 液态玻璃效果配置
  /// 控制所有 GlassCard、GlassPanel 等组件的视觉效果
  final LiquidGlassConfig liquidGlass;

  /// 流体动态背景配置
  /// 控制页面背景的气泡动画效果
  final FluidBackgroundConfig fluidBackground;

  /// 页面布局配置
  /// 控制各组件的尺寸比例、间距和内边距
  final LayoutConfig layout;

  /// 排版字体大小配置
  /// 控制所有文本组件的字体大小
  final TypographyConfig typography;

  /// 构造函数，所有参数均有默认值
  ///
  /// 默认配置产生和谐的视觉效果，适合大多数场景。
  /// 子配置对象使用 const 构造，确保默认值不可变。
  /// 修改此处的默认值即可全局调整UI配置。
  const UiConfig({
    this.fontFamily = 'MapleMono NF CN',
    this.liquidGlass = const LiquidGlassConfig(),
    this.fluidBackground = const FluidBackgroundConfig(),
    this.layout = const LayoutConfig(),
    this.typography = const TypographyConfig(),
  });
}
