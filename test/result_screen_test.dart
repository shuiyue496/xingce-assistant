import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xingce_assistant/generators/calc_generator.dart';
import 'package:xingce_assistant/screens/quiz_screen.dart';
import 'package:xingce_assistant/screens/result_screen.dart';

void main() {
  Widget wrap(Widget w) => MaterialApp(home: w);

  testWidgets('result screen renders with mixed results', (tester) async {
    final q = CalcGenerator.generate('add_sub_2d', 1).first;
    await tester.pumpWidget(wrap(ResultScreen(
      moduleName: '基础计算练习',
      typeName: '两位数加减',
      results: [
        QuizResult(q, '5', true, 3),
        QuizResult(q, '8', false, 4),
      ],
      totalSeconds: 7,
    )));
    await tester.pump();
    expect(find.byType(ResultScreen), findsOneWidget);
    expect(find.textContaining('本次练习用时'), findsOneWidget);
    expect(find.textContaining('正确答案'), findsOneWidget);
    expect(find.textContaining('你的答案'), findsOneWidget); // header
    expect(find.textContaining('√'), findsOneWidget);
    expect(find.textContaining('×'), findsOneWidget);
  });

  testWidgets('full quiz flow finishes into result screen', (tester) async {
    final qs = CalcGenerator.generate('add_sub_2d', 2);
    await tester.pumpWidget(wrap(QuizScreen(
      module: 'calc',
      moduleName: '基础计算练习',
      typeName: '两位数加减',
      questions: qs,
      useKeypad: false,
    )));
    // answer both questions correctly via the system input
    for (final q in qs) {
      final answer = q.answerText;
      await tester.enterText(find.byType(TextField), answer);
      await tester.pump(); // render the typed input
      await tester.tap(find.text('确定'));
      await tester.pump(); // brief feedback strip
      await tester.pump(const Duration(milliseconds: 750)); // auto-advance
      await tester.pump(); // render the advanced question
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400)); // route transition
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ResultScreen), findsOneWidget);
  });
}
