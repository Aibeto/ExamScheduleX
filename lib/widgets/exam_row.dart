// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../models/exam.dart';
import '../utils/time_utils.dart';

/// 考试信息行组件
/// 
/// 用于显示单个考试的信息，包括考试日期、时间、名称和状态。
/// 状态会根据当前时间自动更新（未开始、即将开始、考试中、已结束），
/// 并以不同颜色标识不同状态。
/// 
/// [exam] 要显示的考试信息对象
class ExamRow extends StatelessWidget {
  final Exam exam;

  const ExamRow({super.key, required this.exam});

  @override
  Widget build(BuildContext context) {
    /// 获取考试状态文本
    /// 
    /// 根据当前时间和考试的开始、结束时间比较，返回相应的状态文本：
    /// - 如果当前时间在考试开始前15分钟内，返回"即将开始"
    /// - 如果当前时间在考试开始前超过15分钟，返回"未开始"
    /// - 如果当前时间在考试时间段内，返回"考试中"
    /// - 如果当前时间在考试结束后，返回"已结束"
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

    /// 获取与考试状态对应的颜色
    /// 
    /// 根据考试状态返回不同的颜色用于界面展示：
    /// - "考试中" 返回红色
    /// - "即将开始" 返回橙色
    /// - "未开始" 返回主题主色调
    /// - 其他状态返回灰色
    Color getStatusColor() {
      final status = getStatusText();
      switch (status) {
        case '考试中':
          return Colors.redAccent;
        case '即将开始':
          return Colors.orangeAccent;
        case '未开始':
          return Theme.of(context).colorScheme.primary;
        default:
          return Colors.grey;
      }
    }

    /// 构建考试信息行组件
    /// 
    /// 组件分为三列布局：
    /// 1. 左侧显示考试日期和时间范围
    /// 2. 中间显示考试名称
    /// 3. 右侧显示考试状态标签（带背景色）
    return Container(
      decoration: BoxDecoration(
        border: const Border(
          bottom: BorderSide(
            color: Colors.grey,
            width: 0.5,
          ),
        ),
        /// 正在进行的考试会有特殊的背景色标识
        color: (getStatusText() == '考试中') 
          ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
          : Colors.transparent,
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            /// 第一列：考试日期和时间范围
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Text(
                    '${exam.start.month}/${exam.start.day}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    '${TimeUtils.formatTime(exam.start)} - ${TimeUtils.formatTime(exam.end)}',
                    style: const TextStyle(
                      fontSize: 26,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            /// 第二列：考试名称
            Expanded(
              flex: 2,
              child: Text(
                exam.name,
                style: const TextStyle(
                  fontSize: 32,
                  // fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            /// 第三列：考试状态标签
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                decoration: BoxDecoration(
                  color: getStatusColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: getStatusColor(),
                    width: 1,
                  ),
                ),
                child: Text(
                  getStatusText(),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: getStatusColor(),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}