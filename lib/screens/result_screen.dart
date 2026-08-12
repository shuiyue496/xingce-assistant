import 'package:flutter/material.dart';

import 'quiz_screen.dart';

class ResultScreen extends StatelessWidget {
  final String moduleName;
  final String typeName;
  final List<QuizResult> results;
  final int totalSeconds;
  final VoidCallback? onRetry;

  const ResultScreen({
    super.key,
    required this.moduleName,
    required this.typeName,
    required this.results,
    required this.totalSeconds,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final correct = results.where((r) => r.correct).length;
    final total = results.length;
    final score = total == 0 ? 0 : (correct * 100 / total).round();

    return Scaffold(
      appBar: AppBar(
        title: Text('$typeName · 结果'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Text('本次练习用时 ${_fmt(totalSeconds)}',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text('正确 $correct / $total 题 · 正确率 $score%',
                      style: TextStyle(
                          fontSize: 14, color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Table(
                border: TableBorder(
                  horizontalInside: BorderSide(
                      color: scheme.outlineVariant.withValues(alpha: .5)),
                ),
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(2),
                },
                children: [
                  TableRow(
                    children: [
                      _header('题目'),
                      _header('正确答案'),
                      _header('你的答案'),
                    ],
                  ),
                  for (var i = 0; i < results.length; i++)
                    TableRow(
                      children: _rowCells(scheme, i),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (onRetry != null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('重来'),
                  ),
                ),
              if (onRetry != null) const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {
                    if (onRetry == null) {
                      Navigator.of(context).pop(); // detail view from history
                    } else {
                      Navigator.of(context)
                          .popUntil((route) => route.isFirst);
                    }
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: Text(onRetry == null ? '返回' : '返回首页'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _header(String s) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Text(s,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      );

  List<Widget> _rowCells(ColorScheme scheme, int i) {
    final r = results[i];
    final ok = r.correct;
    final formula = r.question.data?['formula'] as String?;
    final qTitle = formula ?? r.question.prompt.replaceAll('\n', ' ');
    return [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Text(qTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, height: 1.3)),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Text(r.question.answerText,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12)),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Text(
          '${r.userAnswer}${ok ? '√' : '×'}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: ok ? Colors.green.shade700 : scheme.error,
          ),
        ),
      ),
    ];
  }

  static String _fmt(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return m > 0 ? '$m:${s.toString().padLeft(2, '0')}' : '0:${s.toString().padLeft(2, '0')}';
  }
}
