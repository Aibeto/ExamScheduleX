import 'exam_info.dart';

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