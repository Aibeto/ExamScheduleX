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