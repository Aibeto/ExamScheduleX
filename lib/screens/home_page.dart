// ============================================================
// 文件: home_page.dart
// 描述: 考试安排应用的主页面组件
// 功能: 显示考试时间表、当前/下一个考试信息、系统时钟以及动态背景
// 依赖: fluid_background（动态背景）、liquid_glass_widgets（液态玻璃UI效果）
// ============================================================

// dart:async - 提供 Timer 定时器功能，用于每秒刷新页面
import 'dart:async';
// dart:convert - 提供 JSON 编解码功能，用于解析配置文件
import 'dart:convert';
// dart:io - 提供 Platform 平台检测和 File 文件操作功能
import 'dart:io';

// UI配置模型，包含布局、字体、液态玻璃效果等配置项
import 'package:examschedulex/models/ui_config.dart';
// 时间格式化工具类
import 'package:examschedulex/utils/time_utils.dart';
// 流体动态背景组件，提供气泡动画效果
import 'package:fluid_background/fluid_background.dart';
// Flutter 核心UI框架
import 'package:flutter/material.dart';
// 系统UI控制，如状态栏、导航栏模式设置
import 'package:flutter/services.dart';
// 液态玻璃风格UI组件库，提供 GlassCard、GlassPanel、GlassChip 等
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
// 路径提供者，用于获取应用文档目录等平台特定路径
import 'package:path_provider/path_provider.dart';

// 考试数据模型，包含考试名称、开始/结束时间、提醒时间
import '../models/exam.dart';
// 考试配置模型，包含考试名称、消息、考试信息列表
import '../models/exam_config.dart';

/// 考试安排主页组件
///
/// 该组件是应用的主入口页面，继承自 [StatefulWidget]，
/// 负责显示考试时间表、当前/下一个考试信息以及系统时钟。
/// 支持从配置文件加载考试数据和UI配置，并提供错误处理机制。
///
/// 页面结构:
/// - 顶部: 考试名称横幅（Banner）
/// - 左侧: 消息卡片 + 时钟卡片 + 当前科目卡片
/// - 右侧: 考试时间表列表
/// - 背景: 流体动态气泡背景
///
/// 使用示例:
/// ```dart
/// MaterialApp(
///   home: ExamScheduleHomePage(),
/// )
/// ```
class ExamScheduleHomePage extends StatefulWidget {
  /// 构造函数，使用 super.key 传递给父类
  const ExamScheduleHomePage({super.key});

  /// 创建状态对象，返回 [_ExamScheduleHomePageState] 实例
  @override
  State<ExamScheduleHomePage> createState() => _ExamScheduleHomePageState();
}

