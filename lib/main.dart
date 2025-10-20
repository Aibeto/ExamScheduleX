// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  // 确保Flutter框架完全初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 设置系统UI样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  runApp(const ExamScheduleApp());
}

class ExamScheduleApp extends StatelessWidget {
  const ExamScheduleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Exam Schedule',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ExamScheduleHomePage(),
    );
  }
}

class ExamScheduleHomePage extends StatefulWidget {
  const ExamScheduleHomePage({super.key});

  @override
  State<ExamScheduleHomePage> createState() => _ExamScheduleHomePageState();
}

class _ExamScheduleHomePageState extends State<ExamScheduleHomePage> {
  // 添加Timer用于更新时间
  Timer? _timer;
  // 添加提醒对话框相关的状态
  bool _showReminder = false;
  String _reminderTitle = '';
  String _reminderSubtitle = '';
  // 添加全屏状态变量
  bool _isFullScreen = false;
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
  void _checkReminders() {
    if (_examConfig == null) return;
    
    final exams = _examConfig!.examInfos.map((info) => Exam(
      name: info.name,
      start: DateTime.parse(info.start),
      end: DateTime.parse(info.end),
      alertTime: info.alertTime,
    )).toList();
    
    final now = DateTime.now();
    for (final exam in exams) {
      // 检查考试前15分钟提醒
      final reminderTime = exam.start.subtract(Duration(minutes: exam.alertTime));
      if (now.isAfter(reminderTime) && now.isBefore(exam.start)) {
        setState(() {
          _showReminder = true;
          _reminderTitle = '距离${exam.name}考试还有 ${exam.alertTime} 分钟';
          _reminderSubtitle = '请准备考试';
        });
        return;
      }
      
      // 检查考试结束前15分钟提醒
      final endReminderTime = exam.end.subtract(Duration(minutes: exam.alertTime));
      if (now.isAfter(endReminderTime) && now.isBefore(exam.end)) {
        setState(() {
          _showReminder = true;
          _reminderTitle = '距离${exam.name}考试结束还有 ${exam.alertTime} 分钟';
          _reminderSubtitle = '注意掌握时间';
        });
        return;
      }
    }
  }

