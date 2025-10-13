import 'package:flutter/material.dart';

void main() {
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
  // 考试数据，基于exam_config.json
  final List<Exam> exams = [
    Exam(
      name: '语文',
      start: DateTime(2025, 9, 5, 7, 20),
      end: DateTime(2025, 9, 5, 9, 50),
      alertTime: 15,
    ),
    Exam(
      name: '物理',
      start: DateTime(2025, 9, 5, 10, 20),
      end: DateTime(2025, 9, 5, 11, 50),
      alertTime: 15,
    ),
    Exam(
      name: '数学',
      start: DateTime(2025, 9, 5, 14, 10),
      end: DateTime(2025, 9, 5, 16, 10),
      alertTime: 15,
    ),
    Exam(
      name: '历史',
      start: DateTime(2025, 9, 5, 16, 30),
      end: DateTime(2025, 9, 5, 18, 0),
      alertTime: 15,
    ),
    Exam(
      name: '英语',
      start: DateTime(2025, 9, 6, 7, 50),
      end: DateTime(2025, 9, 6, 9, 50),
      alertTime: 15,
    ),
    Exam(
      name: '化学',
      start: DateTime(2025, 9, 6, 10, 20),
      end: DateTime(2025, 9, 6, 11, 50),
      alertTime: 15,
    ),
    Exam(
      name: '政治/生物',
      start: DateTime(2025, 9, 6, 14, 10),
      end: DateTime(2025, 9, 6, 15, 40),
      alertTime: 15,
    ),
    Exam(
      name: '地理',
      start: DateTime(2025, 9, 6, 16, 10),
      end: DateTime(2025, 9, 6, 17, 40),
      alertTime: 15,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('高三一调'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.fullscreen),
            onPressed: () {
              // 全屏功能
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
      body: Column(
        children: [
          // 消息显示区域
          Container(
            padding: const EdgeInsets.all(16.0),
            child: const Text(
              '沉着应对，冷静答题。',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          // 当前时间显示
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: const Text(
              '当前时间: 00:00:00',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          // 当前考试信息区域
          Card(
            margin: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(16.0),
              child: const Column(
                children: [
                  Text(
                    '当前科目: 语文',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('考试时间: 07:20 - 09:50'),
                  SizedBox(height: 8),
                  Text('剩余时间: 01:30:00'),
                  SizedBox(height: 8),
                  Text('状态: 考试中'),
                ],
              ),
            ),
          ),
          // 考试安排表格
          Expanded(
            child: Column(
              children: [
                // 表头
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          '时间',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '科目',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '开始',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '结束',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          '状态',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                // 表格内容
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: exams.length,
                    itemBuilder: (context, index) {
                      return ExamRow(exam: exams[index]);
                    },
                  ),
                ),
              ],
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

class ExamRow extends StatelessWidget {
  final Exam exam;

  const ExamRow({super.key, required this.exam});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                '${exam.start.month}/${exam.start.day}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(exam.name),
            ),
            Expanded(
              flex: 2,
              child: Text(_formatTime(exam.start)),
            ),
            Expanded(
              flex: 2,
              child: Text(_formatTime(exam.end)),
            ),
            const Expanded(
              flex: 1,
              child: Text('未开始'),
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