/// 考试安排主页的状态管理类
///
/// 负责管理考试配置、UI配置的加载，定时器更新以及页面构建逻辑。
/// 混入 [TickerProviderStateMixin] 以支持动画相关功能（虽然当前未直接使用动画，
/// 但保留以备将来扩展，如液态玻璃效果的过渡动画）。
class _ExamScheduleHomePageState extends State<ExamScheduleHomePage>
    with TickerProviderStateMixin {
  // ==================== 状态变量 ====================

  /// 每秒触发的定时器，用于刷新页面显示（时钟、考试倒计时等）
  Timer? _timer;

  /// 考试配置对象，包含考试名称、消息和考试信息列表
  /// 从 JSON 配置文件加载，加载失败时为 null
  ExamConfig? _examConfig;

  /// UI配置对象，包含布局、字体、液态玻璃效果、流体背景等配置
  /// 默认值为空配置，加载成功后更新
  UiConfig _uiConfig = const UiConfig();

  /// 是否正在加载配置文件
  /// 初始值为 true，加载完成后设为 false
  bool _isLoading = true;

  /// 错误信息字符串，为空表示无错误
  /// 可能的错误: "未找到考试配置文件"、"插件初始化失败"等
  String _errorMessage = '';

  // ==================== 生命周期方法 ====================

  /// 组件初始化时调用
  ///
  /// 执行以下操作:
  /// 1. 调用父类 initState 完成基础初始化
  /// 2. 调用 [_loadConfigs] 异步加载配置文件
  /// 3. 启动每秒触发的定时器，通过 setState 刷新页面
  ///    使用 mounted 检查确保组件仍然挂载，避免在 dispose 后调用 setState
  @override
  void initState() {
    super.initState();
    // 异步加载UI配置和考试配置
    _loadConfigs();
    // 启动每秒更新的定时器，用于刷新页面显示（如时钟、倒计时）
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      // 只有在组件仍然挂载时才调用 setState，避免内存泄漏
      if (mounted) setState(() {});
    });
  }

  /// 组件销毁时调用
  ///
  /// 执行以下清理操作:
  /// 1. 取消定时器，防止内存泄漏和在组件销毁后调用 setState
  /// 2. 恢复系统UI为边到边（edgeToEdge）模式
  /// 3. 调用父类 dispose 完成基础清理
  @override
  void dispose() {
    // 取消定时器，防止在组件销毁后继续触发回调
    _timer?.cancel();
    // 恢复系统UI模式为边到边显示（隐藏状态栏和导航栏）
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ==================== 配置加载 ====================

  /// 加载UI配置和考试配置文件
  ///
  /// 该方法为异步方法，执行以下流程:
  /// 1. 直接使用代码中定义的UI配置（const UiConfig()）
  /// 2. 根据平台确定考试配置文件路径:
  ///    - Windows: C:\esx\exam_config.json
  ///    - Linux/macOS: /exam_config.json
  ///    - 其他平台（移动端）: 应用文档目录/exam_config.json
  /// 3. 如果主路径文件不存在，尝试从应用文档目录加载备用配置文件
  /// 4. 如果备用路径也不存在，设置错误信息
  /// 5. 捕获 [MissingPluginException] 和其他异常，设置对应错误信息
  /// 6. 加载完成后通过 setState 更新状态以触发UI重建
  Future<void> _loadConfigs() async {
    // 直接使用代码中定义的UI配置（无需从JSON文件加载）
    const uiConfig = UiConfig();
    // 考试配置对象，加载成功后赋值
    ExamConfig? examConfig;
    // 错误信息，为空表示无错误
    String error = '';

    try {
      // 添加短暂延迟，确保平台通道初始化完成
      await Future.delayed(const Duration(milliseconds: 100));

      // 根据平台确定考试配置文件路径
      String path;
      if (Platform.isWindows) {
        // Windows平台: 使用 C:\esx\ 目录下的配置文件
        path = 'C:\\esx\\exam_config.json';
      } else if (Platform.isLinux) {
        // Linux平台: 使用根目录下的配置文件
        path = '/exam_config.json';
      } else if (Platform.isMacOS) {
        // macOS平台: 使用根目录下的配置文件
        path = '/exam_config.json';
      } else {
        // 移动端平台（Android/iOS）: 使用应用文档目录下的配置文件
        final directory = await getApplicationDocumentsDirectory();
        path = '${directory.path}/exam_config.json';
      }

      // 尝试从主路径读取配置文件
      File file = File(path);
      if (await file.exists()) {
        // 主路径文件存在，读取并解析JSON
        final jsonString = await file.readAsString();
        final jsonData = json.decode(jsonString);
        // 将JSON数据转换为ExamConfig对象
        examConfig = ExamConfig.fromJson(jsonData);
      } else {
        // 主路径文件不存在，尝试备用路径（应用文档目录）
        final directory = await getApplicationDocumentsDirectory();
        // 注意: 这里使用反斜杠作为路径分隔符，适用于Windows
        final fallbackPath = '${directory.path}\\exam_config.json';
        file = File(fallbackPath);
        if (await file.exists()) {
          // 备用路径文件存在，读取并解析JSON
          final jsonString = await file.readAsString();
          final jsonData = json.decode(jsonString);
          examConfig = ExamConfig.fromJson(jsonData);
        } else {
          // 主路径和备用路径都不存在，设置错误信息
          error = '未找到考试配置文件';
        }
      }
    } on MissingPluginException {
      // 插件初始化失败，通常发生在平台通道未正确注册时
      error = '插件初始化失败，请重启应用';
    } catch (e) {
      // 其他异常（文件格式错误、权限不足等）
      error = '加载考试配置失败: $e';
    }

    // 确保组件仍然挂载后再更新状态，避免在 dispose 后调用 setState
    if (mounted) {
      setState(() {
        _uiConfig = uiConfig; // 更新UI配置
        _examConfig = examConfig; // 更新考试配置
        _errorMessage = error; // 更新错误信息
        _isLoading = false; // 标记加载完成
      });
    }
  }

  // ==================== 数据获取 ====================

  /// 获取所有考试列表
  ///
  /// 将配置中的考试信息（ExamInfo）转换为 Exam 对象列表。
  /// ExamInfo 包含字符串格式的时间，Exam 包含 DateTime 格式的时间。
  ///
  /// 如果 [_examConfig] 为 null（配置未加载），返回空列表。
  List<Exam> get _exams {
    if (_examConfig == null) return [];
    // 遍历考试信息列表，将每个 ExamInfo 转换为 Exam 对象
    return _examConfig!.examInfos
        .map((info) => Exam(
              name: info.name, // 考试名称
              start: DateTime.parse(info.start), // 开始时间字符串转DateTime
              end: DateTime.parse(info.end), // 结束时间字符串转DateTime
              alertTime: info.alertTime, // 提醒时间（分钟）
            ))
        .toList();
  }

  /// 获取当前正在进行的考试列表
  ///
  /// 返回当前时间处于考试开始和结束时间之间的所有考试。
  /// 判断条件: 当前时间 > 考试开始时间 且 当前时间 < 考试结束时间
  List<Exam> get _currentExams {
    final now = DateTime.now();
    return _exams
        .where((exam) => exam.start.isBefore(now) && exam.end.isAfter(now))
        .toList();
  }

  /// 获取当前或下一个即将开始的考试
  ///
  /// 查找逻辑:
  /// 1. 首先遍历所有考试，查找当前正在进行的考试（开始时间 < 当前时间 < 结束时间）
  /// 2. 如果没有正在进行的考试，查找最近的未来考试（开始时间 > 当前时间）
  ///    通过比较时间差找到最近的那个
  /// 3. 如果既没有正在进行的考试也没有未来考试，返回 null
  ///
  /// 返回:
  ///   当前正在进行的考试或最近的未来考试，如果没有则返回 null
  Exam? _getCurrentOrNextExam() {
    final now = DateTime.now();

    // 第一轮遍历: 查找正在进行的考试
    for (final exam in _exams) {
      if (exam.start.isBefore(now) && exam.end.isAfter(now)) {
        return exam; // 找到正在进行的考试，直接返回
      }
    }

    // 第二轮遍历: 查找最近的未来考试
    Exam? nextExam; // 最近的未来考试
    Duration? minDiff; // 最小时间差
    for (final exam in _exams) {
      if (exam.start.isAfter(now)) {
        // 考试尚未开始
        final diff = exam.start.difference(now);
        if (minDiff == null || diff < minDiff) {
          // 找到更近的考试，更新记录
          minDiff = diff;
          nextExam = exam;
        }
      }
    }
    return nextExam; // 可能为 null（没有未来考试）
  }

  // ==================== 时间与状态计算 ====================

  /// 获取考试剩余时间或距开始时间的格式化字符串
  ///
  /// 根据当前时间与考试时间的关系，返回相应的格式化时间字符串:
  /// - 当前时间 < 考试开始时间: 返回 "距开始: HH:MM:SS" 格式
  /// - 当前时间 > 考试结束时间: 返回 "已结束"
  /// - 当前时间在考试期间: 返回 "剩余: HH:MM:SS" 格式
  ///
  /// 时间格式说明:
  /// - HH: 两位小时数（00-99），使用 padLeft(2, '0') 补零
  /// - MM: 两位分钟数（00-59），使用 inMinutes % 60 获取
  /// - SS: 两位秒数（00-59），使用 inSeconds % 60 获取
  ///
  /// 参数:
  ///   [exam] - 要计算时间的考试对象
  ///
  /// 返回:
  ///   格式化的时间字符串，如"剩余: 01:30:45"或"距开始: 02:15:30"
  String _getRemainingTime(Exam exam) {
    final now = DateTime.now();
    if (now.isBefore(exam.start)) {
      // 考试尚未开始，计算距开始时间的差值
      final diff = exam.start.difference(now);
      return '距开始: ${diff.inHours.toString().padLeft(2, '0')}:${(diff.inMinutes % 60).toString().padLeft(2, '0')}:${(diff.inSeconds % 60).toString().padLeft(2, '0')}';
    } else if (now.isAfter(exam.end)) {
      // 考试已结束
      return '已结束';
    } else {
      // 考试进行中，计算剩余时间
      final diff = exam.end.difference(now);
      return '剩余: ${diff.inHours.toString().padLeft(2, '0')}:${(diff.inMinutes % 60).toString().padLeft(2, '0')}:${(diff.inSeconds % 60).toString().padLeft(2, '0')}';
    }
  }

  /// 获取考试状态字符串
  ///
  /// 根据当前时间与考试时间的关系，返回考试状态:
  /// - "未开始": 考试开始时间在当前时间之后，且距开始超过15分钟
  /// - "即将开始": 考试开始时间在当前时间之后，且距开始不超过15分钟
  /// - "考试中": 当前时间处于考试开始和结束时间之间
  /// - "已结束": 当前时间在考试结束时间之后
  ///
  /// 参数:
  ///   [exam] - 要检查状态的考试对象
  ///
  /// 返回:
  ///   考试状态字符串："未开始"、"即将开始"、"考试中"或"已结束"
  String _getExamStatus(Exam exam) {
    final now = DateTime.now();
    if (now.isBefore(exam.start)) {
      // 考试尚未开始
      final diff = exam.start.difference(now);
      // 15分钟内视为"即将开始"
      return diff.inMinutes <= 15 ? '即将开始' : '未开始';
    } else if (now.isAfter(exam.end)) {
      // 考试已结束
      return '已结束';
    } else {
      // 考试正在进行中
      return '考试中';
    }
  }

  // ==================== UI配置辅助方法 ====================

  /// 构建液态玻璃效果设置
  ///
  /// 根据UI配置中的 liquidGlass 设置创建 [LiquidGlassSettings] 对象。
  /// 液态玻璃效果包含以下可配置参数:
  /// - thickness: 玻璃厚度，影响折射和反射效果
  /// - blur: 模糊程度，影响背景模糊强度
  /// - glassColor: 玻璃颜色，叠加在背景上的色调
  /// - specularSharpness: 高光锐度，控制高光的柔和/锐利程度
  /// - visibility: 可见度，控制玻璃效果的透明程度
  /// - chromaticAberration: 色差，模拟光线折射产生的色彩偏移
  /// - lightAngle: 光照角度，影响高光位置
  /// - lightIntensity: 光照强度，影响高光亮度
  /// - ambientStrength: 环境光强度，影响整体亮度
  /// - refractiveIndex: 折射率，影响背景扭曲程度
  /// - saturation: 饱和度，影响背景色彩的鲜艳程度
  LiquidGlassSettings _glassSettings() {
    final config = _uiConfig.liquidGlass;

    // 将字符串配置转换为枚举值
    GlassSpecularSharpness sharpness;
    switch (config.specularSharpness) {
      case 'soft':
        // 柔和高光，产生更自然的玻璃效果
        sharpness = GlassSpecularSharpness.soft;
        break;
      case 'sharp':
        // 锐利高光，产生更明显的镜面反射效果
        sharpness = GlassSpecularSharpness.sharp;
        break;
      default:
        // 中等高光，平衡柔和与锐利
        sharpness = GlassSpecularSharpness.medium;
    }

    return LiquidGlassSettings(
      thickness: config.thickness, // 玻璃厚度
      blur: config.blur, // 模糊程度
      glassColor: config.glassColor, // 玻璃颜色
      specularSharpness: sharpness, // 高光锐度
      visibility: config.visibility, // 可见度
      chromaticAberration: config.chromaticAberration, // 色差
      lightAngle: config.lightAngle, // 光照角度
      lightIntensity: config.lightIntensity, // 光照强度
      ambientStrength: config.ambientStrength, // 环境光强度
      refractiveIndex: config.refractiveIndex, // 折射率
      saturation: config.saturation, // 饱和度
    );
  }

  /// 获取当前UI配置的字体族名称
  ///
  /// 返回 [_uiConfig.fontFamily] 中配置的字体族名称，
  /// 用于所有文本组件的 fontFamily 属性。
  String _fontFamily() => _uiConfig.fontFamily;

  /// 格式化当前系统时间用于时钟显示
  ///
  /// 获取当前系统时间并格式化为 "HH:mm:ss" 格式的24小时制时间字符串。
  /// 使用 padLeft(2, '0') 确保每位数都有前导零。
  ///
  /// 返回示例: "09:05:03"、"14:30:45"、"23:59:59"
  String _formatClockTime() {
    final now = DateTime.now();
    // 小时: 0-23，补零到两位
    // 分钟: 0-59，补零到两位
    // 秒: 0-59，补零到两位
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  // ==================== 页面构建 ====================

  /// 构建页面主框架
  ///
  /// 页面布局结构:
  /// ```
  /// Scaffold
  /// └── body (根据状态显示不同内容)
  ///     ├── 加载中 → CircularProgressIndicator
  ///     ├── 有错误 → _buildErrorView
  ///     └── 正常 → Stack
  ///         ├── _buildFluidBackground (流体动态背景)
  ///         └── SafeArea + Padding + AdaptiveLiquidGlassLayer
  ///             └── Column
  ///                 ├── _buildBanner (考试名称横幅)
  ///                 └── Expanded Row
  ///                     ├── _buildLeftPanel (左侧面板)
  ///                     └── _buildRightPanel (右侧面板)
  /// ```
  @override
  Widget build(BuildContext context) {
    // 获取屏幕高度，用于响应式布局计算
    final screenHeight = MediaQuery.of(context).size.height;
    // 获取屏幕宽度，用于响应式布局计算
    final screenWidth = MediaQuery.of(context).size.width;
    // 获取布局配置（间距、比例等）
    final layout = _uiConfig.layout;
    // 获取排版配置（字体大小等）
    final typo = _uiConfig.typography;
    // 获取字体族名称
    final font = _fontFamily();

    return Scaffold(
      // 禁止键盘弹出时调整视图大小，保持布局稳定
      resizeToAvoidBottomInset: false,
      body: _isLoading
          // 加载中状态: 显示居中的进度指示器
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : _errorMessage.isNotEmpty
              // 错误状态: 显示错误信息视图
              ? _buildErrorView(font)
              // 正常状态: 显示主内容
              : Stack(
                  children: [
                    // 底层: 流体动态背景
                    _buildFluidBackground(),
                    // 上层: 主内容区域
                    SafeArea(
                      // 使用配置的间距作为整体内边距
                      child: Padding(
                        padding: EdgeInsets.all(layout.padding),
                        // 液态玻璃效果层，包裹所有内容卡片
                        child: AdaptiveLiquidGlassLayer(
                          settings: _glassSettings(),
                          child: Column(
                            children: [
                              // 顶部横幅: 显示考试名称
                              _buildBanner(screenHeight, typo, font),
                              // 横幅与内容之间的间距
                              SizedBox(height: layout.spacing),
                              // 主内容区域: 左右两栏布局
                              Expanded(
                                child: Row(
                                  children: [
                                    // 左侧面板: 消息 + 时钟 + 当前科目
                                    Expanded(
                                      // 左侧占比由配置的 leftRightRatio[0] 决定
                                      flex: layout.leftRightRatio[0],
                                      child: _buildLeftPanel(screenHeight,
                                          screenWidth, typo, layout, font),
                                    ),
                                    // 左右面板之间的间距
                                    SizedBox(width: layout.spacing),
                                    // 右侧面板: 考试时间表
                                    Expanded(
                                      // 右侧占比由配置的 leftRightRatio[1] 决定
                                      flex: layout.leftRightRatio[1],
                                      child:
                                          _buildRightPanel(typo, layout, font),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  // ==================== 背景构建 ====================

  /// 构建流体动态背景
  ///
  /// 使用 [FluidBackground] 组件创建带有气泡动画的动态背景效果。
  /// 背景配置包括:
  /// - initialColors: 气泡初始颜色列表
  /// - initialPositions: 气泡初始位置（使用预定义位置）
  /// - velocity: 气泡移动速度
  /// - bubblesSize: 气泡大小
  /// - sizeChangingRange: 气泡大小变化范围
  /// - allowColorChanging: 是否允许气泡颜色变化
  /// - bubbleMutationDuration: 气泡变化动画持续时间
  ///
  /// 使用 [Positioned.fill] 使背景填满整个屏幕。
  Widget _buildFluidBackground() {
    final fbConfig = _uiConfig.fluidBackground;
    return Positioned.fill(
      child: FluidBackground(
        // 使用自定义颜色列表初始化气泡颜色
        initialColors: InitialColors.custom(
          fbConfig.initialColors,
        ),
        // 使用预定义的初始位置偏移
        initialPositions: InitialOffsets.predefined(),
        // 气泡移动速度
        velocity: fbConfig.velocity,
        // 气泡大小
        bubblesSize: fbConfig.bubblesSize,
        // 气泡大小变化范围
        sizeChangingRange: fbConfig.sizeChangingRange,
        // 是否允许气泡颜色随时间变化
        allowColorChanging: fbConfig.allowColorChanging,
        // 气泡变化动画持续时间
        bubbleMutationDuration:
            Duration(seconds: fbConfig.bubbleMutationDurationSeconds),
        // 子组件为空，仅作为背景
        child: const SizedBox.expand(),
      ),
    );
  }

  // ==================== 横幅构建 ====================

  /// 构建顶部考试名称横幅
  ///
  /// 横幅高度由配置的 bannerHeightRatio 与屏幕高度的乘积决定。
  /// 使用 [GlassCard] 包裹，显示考试名称或默认文本"考试安排"。
  ///
  /// 参数:
  ///   [screenHeight] - 屏幕高度，用于计算横幅高度
  ///   [typo] - 排版配置，包含横幅字体大小
  ///   [font] - 字体族名称
  Widget _buildBanner(double screenHeight, TypographyConfig typo, String font) {
    return SizedBox(
      // 横幅高度 = 屏幕高度 × 横幅高度比例
      height: screenHeight * _uiConfig.layout.bannerHeightRatio,
      child: GlassCard(
        child: Center(
          child: Text(
            // 显示考试名称，如果未配置则显示默认文本
            _examConfig?.examName ?? '考试安排',
            style: TextStyle(
              fontFamily: font,
              fontSize: typo.bannerFontSize, // 横幅字体大小
              fontWeight: FontWeight.bold, // 粗体
            ),
          ),
        ),
      ),
    );
  }

  // ==================== 左侧面板构建 ====================

  /// 构建左侧面板
  ///
  /// 左侧面板为垂直布局，包含以下组件:
  /// 1. 消息卡片 - 显示鼓励语或自定义消息
  /// 2. 时钟卡片 - 显示当前系统时间
  /// 3. 当前科目卡片 - 显示当前/下一个考试的详细信息（条件显示）
  ///
  /// 参数:
  ///   [screenHeight] - 屏幕高度，用于响应式布局
  ///   [screenWidth] - 屏幕宽度，用于响应式布局
  ///   [typo] - 排版配置
  ///   [layout] - 布局配置
  ///   [font] - 字体族名称
  Widget _buildLeftPanel(
    double screenHeight,
    double screenWidth,
    TypographyConfig typo,
    LayoutConfig layout,
    String font,
  ) {
    // 获取当前或下一个考试
    final currentExam = _getCurrentOrNextExam();

    return Column(
      children: [
        // 消息卡片: 显示鼓励语
        _buildMessageCard(screenHeight, typo, layout, font),
        // 消息卡片与时钟卡片之间的间距
        SizedBox(height: layout.spacing),
        // 时钟卡片: 显示当前时间
        _buildClockCard(screenHeight, screenWidth, typo, layout, font),
        // 时钟卡片与当前科目卡片之间的间距
        SizedBox(height: layout.spacing),
        // 当前科目卡片: 仅在有考试时显示
        if (currentExam != null)
          _buildCurrentSubjectCard(currentExam, typo, layout, font),
      ],
    );
  }

  /// 构建消息卡片
  ///
  /// 消息卡片显示鼓励语或自定义消息文本。
  /// 使用 [LayoutBuilder] 和 [TextPainter] 实现自适应字体大小:
  /// - 从配置的初始字体大小开始
  /// - 如果文本高度超出可用空间，逐步减小字体大小
  /// - 直到文本适合可用空间或达到最小字体大小
  ///
  /// 卡片高度受 messageCardMaxHeightRatio 配置限制。
  ///
  /// 参数:
  ///   [screenHeight] - 屏幕高度，用于计算最大高度
  ///   [typo] - 排版配置，包含字体大小范围
  ///   [layout] - 布局配置，包含高度比例
  ///   [font] - 字体族名称
  Widget _buildMessageCard(
    double screenHeight,
    TypographyConfig typo,
    LayoutConfig layout,
    String font,
  ) {
    // 获取消息文本，如果未配置则使用默认鼓励语
    final message = _examConfig?.message ?? '沉着应对，冷静答题。';
    // 计算消息卡片的最大高度
    final maxHeight = screenHeight * layout.messageCardMaxHeightRatio;

    return ConstrainedBox(
      // 限制卡片最大高度
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: GlassCard(
        child: Center(
          child: Padding(
            // 水平和垂直内边距
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            // 使用 LayoutBuilder 获取实际可用空间
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 计算可用宽度（减去水平内边距 16×2=32）
                final availableWidth = constraints.maxWidth - 32;
                // 计算可用高度（减去垂直内边距 12×2=24）
                final availableHeight = constraints.maxHeight - 24;

                // 从配置的初始字体大小开始
                double fontSize = typo.messageFontSize;
                // 创建 TextPainter 用于测量文本尺寸
                final textPainter = TextPainter(
                  text: TextSpan(
                    text: message,
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  textDirection: TextDirection.ltr, // 从左到右文本方向
                  textAlign: TextAlign.center, // 居中对齐
                );

                // 首次布局，使用可用宽度约束
                textPainter.layout(maxWidth: availableWidth.abs());

                // 自适应字体大小循环:
                // 如果文本高度超出可用高度且字体大小未达到最小值，继续缩小
                while (textPainter.height > availableHeight &&
                    fontSize > typo.messageMinFontSize) {
                  fontSize -= 1; // 每次减小1号字体
                  // 更新 TextPainter 的文本样式
                  textPainter.text = TextSpan(
                    text: message,
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                  // 重新布局测量
                  textPainter.layout(maxWidth: availableWidth);
                }

                // 使用计算后的字体大小显示文本
                return Text(
                  message,
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: fontSize, // 自适应后的字体大小
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// 计算时钟显示的最佳字体大小
  ///
  /// 使用 [TextPainter] 测量时钟文本的实际渲染宽度，
  /// 如果超出可用宽度则逐步减小字体大小，直到适合或达到最小值20。
  ///
  /// 使用 [FontFeature.tabularFigures] 确保数字等宽，
  /// 防止时钟数字切换时文本宽度变化导致抖动。
  ///
  /// 参数:
  ///   [clockWidth] - 时钟文本可用宽度
  ///   [typo] - 排版配置，包含初始时钟字体大小
  ///   [font] - 字体族名称
  ///
  /// 返回:
  ///   适合可用宽度的字体大小
  double _calculateClockFontSize(
      double clockWidth, TypographyConfig typo, String font) {
    // 从配置的时钟字体大小开始
    double fontSize = typo.clockFontSize;
    // 获取当前时间字符串用于测量
    final timeStr = _formatClockTime();
    // 创建 TextPainter 用于测量文本宽度
    final textPainter = TextPainter(
      text: TextSpan(
        text: timeStr,
        style: TextStyle(
          fontFamily: font,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          // 使用等宽数字特性，防止数字宽度不一致导致时钟抖动
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    // 首次布局测量
    textPainter.layout();

    // 自适应字体大小循环:
    // 如果文本宽度超出可用宽度且字体大小大于20，继续缩小
    while (textPainter.width > clockWidth && fontSize > 20) {
      fontSize -= 1; // 每次减小1号字体
      // 更新 TextPainter 的文本样式
      textPainter.text = TextSpan(
        text: timeStr,
        style: TextStyle(
          fontFamily: font,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );
      // 重新布局测量
      textPainter.layout();
    }
    return fontSize; // 返回计算后的字体大小
  }

  /// 构建时钟卡片
  ///
  /// 时钟卡片显示当前系统时间，格式为 "HH:mm:ss"。
  /// 使用自适应字体大小确保时钟文本适合可用宽度。
  /// 垂直内边距根据屏幕高度和配置比例计算。
  ///
  /// 参数:
  ///   [screenHeight] - 屏幕高度，用于计算垂直内边距
  ///   [screenWidth] - 屏幕宽度，用于计算时钟文本宽度
  ///   [typo] - 排版配置
  ///   [layout] - 布局配置
  ///   [font] - 字体族名称
  Widget _buildClockCard(
    double screenHeight,
    double screenWidth,
    TypographyConfig typo,
    LayoutConfig layout,
    String font,
  ) {
    // 计算时钟卡片的垂直内边距
    final verticalPadding = screenHeight * layout.clockPaddingVerticalRatio;
    // 计算时钟文本的可用宽度
    final clockWidth = screenWidth * layout.clockTextWidthRatio;
    // 计算适合可用宽度的字体大小
    final clockFontSize = _calculateClockFontSize(clockWidth, typo, font);

    return GlassCard(
      child: Padding(
        // 仅设置垂直内边距，水平由卡片自身处理
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        child: Center(
          child: Text(
            _formatClockTime(), // 格式化的当前时间
            style: TextStyle(
              fontFamily: font,
              fontSize: clockFontSize, // 自适应后的字体大小
              fontWeight: FontWeight.bold,
              // 使用等宽数字特性，防止时钟数字切换时宽度抖动
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== 当前科目卡片构建 ====================

  /// 构建当前科目卡片
  ///
  /// 显示当前/下一个考试的详细信息，包括:
  /// - 考试名称（标题）
  /// - 开始时间和结束时间（详情行）
  /// - 剩余时间/距开始时间（带颜色高亮）
  /// - 考试状态标签（GlassChip）
  ///
  /// 颜色规则:
  /// - 考试中: 红色（Colors.redAccent）- 表示紧急
  /// - 即将开始: 橙色（Colors.orangeAccent）- 表示警告
  /// - 其他: 默认颜色
  ///
  /// 参数:
  ///   [exam] - 要显示的考试对象
  ///   [typo] - 排版配置
  ///   [layout] - 布局配置
  ///   [font] - 字体族名称
  Widget _buildCurrentSubjectCard(
    Exam exam,
    TypographyConfig typo,
    LayoutConfig layout,
    String font,
  ) {
    // 获取考试状态
    final status = _getExamStatus(exam);
    // 判断是否正在进行中
    final isOngoing = status == '考试中';
    // 判断是否即将开始
    final isUpcoming = status == '即将开始';

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center, // 水平居中对齐
          children: [
            // 考试名称标题
            Text(
              exam.name,
              style: TextStyle(
                fontFamily: font,
                fontSize: typo.subjectCardTitleFontSize, // 科目卡片标题字体大小
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            // 标题与详情之间的间距
            SizedBox(height: layout.spacing),
            // 开始/结束时间行
            Row(
              mainAxisAlignment: MainAxisAlignment.center, // 水平居中
              children: [
                // 开始时间
                Text(
                  '开始: ${TimeUtils.formatTime(exam.start)}',
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: typo.subjectCardDetailFontSize, // 详情字体大小
                  ),
                ),
                // 开始与结束时间之间的间距
                SizedBox(width: layout.spacing * 2),
                // 结束时间
                Text(
                  '结束: ${TimeUtils.formatTime(exam.end)}',
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: typo.subjectCardDetailFontSize,
                  ),
                ),
              ],
            ),
            // 时间行与状态行之间的间距
            SizedBox(height: layout.spacing),
            // 剩余时间与状态标签行
            Row(
              mainAxisAlignment: MainAxisAlignment.center, // 水平居中
              children: [
                // 剩余时间/距开始时间
                Text(
                  _getRemainingTime(exam),
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: typo.subjectCardDetailFontSize,
                    fontWeight: FontWeight.bold,
                    // 根据考试状态设置颜色
                    color: isOngoing
                        ? Colors.redAccent // 考试中: 红色，表示紧急
                        : isUpcoming
                            ? Colors.orangeAccent // 即将开始: 橙色，表示警告
                            : null, // 其他: 使用默认颜色
                  ),
                ),
                // 剩余时间与状态标签之间的间距
                SizedBox(width: layout.spacing),
                // 考试状态标签
                _buildStatusChip(status, font),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建考试状态标签
  ///
  /// 使用 [GlassChip] 组件显示考试状态，不同状态对应不同颜色:
  /// - "考试中": 红色（Colors.redAccent）- 表示正在考试，需要关注
  /// - "即将开始": 橙色（Colors.orangeAccent）- 表示即将开考，需要准备
  /// - "未开始": 蓝色（Colors.blue）- 表示尚未开始，正常状态
  /// - 其他（"已结束"等）: 灰色（Colors.grey）- 表示已过去
  ///
  /// 参数:
  ///   [status] - 考试状态字符串
  ///   [font] - 字体族名称
  Widget _buildStatusChip(String status, String font) {
    // 根据状态确定标签颜色
    Color color;
    switch (status) {
      case '考试中':
        color = Colors.redAccent; // 红色: 正在考试
        break;
      case '即将开始':
        color = Colors.orangeAccent; // 橙色: 即将开考
        break;
      case '未开始':
        color = Colors.blue; // 蓝色: 尚未开始
        break;
      default:
        color = Colors.grey; // 灰色: 已结束或其他状态
    }
    return GlassChip(
      label: status, // 状态文本
      labelStyle: TextStyle(
        fontFamily: font,
        fontSize: 16, // 标签字体大小
        fontWeight: FontWeight.bold,
        color: color, // 状态对应的颜色
      ),
    );
  }

  // ==================== 右侧面板构建 ====================

  /// 构建右侧面板 - 考试时间表
  ///
  /// 右侧面板使用 [GlassPanel] 包裹，包含:
  /// - 表头行: "日期" | "开始时间" | "科目" 三列等宽布局
  /// - 分隔线: [GlassDivider]
  /// - 考试列表: [ListView.separated] 显示所有考试信息
  ///
  /// 参数:
  ///   [typo] - 排版配置
  ///   [layout] - 布局配置
  ///   [font] - 字体族名称
  Widget _buildRightPanel(
      TypographyConfig typo, LayoutConfig layout, String font) {
    // 获取所有考试列表
    final exams = _exams;

    return GlassPanel(
      child: Column(
        children: [
          // 表头行: 日期、开始时间、科目
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // 日期列
                Expanded(
                  child: Text(
                    '日期',
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: typo.scheduleHeaderFontSize, // 表头字体大小
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // 开始时间列
                Expanded(
                  child: Text(
                    '开始时间',
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: typo.scheduleHeaderFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                // 科目列
                Expanded(
                  child: Text(
                    '科目',
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: typo.scheduleHeaderFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // 表头与列表之间的分隔线
          const GlassDivider(),
          // 考试列表（可滚动）
          Expanded(
            child: ListView.separated(
              // 无额外内边距
              padding: EdgeInsets.zero,
              // 列表项数量 = 考试总数
              itemCount: exams.length,
              // 列表项之间的分隔线
              separatorBuilder: (context, index) => const GlassDivider(),
              // 构建每个考试列表项
              itemBuilder: (context, index) {
                // 获取当前索引的考试对象
                final exam = exams[index];
                // 获取考试状态
                final status = _getExamStatus(exam);
                // 判断是否为正在进行的考试（用于高亮显示）
                final isActive = status == '考试中';
                return Container(
                  // 正在进行的考试使用主题色半透明背景高亮，其他考试透明
                  color: isActive
                      ? Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1) // 10%透明度的主题色
                      : Colors.transparent, // 透明背景
                  child: Padding(
                    // 水平和垂直内边距
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 10.0),
                    child: Row(
                      children: [
                        // 日期列: 显示 "月/日" 格式
                        Expanded(
                          child: Text(
                            // 格式: 月/日，如 "6/15"、"12/3"
                            '${exam.start.month}/${exam.start.day}',
                            style: TextStyle(
                              fontFamily: font,
                              fontSize: typo.scheduleRowFontSize, // 列表行字体大小
                              fontWeight: FontWeight.bold, // 日期加粗显示
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        // 开始时间列
                        Expanded(
                          child: Text(
                            // 使用 TimeUtils 格式化开始时间
                            TimeUtils.formatTime(exam.start),
                            style: TextStyle(
                              fontFamily: font,
                              fontSize: typo.scheduleRowFontSize,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        // 科目名称列
                        Expanded(
                          child: Text(
                            exam.name, // 考试科目名称
                            style: TextStyle(
                              fontFamily: font,
                              fontSize: typo.scheduleRowFontSize,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 错误视图构建 ====================

  /// 构建错误信息视图
  ///
  /// 当配置文件加载失败时显示此视图，包含:
  /// - 错误图标: 红色感叹号图标
  /// - 错误信息: 显示具体的错误描述文本
  /// - 重新加载按钮: 点击后重新尝试加载配置文件
  ///
  /// 重新加载逻辑:
  /// 1. 将 _isLoading 设为 true，显示加载指示器
  /// 2. 清空 _errorMessage
  /// 3. 调用 [_loadConfigs] 重新加载配置
  ///
  /// 参数:
  ///   [font] - 字体族名称
  Widget _buildErrorView(String font) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // 垂直居中
        children: [
          // 错误图标: 红色感叹号
          Icon(
            Icons.error_outline, // 错误轮廓图标
            size: 60, // 图标大小
            color: Theme.of(context).colorScheme.error, // 使用主题错误色
          ),
          // 图标与文本之间的间距
          const SizedBox(height: 16),
          // 错误信息文本
          Text(
            _errorMessage, // 具体的错误描述
            style: TextStyle(
              fontFamily: font,
              color: Theme.of(context).colorScheme.error, // 使用主题错误色
              fontSize: 18, // 错误信息字体大小
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          // 文本与按钮之间的间距
          const SizedBox(height: 16),
          // 重新加载按钮
          GlassButton.custom(
            // 点击事件: 重新加载配置
            onTap: () {
              setState(() {
                _isLoading = true; // 重新显示加载状态
                _errorMessage = ''; // 清空错误信息
              });
              _loadConfigs(); // 重新加载配置文件
            },
            width: 120, // 按钮宽度
            height: 48, // 按钮高度
            child: Text(
              '重新加载', // 按钮文本
              style: TextStyle(fontFamily: font),
            ),
          ),
        ],
      ),
    );
  }
}
