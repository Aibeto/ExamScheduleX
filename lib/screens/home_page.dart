// ignore_for_file: deprecated_member_use, avoid_print

import 'package:examschedulex/utils/time_utils.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../models/exam.dart';
import '../models/exam_config.dart';
import '../widgets/exam_row.dart';

class ExamScheduleHomePage extends StatefulWidget {
  const ExamScheduleHomePage({super.key});

  @override
  State<ExamScheduleHomePage> createState() => _ExamScheduleHomePageState();
}

class _ExamScheduleHomePageState extends State<ExamScheduleHomePage> with TickerProviderStateMixin {
  // 添加Timer用于更新时间
  Timer? _timer;
  // 添加动画控制器
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  // 添加提醒对话框相关的状态
  // bool _showReminder = false;
  // final String _reminderTitle = '';
  // final String _reminderSubtitle = '';
  // 添加全屏状态变量
  // bool _isFullScreen = false;
  // 添加考试配置数据
  ExamConfig? _examConfig;
  // 添加加载状态
  bool _isLoading = true;
  // 添加错误信息
  String _errorMessage = '';
  
  // 当前时间
  String _getCurrentTime() {
    // 返回当前时间的格式化字符串
    return DateTime.now().toString().split(' ')[1].substring(0, 8);
  }

