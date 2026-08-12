import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xingce_assistant/generators/calc_generator.dart';
import 'package:xingce_assistant/generators/data_generator.dart';
import 'package:xingce_assistant/generators/seq_generator.dart';
import 'package:xingce_assistant/screens/quiz_screen.dart';

void main() {
  Widget wrap(Widget w) => MaterialApp(home: w);

  testWidgets('calc fill quiz renders', (tester) async {
    final qs = CalcGenerator.generate('add_sub_2d', 5);
    await tester.pumpWidget(wrap(QuizScreen(
      module: 'calc',
      moduleName: '基础计算练习',
      typeName: '两位数加减',
      questions: qs,
    )));
    await tester.pump();
    expect(find.byType(QuizScreen), findsOneWidget);
    expect(find.textContaining('1/5'), findsOneWidget);
  });

  testWidgets('seq choice quiz renders', (tester) async {
    final qs = SeqGenerator.generate('basic', 5);
    await tester.pumpWidget(wrap(QuizScreen(
      module: 'seq',
      moduleName: '数字推理训练',
      typeName: '基础数列',
      questions: qs,
    )));
    await tester.pump();
    expect(find.byType(QuizScreen), findsOneWidget);
  });

  testWidgets('data table quiz renders with keypad', (tester) async {
    final qs = DataGenerator.generate('avg_annual', 3);
    await tester.pumpWidget(wrap(QuizScreen(
      module: 'data',
      moduleName: '资料分析专项',
      typeName: '年平均量',
      questions: qs,
    )));
    await tester.pump();
    expect(find.byType(QuizScreen), findsOneWidget);
  });

  testWidgets('compare question renders 大于/小于 buttons', (tester) async {
    final qs = DataGenerator.generate('delta_compare', 3);
    expect(qs.first.options, const ['大于', '小于']);
    await tester.pumpWidget(wrap(QuizScreen(
      module: 'data',
      moduleName: '资料分析专项',
      typeName: '增量比大小',
      questions: qs,
    )));
    await tester.pump();
    expect(find.text('大于'), findsOneWidget);
    expect(find.text('小于'), findsOneWidget);
    expect(find.text('重开'), findsOneWidget);
    expect(find.text('确定'), findsOneWidget);
    // selecting then submitting advances
    await tester.tap(find.text('大于'));
    await tester.pump();
    await tester.tap(find.text('确定'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 750));
    await tester.pump();
    expect(find.textContaining('2/3'), findsOneWidget);
  });

  testWidgets('fraction with prefix shows 0. input', (tester) async {
    final qs = DataGenerator.generate('frac_small', 2);
    expect(qs.first.data?['prefix'], '0.');
    await tester.pumpWidget(wrap(QuizScreen(
      module: 'data',
      moduleName: '资料分析专项',
      typeName: '分数计算（分子<分母）',
      questions: qs,
    )));
    await tester.pump();
    expect(find.textContaining('建议写到小数点后 2~3 位'), findsOneWidget);
    // prefix renders in the display box
    expect(find.textContaining('0.'), findsWidgets);
  });
}
