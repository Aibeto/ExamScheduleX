// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:examschedulex/main.dart';

void main() {
  testWidgets('Exam schedule app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ExamScheduleApp());

    // Verify that the app bar title is displayed.
    expect(find.text('高三一调'), findsOneWidget);

    // Verify that we have the message text.
    expect(find.text('沉着应对，冷静答题。'), findsOneWidget);

    // Verify that we can find table headers.
    expect(find.text('时间'), findsOneWidget);
    expect(find.text('科目'), findsOneWidget);
    expect(find.text('开始'), findsOneWidget);
    expect(find.text('结束'), findsOneWidget);
    expect(find.text('状态'), findsOneWidget);

    // Verify that we have exam subjects in the list.
    expect(find.text('语文'), findsOneWidget);
    expect(find.text('数学'), findsOneWidget);

    // Verify that we can find the back button.
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });
}