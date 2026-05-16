import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:examschedulex/models/ui_config.dart';
import 'package:examschedulex/utils/time_utils.dart';
import 'package:fluid_background/fluid_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:path_provider/path_provider.dart';

import '../models/exam.dart';
import '../models/exam_config.dart';

class ExamScheduleHomePage extends StatefulWidget {
  const ExamScheduleHomePage({super.key});

  @override
  State<ExamScheduleHomePage> createState() => _ExamScheduleHomePageState();
}

class _ExamScheduleHomePageState extends State<ExamScheduleHomePage>
    with TickerProviderStateMixin {
  Timer? _timer;
  ExamConfig? _examConfig;
  UiConfig _uiConfig = const UiConfig();
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadConfigs();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  Future<void> _loadConfigs() async {
    final uiConfig = await UiConfig.load();
    ExamConfig? examConfig;
    String error = '';

    try {
      await Future.delayed(const Duration(milliseconds: 100));
      String path;
      if (Platform.isWindows) {
        path = 'C:\\esx\\exam_config.json';
      } else if (Platform.isLinux) {
        path = '/exam_config.json';
      } else if (Platform.isMacOS) {
        path = '/exam_config.json';
      } else {
        final directory = await getApplicationDocumentsDirectory();
        path = '${directory.path}/exam_config.json';
      }

      File file = File(path);
      if (await file.exists()) {
        final jsonString = await file.readAsString();
        final jsonData = json.decode(jsonString);
        examConfig = ExamConfig.fromJson(jsonData);
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final fallbackPath = '${directory.path}\\exam_config.json';
        file = File(fallbackPath);
        if (await file.exists()) {
          final jsonString = await file.readAsString();
          final jsonData = json.decode(jsonString);
          examConfig = ExamConfig.fromJson(jsonData);
        } else {
          error = '未找到考试配置文件';
        }
      }
    } on MissingPluginException {
      error = '插件初始化失败，请重启应用';
    } catch (e) {
      error = '加载考试配置失败: $e';
    }

    if (mounted) {
      setState(() {
        _uiConfig = uiConfig;
        _examConfig = examConfig;
        _errorMessage = error;
        _isLoading = false;
      });
    }
  }

  List<Exam> get _exams {
    if (_examConfig == null) return [];
    return _examConfig!.examInfos
        .map((info) => Exam(
              name: info.name,
              start: DateTime.parse(info.start),
              end: DateTime.parse(info.end),
              alertTime: info.alertTime,
            ))
        .toList();
  }

  List<Exam> get _currentExams {
    final now = DateTime.now();
    return _exams
        .where((exam) => exam.start.isBefore(now) && exam.end.isAfter(now))
        .toList();
  }

  Exam? _getCurrentOrNextExam() {
    final now = DateTime.now();
    for (final exam in _exams) {
      if (exam.start.isBefore(now) && exam.end.isAfter(now)) {
        return exam;
      }
    }
    Exam? nextExam;
    Duration? minDiff;
    for (final exam in _exams) {
      if (exam.start.isAfter(now)) {
        final diff = exam.start.difference(now);
        if (minDiff == null || diff < minDiff) {
          minDiff = diff;
          nextExam = exam;
        }
      }
    }
    return nextExam;
  }

  String _getRemainingTime(Exam exam) {
    final now = DateTime.now();
    if (now.isBefore(exam.start)) {
      final diff = exam.start.difference(now);
      return '距开始: ${diff.inHours.toString().padLeft(2, '0')}:${(diff.inMinutes % 60).toString().padLeft(2, '0')}:${(diff.inSeconds % 60).toString().padLeft(2, '0')}';
    } else if (now.isAfter(exam.end)) {
      return '已结束';
    } else {
      final diff = exam.end.difference(now);
      return '剩余: ${diff.inHours.toString().padLeft(2, '0')}:${(diff.inMinutes % 60).toString().padLeft(2, '0')}:${(diff.inSeconds % 60).toString().padLeft(2, '0')}';
    }
  }

  String _getExamStatus(Exam exam) {
    final now = DateTime.now();
    if (now.isBefore(exam.start)) {
      final diff = exam.start.difference(now);
      return diff.inMinutes <= 15 ? '即将开始' : '未开始';
    } else if (now.isAfter(exam.end)) {
      return '已结束';
    } else {
      return '考试中';
    }
  }

  LiquidGlassSettings _glassSettings() {
    final config = _uiConfig.liquidGlass;
    GlassSpecularSharpness sharpness;
    switch (config.specularSharpness) {
      case 'soft':
        sharpness = GlassSpecularSharpness.soft;
        break;
      case 'sharp':
        sharpness = GlassSpecularSharpness.sharp;
        break;
      default:
        sharpness = GlassSpecularSharpness.medium;
    }
    return LiquidGlassSettings(
      thickness: config.thickness,
      blur: config.blur,
      glassColor: config.glassColor,
      specularSharpness: sharpness,
      visibility: config.visibility,
      chromaticAberration: config.chromaticAberration,
      lightAngle: config.lightAngle,
      lightIntensity: config.lightIntensity,
      ambientStrength: config.ambientStrength,
      refractiveIndex: config.refractiveIndex,
      saturation: config.saturation,
    );
  }

  String _fontFamily() => _uiConfig.fontFamily;

  String _formatClockTime() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final layout = _uiConfig.layout;
    final typo = _uiConfig.typography;
    final font = _fontFamily();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : _errorMessage.isNotEmpty
              ? _buildErrorView(font)
              : Stack(
                  children: [
                    _buildFluidBackground(),
                    SafeArea(
                      child: Padding(
                        padding: EdgeInsets.all(layout.padding),
                        child: AdaptiveLiquidGlassLayer(
                          settings: _glassSettings(),
                          child: Column(
                            children: [
                              _buildBanner(screenHeight, typo, font),
                              SizedBox(height: layout.spacing),
                              Expanded(
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: layout.leftRightRatio[0],
                                      child: _buildLeftPanel(screenHeight,
                                          screenWidth, typo, layout, font),
                                    ),
                                    SizedBox(width: layout.spacing),
                                    Expanded(
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

  Widget _buildFluidBackground() {
    final fbConfig = _uiConfig.fluidBackground;
    return Positioned.fill(
      child: FluidBackground(
        initialColors: InitialColors.custom(
          fbConfig.initialColors,
        ),
        initialPositions: InitialOffsets.predefined(),
        velocity: fbConfig.velocity,
        bubblesSize: fbConfig.bubblesSize,
        sizeChangingRange: fbConfig.sizeChangingRange,
        allowColorChanging: fbConfig.allowColorChanging,
        bubbleMutationDuration:
            Duration(seconds: fbConfig.bubbleMutationDurationSeconds),
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _buildBanner(double screenHeight, TypographyConfig typo, String font) {
    return SizedBox(
      height: screenHeight * _uiConfig.layout.bannerHeightRatio,
      child: GlassCard(
        child: Center(
          child: Text(
            _examConfig?.examName ?? '考试安排',
            style: TextStyle(
              fontFamily: font,
              fontSize: typo.bannerFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeftPanel(
    double screenHeight,
    double screenWidth,
    TypographyConfig typo,
    LayoutConfig layout,
    String font,
  ) {
    final currentExam = _getCurrentOrNextExam();

    return Column(
      children: [
        _buildMessageCard(screenHeight, typo, layout, font),
        SizedBox(height: layout.spacing),
        _buildClockCard(screenHeight, screenWidth, typo, layout, font),
        SizedBox(height: layout.spacing),
        if (currentExam != null)
          _buildCurrentSubjectCard(currentExam, typo, layout, font),
      ],
    );
  }

  Widget _buildMessageCard(
    double screenHeight,
    TypographyConfig typo,
    LayoutConfig layout,
    String font,
  ) {
    final message = _examConfig?.message ?? '沉着应对，冷静答题。';
    final maxHeight = screenHeight * layout.messageCardMaxHeightRatio;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: GlassCard(
        child: Center(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth - 32;
                final availableHeight = constraints.maxHeight - 24;

                double fontSize = typo.messageFontSize;
                final textPainter = TextPainter(
                  text: TextSpan(
                    text: message,
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.center,
                );

                textPainter.layout(maxWidth: availableWidth.abs());

                while (textPainter.height > availableHeight &&
                    fontSize > typo.messageMinFontSize) {
                  fontSize -= 1;
                  textPainter.text = TextSpan(
                    text: message,
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                  textPainter.layout(maxWidth: availableWidth);
                }

                return Text(
                  message,
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: fontSize,
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

  double _calculateClockFontSize(
      double clockWidth, TypographyConfig typo, String font) {
    double fontSize = typo.clockFontSize;
    final timeStr = _formatClockTime();
    final textPainter = TextPainter(
      text: TextSpan(
        text: timeStr,
        style: TextStyle(
          fontFamily: font,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    while (textPainter.width > clockWidth && fontSize > 20) {
      fontSize -= 1;
      textPainter.text = TextSpan(
        text: timeStr,
        style: TextStyle(
          fontFamily: font,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );
      textPainter.layout();
    }
    return fontSize;
  }

  Widget _buildClockCard(
    double screenHeight,
    double screenWidth,
    TypographyConfig typo,
    LayoutConfig layout,
    String font,
  ) {
    final verticalPadding = screenHeight * layout.clockPaddingVerticalRatio;
    final clockWidth = screenWidth * layout.clockTextWidthRatio;
    final clockFontSize = _calculateClockFontSize(clockWidth, typo, font);

    return GlassCard(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        child: Center(
          child: Text(
            _formatClockTime(),
            style: TextStyle(
              fontFamily: font,
              fontSize: clockFontSize,
              fontWeight: FontWeight.bold,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentSubjectCard(
    Exam exam,
    TypographyConfig typo,
    LayoutConfig layout,
    String font,
  ) {
    final status = _getExamStatus(exam);
    final isOngoing = status == '考试中';
    final isUpcoming = status == '即将开始';

    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              exam.name,
              style: TextStyle(
                fontFamily: font,
                fontSize: typo.subjectCardTitleFontSize,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: layout.spacing),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '开始: ${TimeUtils.formatTime(exam.start)}',
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: typo.subjectCardDetailFontSize,
                  ),
                ),
                SizedBox(width: layout.spacing * 2),
                Text(
                  '结束: ${TimeUtils.formatTime(exam.end)}',
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: typo.subjectCardDetailFontSize,
                  ),
                ),
              ],
            ),
            SizedBox(height: layout.spacing),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _getRemainingTime(exam),
                  style: TextStyle(
                    fontFamily: font,
                    fontSize: typo.subjectCardDetailFontSize,
                    fontWeight: FontWeight.bold,
                    color: isOngoing
                        ? Colors.redAccent
                        : isUpcoming
                            ? Colors.orangeAccent
                            : null,
                  ),
                ),
                SizedBox(width: layout.spacing),
                _buildStatusChip(status, font),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, String font) {
    Color color;
    switch (status) {
      case '考试中':
        color = Colors.redAccent;
        break;
      case '即将开始':
        color = Colors.orangeAccent;
        break;
      case '未开始':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }
    return GlassChip(
      label: status,
      labelStyle: TextStyle(
        fontFamily: font,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }

  Widget _buildRightPanel(
      TypographyConfig typo, LayoutConfig layout, String font) {
    final exams = _exams;

    return GlassPanel(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '日期',
                    style: TextStyle(
                      fontFamily: font,
                      fontSize: typo.scheduleHeaderFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
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
          const GlassDivider(),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: exams.length,
              separatorBuilder: (_, __) => const GlassDivider(),
              itemBuilder: (context, index) {
                final exam = exams[index];
                final status = _getExamStatus(exam);
                final isActive = status == '考试中';
                return Container(
                  color: isActive
                      ? Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.1)
                      : Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12.0, vertical: 10.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${exam.start.month}/${exam.start.day}',
                            style: TextStyle(
                              fontFamily: font,
                              fontSize: typo.scheduleRowFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            TimeUtils.formatTime(exam.start),
                            style: TextStyle(
                              fontFamily: font,
                              fontSize: typo.scheduleRowFontSize,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            exam.name,
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

  Widget _buildErrorView(String font) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 60,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            style: TextStyle(
              fontFamily: font,
              color: Theme.of(context).colorScheme.error,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          GlassButton.custom(
            onTap: () {
              setState(() {
                _isLoading = true;
                _errorMessage = '';
              });
              _loadConfigs();
            },
            width: 120,
            height: 48,
            child: Text(
              '重新加载',
              style: TextStyle(fontFamily: font),
            ),
          ),
        ],
      ),
    );
  }
}