  // 从文件加载考试配置
  Future<void> _loadExamConfig() async {
    try {
      // 添加延迟确保插件初始化完成
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 修改路径为系统根目录
      String path;
      if (Platform.isWindows) {
        // Windows系统根目录
        path = 'C:/exam_config.json';
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
      
      final file = File(path);
      
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
        // 如果文件不存在，使用默认数据
        setState(() {
          _errorMessage = '未找到考试配置文件: $path';
          _isLoading = false;
        });
        print('考试配置文件不存在: $path');
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
    // 加载考试配置
    _loadExamConfig();
    // 启动定时器，每秒更新一次时间显示
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        // 更新UI
      });
      _checkReminders();
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // 取消定时器以避免内存泄漏
    // 退出全屏模式
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // 防止键盘弹出时布局变化
      appBar: AppBar(
        title: Text(_examConfig?.examName ?? '考试安排'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(_isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen),
            onPressed: () {
              // 全屏功能
              setState(() {
                _isFullScreen = !_isFullScreen;
              });
              
              if (_isFullScreen) {
                // 进入全屏模式 - 隐藏所有系统UI
                SystemChrome.setEnabledSystemUIMode(
                  SystemUiMode.manual,
                  overlays: [],
                );
              } else {
                // 退出全屏模式 - 显示系统UI
                SystemChrome.setEnabledSystemUIMode(
                  SystemUiMode.manual,
                  overlays: SystemUiOverlay.values,
                );
              }
              
              // 显示提示信息
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isFullScreen ? '已进入全屏模式' : '已退出全屏模式'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // 提醒设置
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // 系统设置
            },
          ),
        ],
      ),
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
                        Text(_errorMessage, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadExamConfig,
                          child: const Text('重新加载'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                // 消息显示区域
                Container(
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    _examConfig?.message ?? '沉着应对，冷静答题。',
                    style: const TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                
                // 主要内容区域 - 分为左右两列
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 左侧列 - 当前时间及考试信息
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            // 当前时间显示
                            Container(
                              padding: const EdgeInsets.all(24.0),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                    Theme.of(context).colorScheme.primary,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    spreadRadius: 2,
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    '当前时间',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _getCurrentTime(),
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // 当前考试信息区域
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(24.0),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(16.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.3),
                                      spreadRadius: 2,
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getCurrentOrNextExam() != null 
                                        ? '当前科目: ${_getCurrentOrNextExam()?.name ?? ""}' 
                                        : '当前科目: 暂无',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _getCurrentOrNextExam() != null 
                                        ? '考试时间: ${ExamRow._formatTime(_getCurrentOrNextExam()!.start)} - ${ExamRow._formatTime(_getCurrentOrNextExam()!.end)}'
                                        : '考试时间: --:-- - --:--',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _getCurrentOrNextExam() != null 
                                        ? _getRemainingTime(_getCurrentOrNextExam()!)
                                        : '剩余时间: --:--:--',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _getCurrentOrNextExam() != null 
                                        ? '状态: ${_getExamStatus(_getCurrentOrNextExam()!)}'
                                        : '状态: 无考试',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        height: 1.5,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    
                                    // 切换显示模式按钮
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.swap_horiz,
                                          size: 36,
                                          color: Colors.white,
                                        ),
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
                        flex: 1,
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
                                    Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(16.0)),
                              ),
                              child: const Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '时间',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 18),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '科目',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 18),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '开始',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 18),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      '结束',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 18),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      '状态',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 18),
                                    ),
                                  ),
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
          // 提醒对话框
          if (_showReminder)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(32.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _reminderTitle,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _reminderSubtitle,
                        style: const TextStyle(
                          fontSize: 20,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _showReminder = false;
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          textStyle: const TextStyle(
                            fontSize: 18,
                          ),
                        ),
                        child: const Text('确定'),
                      )
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 返回主页
        },
        child: const Icon(Icons.arrow_back),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endContained,
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {
                // 导航到主页
              },
            ),
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () {
                // 导航到日历视图
              },
            ),
            IconButton(
              icon: const Icon(Icons.info),
              onPressed: () {
                // 显示信息
              },
            ),
          ],
        ),
      ),
    );
  }
}

class Exam {
  final String name;
  final DateTime start;
  final DateTime end;
  final int alertTime;

  Exam({
    required this.name,
    required this.start,
    required this.end,
    required this.alertTime,
  });
}

class ExamConfig {
  final String examName;
  final String message;
  final List<ExamInfo> examInfos;

  ExamConfig({
    required this.examName,
    required this.message,
    required this.examInfos,
  });

  factory ExamConfig.fromJson(Map<String, dynamic> json) {
    var examInfosList = json['examInfos'] as List;
    List<ExamInfo> examInfos = examInfosList.map((e) => ExamInfo.fromJson(e)).toList();

    return ExamConfig(
      examName: json['examName'],
      message: json['message'],
      examInfos: examInfos,
    );
  }
}

class ExamInfo {
  final String name;
  final String start;
  final String end;
  final int alertTime;
  final List<dynamic> materials;

  ExamInfo({
    required this.name,
    required this.start,
    required this.end,
    required this.alertTime,
    required this.materials,
  });

  factory ExamInfo.fromJson(Map<String, dynamic> json) {
    return ExamInfo(
      name: json['name'],
      start: json['start'],
      end: json['end'],
      alertTime: json['alertTime'],
      materials: json['materials'],
    );
  }
}

class ExamRow extends StatelessWidget {
  final Exam exam;

  const ExamRow({super.key, required this.exam});

  @override
  Widget build(BuildContext context) {
    // 获取考试状态
    String getStatusText() {
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

    return Container(
      decoration: BoxDecoration(
        border: const Border(
          bottom: BorderSide(
            color: Colors.grey,
            width: 0.5,
          ),
        ),
        color: (getStatusText() == '考试中') 
          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
          : Colors.transparent,
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                '${exam.start.month}/${exam.start.day}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                exam.name,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                _formatTime(exam.start),
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                _formatTime(exam.end),
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                getStatusText(),
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}