  // 获取当前或下一个考试
  Exam? _getCurrentOrNextExam() {
    if (_examConfig == null) return null;
    
    final now = DateTime.now();
    final exams = _examConfig!.examInfos.map((info) => Exam(
      name: info.name,
      start: DateTime.parse(info.start),
      end: DateTime.parse(info.end),
      alertTime: info.alertTime,
    )).toList();
    
    // 查找正在进行的考试
    for (final exam in exams) {
      if (exam.start.isBefore(now) && exam.end.isAfter(now)) {
        return exam;
      }
    }
    // 如果没有正在进行的考试，查找下一个即将开始的考试
    Exam? nextExam;
    Duration? minDiff;
    for (final exam in exams) {
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

  // 获取考试状态文本
  String _getExamStatus(Exam exam) {
    final now = DateTime.now();
    if (now.isBefore(exam.start)) {
      final diff = exam.start.difference(now);
      if (diff.inMinutes <= 15) {
        return '即将开始';
      }
      return '未开始';
    } else if (now.isAfter(exam.end)) {
      return '已结束';
    } else {
      return '考试中';
    }
  }

  // 获取剩余时间文本
  String _getRemainingTime(Exam exam) {
    final now = DateTime.now();
    if (now.isBefore(exam.start)) {
      final diff = exam.start.difference(now);
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      final seconds = diff.inSeconds % 60;
      return '距开始: ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else if (now.isAfter(exam.end)) {
      return '已结束';
    } else {
      final diff = exam.end.difference(now);
      final hours = diff.inHours;
      final minutes = diff.inMinutes % 60;
      final seconds = diff.inSeconds % 60;
      return '剩余时间: ${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  // 检查是否需要显示提醒

  // 从文件加载考试配置
  Future<void> _loadExamConfig() async {
    try {
      // 添加延迟确保插件初始化完成
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 修改路径为系统根目录
      String path;
      if (Platform.isWindows) {
        // Windows系统根目录
        path = 'C:\\esx\\exam_config.json';
      } else if (Platform.isLinux) {
        // Linux系统根目录
        path = '/exam_config.json';
      } else if (Platform.isMacOS) {
        // macOS系统根目录
        path = '/exam_config.json';
      } else {
        // 其他平台回退到应用文档目录
        final directory = await getApplicationDocumentsDirectory();
        path = '${directory.path}/exam_config.json';
      }
      
      File file = File(path);
      
      // 打印路径以便调试
      print('尝试从以下路径加载考试配置文件: $path');
      
      // 检查文件是否存在
      if (await file.exists()) {
        // 从文件读取数据
        final jsonString = await file.readAsString();
        final jsonData = json.decode(jsonString);
        setState(() {
          _examConfig = ExamConfig.fromJson(jsonData);
          _isLoading = false;
        });
        print('成功加载考试配置文件');
      } else {
        // 如果主路径文件不存在，尝试从应用程序文档目录加载
        print('考试配置文件不存在: $path');
        final directory = await getApplicationDocumentsDirectory();
        final fallbackPath = '${directory.path}\\exam_config.json';
        file = File(fallbackPath);
        
        print('尝试从备选路径加载考试配置文件: $fallbackPath');
        if (await file.exists()) {
          // 从备选路径读取数据
          final jsonString = await file.readAsString();
          final jsonData = json.decode(jsonString);
          setState(() {
            _examConfig = ExamConfig.fromJson(jsonData);
            _isLoading = false;
          });
          print('成功从备选路径加载考试配置文件');
        } else {
          // 如果备选路径也不存在文件，使用默认数据
          setState(() {
            _errorMessage = '未找到考试配置文件: $path 和 $fallbackPath';
            _isLoading = false;
          });
          print('备选考试配置文件也不存在: $fallbackPath');
        }
      }
    } on MissingPluginException catch (e) {
      // 处理插件未找到异常
      print('插件异常: $e');
      setState(() {
        _errorMessage = '插件初始化失败，请重启应用';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '加载考试配置失败: $e';
        _isLoading = false;
      });
      print('加载考试配置失败: $e');
    }
  }

  // 考试数据列表
  List<Exam> get _exams {
    if (_examConfig == null) return [];
    return _examConfig!.examInfos.map((info) => Exam(
      name: info.name,
      start: DateTime.parse(info.start),
      end: DateTime.parse(info.end),
      alertTime: info.alertTime,
    )).toList();
  }

  @override
  void initState() {
    super.initState();
    // 初始化动画控制器
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    
    // 每隔一段时间播放一次跳动动画
    Timer.periodic(const Duration(seconds: 10), (timer) {
      _animationController.forward(from: 0.9);
    });
    
    // 加载考试配置
    _loadExamConfig();
    // 启动定时器，每秒更新一次时间显示
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        // 更新时间显示
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // 取消定时器以避免内存泄漏
    _animationController.dispose();
    // 退出全屏模式
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 获取媒体查询数据用于响应式设计
    final mediaQuery = MediaQuery.of(context);
    final textScaleFactor = mediaQuery.textScaleFactor;
    // 基准字体大小，可以根据需要调整
    const baseFontSize = 1.0;
    
    return Scaffold(
      resizeToAvoidBottomInset: false, // 防止键盘弹出时布局变化
      appBar: null, // 移除AppBar
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage.isNotEmpty
                ? Center(
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
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            // 重启程序
                            setState(() {
                              _isLoading = true;
                              _errorMessage = '';
                            });
                            // 重新初始化应用状态
                            _loadExamConfig();
                          },
                          icon: const Icon(Icons.refresh),
                          label: Text(
                            '重新加载',
                            style: TextStyle(
                              fontSize: baseFontSize * 1.2 * textScaleFactor,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 将标题放在顶部中央位置
                      Center(
                        child: Text(
                          _examConfig?.examName ?? '考试安排',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                
                // 主要内容区域 - 分为左右两列
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 左侧列 - 当前时间及考试信息
                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            // 消息显示区域
                            Container(  
                              width: double.infinity, // 设置宽度占满
                              padding: const EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context).colorScheme.secondary,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(19.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    spreadRadius: 2,
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Text(
                                
                                _examConfig?.message ?? '沉着应对，冷静答题。',
                                style: const TextStyle(
                                  fontSize: 28, 
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 8),
                            // 当前时间显示
                            // 使用装饰性容器展示实时时间，具有渐变背景和阴影效果
                            ScaleTransition(
                              scale: _scaleAnimation,
                              child: Container(
                                width: double.infinity, // 设置宽度占满
                                padding: const EdgeInsets.all(20.0),
                                decoration: BoxDecoration(
                                  // 渐变背景色，从左上到右下由浅蓝到深蓝
                                  gradient: LinearGradient(
                                    colors: [
                                      Theme.of(context).colorScheme.primary.withOpacity(0.9),
                                      Theme.of(context).colorScheme.primary,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(24.0),
                                  // 添加阴影效果增强立体感
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.4),
                                      spreadRadius: 3,
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      _getCurrentTime(),
                                      style: TextStyle(
                                        fontSize: MediaQuery.of(context).size.width * 0.125, // 根据屏幕宽度自适应字体大小
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: const [
                                          Shadow(
                                            offset: Offset(2, 2),
                                            blurRadius: 3,
                                            color: Colors.black26,
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Text(
                                    //   '当前时间',
                                    //   style: TextStyle(
                                    //     fontSize: MediaQuery.of(context).size.width * 0.03, // 根据屏幕宽度自适应字体大小
                                    //     color: Colors.white70,
                                    //     fontWeight: FontWeight.w500,
                                    //   ),
                                    // ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            // 当前考试信息区域
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(19.0),
                               
                                child: Column(
                                  // crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    
                                    Container(
                                      width: double.infinity, // 设置宽度占满
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Theme.of(context).colorScheme.primary,
                                          width: 1,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _getCurrentOrNextExam() != null 
                                              ? '科目: ${_getCurrentOrNextExam()?.name ?? ""}' 
                                              : '科目: 暂无',
                                            style: const TextStyle(
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            _getCurrentOrNextExam() != null 
                                              ? '时间: ${TimeUtils.formatTime(_getCurrentOrNextExam()!.start)} - ${TimeUtils.formatTime(_getCurrentOrNextExam()!.end)}'
                                              : '时间: --:-- - --:--',
                                            style: const TextStyle(
                                              fontSize: 26,
                                              height: 1.5,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _getCurrentOrNextExam() != null 
                                              ? _getRemainingTime(_getCurrentOrNextExam()!)
                                              : '剩余时间: --:--:--',
                                            style: const TextStyle(
                                              fontSize: 26,
                                              height: 1.5,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _getCurrentOrNextExam() != null 
                                              ? '状态: ${_getExamStatus(_getCurrentOrNextExam()!)}'
                                              : '状态: 无考试',
                                            style: const TextStyle(
                                              fontSize: 26,
                                              height: 1.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                   
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // 右侧列 - 考试安排表格
                      Expanded(
                        flex: 4,
                        child: Column(
                          children: [
                            // 表头
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24.0, vertical: 16.0),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context).colorScheme.secondary,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16.0)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    spreadRadius: 1,
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Row(
                                children: [
                                  
                                ],
                              ),
                            ),
                            // 表格内容
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: const BorderRadius.vertical(
                                      bottom: Radius.circular(16.0)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.3),
                                      spreadRadius: 1,
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ListView.builder(
                                  padding: const EdgeInsets.all(0),
                                  itemCount: _exams.length,
                                  itemBuilder: (context, index) {
                                    return ExamRow(exam: _exams[index]);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
        ],
      ),
      
      floatingActionButtonLocation: FloatingActionButtonLocation.endContained,
      
    );
  }
}