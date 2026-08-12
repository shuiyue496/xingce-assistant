import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../models/question.dart';
import '../widgets/custom_numpad.dart';
import 'result_screen.dart';

class QuizResult {
  final Question question;
  final String userAnswer;
  final bool correct;
  final int seconds;

  const QuizResult(this.question, this.userAnswer, this.correct, this.seconds);
}

enum _Feedback { none, ok, wrong }

/// Shared quiz page: fill-in (custom keypad), choice or compare mode.
class QuizScreen extends StatefulWidget {
  final String module; // 'calc' | 'data' | 'seq'
  final String moduleName;
  final String typeName;
  final List<Question> questions;
  final bool fastFeedback; // show a detailed feedback dialog on wrong answers
  final bool useKeypad; // custom keypad instead of system keyboard

  const QuizScreen({
    super.key,
    required this.module,
    required this.moduleName,
    required this.typeName,
    required this.questions,
    this.fastFeedback = false,
    this.useKeypad = true,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _index = 0;
  String _input = '';
  String? _selectedOption;
  bool _done = false;
  NumpadMode _keypadMode = NumpadMode.docked;
  Timer? _ticker;
  Timer? _feedbackTimer;
  int _elapsed = 0;
  _Feedback _feedback = _Feedback.none;
  String _feedbackText = '';
  final _results = <QuizResult>[];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _feedbackTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _feedback == _Feedback.none) {
        setState(() => _elapsed++);
      }
    });
  }

  Question get _q => widget.questions[_index];

  bool get _isComparing => _q.options != null && _q.compareMode;

  String get _prefix => (_q.data?['prefix'] as String?) ?? '';

  /// Full input value including the answer prefix (e.g. "0." for decimals).
  String get _fullInput => _prefix + _input;

  // ---------- actions ----------

  void _submit(String userAnswer) {
    if (_done || _feedback != _Feedback.none) return;
    final correct = _q.check(userAnswer);
    _results.add(QuizResult(_q, userAnswer, correct, _elapsed));
    _elapsed = 0;
    if (!correct && widget.fastFeedback) {
      _showFeedbackDialog(userAnswer);
      return;
    }
    _showBriefFeedback(correct);
  }

  void _showBriefFeedback(bool correct) {
    setState(() {
      _feedback = correct ? _Feedback.ok : _Feedback.wrong;
      _feedbackText =
          correct ? '✓ 正确' : '✗ 错误，正确答案：${_q.answerText}';
    });
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) _advance();
    });
  }

  void _advance() {
    _feedbackTimer?.cancel();
    setState(() {
      _input = '';
      _selectedOption = null;
      _feedback = _Feedback.none;
      _feedbackText = '';
      _index++;
      if (_index >= widget.questions.length) {
        _finish();
      }
    });
  }

  /// 重开: reset the current question (input + timer).
  void _restart() {
    _feedbackTimer?.cancel();
    setState(() {
      _input = '';
      _selectedOption = null;
      _feedback = _Feedback.none;
      _feedbackText = '';
      _elapsed = 0;
    });
  }

  Future<void> _finish() async {
    _done = true;
    _ticker?.cancel();
    final totalSec = _results.fold<int>(0, (s, r) => s + r.seconds);
    final correctCount = _results.where((r) => r.correct).length;

    await AppDatabase.instance.addRecord(PracticeRecord(
      module: widget.module,
      moduleName: widget.moduleName,
      typeId: widget.questions.last.typeId,
      typeName: widget.typeName,
      total: widget.questions.length,
      correct: correctCount,
      seconds: totalSec,
      doneAt: DateTime.now(),
      details: [
        for (final r in _results)
          {
            'question': r.question.toJson(),
            'userAnswer': r.userAnswer,
            'correct': r.correct,
            'seconds': r.seconds,
          },
      ],
    ));

    if (!mounted) return;
    final navigator = Navigator.of(context);
    navigator.pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          moduleName: widget.moduleName,
          typeName: widget.typeName,
          results: _results,
          totalSeconds: totalSec,
          onRetry: () => navigator.pushReplacement(
            MaterialPageRoute(
              builder: (_) => QuizScreen(
                module: widget.module,
                moduleName: widget.moduleName,
                typeName: widget.typeName,
                questions: widget.questions,
                fastFeedback: widget.fastFeedback,
                useKeypad: widget.useKeypad,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showFeedbackDialog(String userAnswer) async {
    final q = _q;
    final parsed = double.tryParse(userAnswer);
    final exact = q.answerNum;
    // Difference and error rate are signed: correct value minus the answer.
    final diffText = exact == null || parsed == null
        ? '—'
        : (exact - parsed).toStringAsFixed(2);
    final errText = exact == null || parsed == null
        ? '—'
        : '${((exact - parsed) / exact * 100).toStringAsFixed(2)}%';
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('答案错误',
            style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(q.prompt.replaceAll('\n', ' '),
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const Divider(height: 16),
            Text('你的答案：$userAnswer'),
            const SizedBox(height: 4),
            Text('正确值：${q.answerText}'),
            const SizedBox(height: 4),
            Text('差值：$diffText'),
            const SizedBox(height: 4),
            Text('误差率：$errText'),
            if (q.explanation.isNotEmpty) ...[
              const Divider(height: 20),
              Text(q.explanation,
                  style: const TextStyle(fontSize: 13, height: 1.5)),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _advance();
            },
            child: const Text('下一题'),
          ),
        ],
      ),
    );
  }

  // ---------- build ----------

  @override
  Widget build(BuildContext context) {
    // During the route transition to ResultScreen the old route is rebuilt
    // with _index already past the end; render a placeholder instead.
    if (_done) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final scheme = Theme.of(context).colorScheme;
    final q = _q;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final leave = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('退出练习？'),
            content: Text('已完成 ${_results.length}/${widget.questions.length} 题'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('继续')),
              FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('退出')),
            ],
          ),
        );
        if (leave == true && mounted) navigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.typeName}　${_index + 1}/${widget.questions.length}'),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // timer + progress bar
                Container(
                  width: double.infinity,
                  color: scheme.surfaceContainerHighest,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Center(
                    child: Text('本题用时 ${_fmtTime(_elapsed)}',
                        style: TextStyle(
                            fontSize: 13, color: scheme.onSurfaceVariant)),
                  ),
                ),
                // brief feedback strip
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: _feedback == _Feedback.none
                      ? const SizedBox(height: 0)
                      : Container(
                          key: ValueKey(_feedback),
                          width: double.infinity,
                          color: _feedback == _Feedback.ok
                              ? Colors.green.withValues(alpha: .15)
                              : scheme.error.withValues(alpha: .15),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Center(
                            child: Text(
                              _feedbackText,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _feedback == _Feedback.ok
                                    ? Colors.green.shade800
                                    : scheme.error,
                              ),
                            ),
                          ),
                        ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTable(q),
                        if (q.data != null &&
                            q.data!['noExtrapolate'] == true) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  size: 16, color: scheme.tertiary),
                              const SizedBox(width: 6),
                              Text('不能往前推：按题目给定年份计算',
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: scheme.tertiary)),
                            ],
                          ),
                        ],
                        if (q.data?['hint'] != null) ...[
                          const SizedBox(height: 8),
                          Text(q.data!['hint'] as String,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: scheme.onSurfaceVariant)),
                        ],
                        const SizedBox(height: 12),
                        Text(
                          q.prompt,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (q.options != null)
                          _isComparing ? _buildCompare() : _buildOptions(q)
                        else
                          _buildInput(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (widget.useKeypad && _q.options == null)
              CustomNumpad(
                mode: _keypadMode,
                enabled: _feedback == _Feedback.none,
                onDigit: (d) =>
                    setState(() => _input = _input + d),
                onBackspace: () => setState(() {
                  if (_input.isNotEmpty) {
                    _input = _input.substring(0, _input.length - 1);
                  }
                }),
                onClear: () => setState(() => _input = ''),
                onRestart: _restart,
                onSubmit: () {
                  if (_fullInput.trim().isNotEmpty &&
                      _feedback == _Feedback.none) {
                    _submit(_fullInput.trim());
                  }
                },
                onModeChanged: (m) => setState(() => _keypadMode = m),
              ),
          ],
        ),
      ),
    );
  }

  // ---------- question widgets ----------

  Widget _buildTable(Question q) {
    final data = q.data;
    if (data == null) return const SizedBox.shrink();
    final chart = data['chart'];
    if (chart != null) {
      return _BarChart(
        chart: chart as Map<String, dynamic>,
      );
    }
    final table = data['table'];
    if (table == null) return const SizedBox.shrink();
    final columns = (table['columns'] as List).cast<String>();
    final rows = (table['rows'] as List).cast<List>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Table(
          border:
              TableBorder.all(color: Theme.of(context).colorScheme.outlineVariant),
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer),
              children: [
                for (final c in columns)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(c,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
            for (final r in rows)
              TableRow(
                children: [
                  for (final cell in r)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text('$cell',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 15)),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptions(Question q) {
    final labels = ['A', 'B', 'C', 'D'];
    return Column(
      children: [
        for (var i = 0; i < q.options!.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _feedback == _Feedback.none
                    ? () => _submit(q.options![i])
                    : null,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  '${labels[i]}. ${q.options![i]}',
                  style:
                      const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// 大于/小于 comparison mode (data analysis module).
  /// Renders the two expressions side by side with a green ? between them,
  /// then 大于/小于/重开/确定 buttons.
  Widget _buildCompare() {
    final scheme = Theme.of(context).colorScheme;
    final left = _q.data?['left'] as String?;
    final right = _q.data?['right'] as String?;
    return Column(
      children: [
        if (left != null && right != null)
          Card(
            color: scheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(left,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 19, fontWeight: FontWeight.w700)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('？',
                        style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Colors.green.shade600)),
                  ),
                  Expanded(
                    child: Text(right,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 19, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: _feedback == _Feedback.none
                      ? () => setState(() => _selectedOption = '大于')
                      : null,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: _selectedOption == '大于'
                        ? Colors.green.withValues(alpha: .15)
                        : null,
                    side: BorderSide(
                      color: _selectedOption == '大于'
                          ? Colors.green
                          : scheme.outlineVariant,
                      width: _selectedOption == '大于' ? 2 : 1,
                    ),
                  ),
                  child: Text('大于',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.green.shade700)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: _feedback == _Feedback.none
                      ? () => setState(() => _selectedOption = '小于')
                      : null,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: _selectedOption == '小于'
                        ? Colors.orange.withValues(alpha: .15)
                        : null,
                    side: BorderSide(
                      color: _selectedOption == '小于'
                          ? Colors.orange
                          : scheme.outlineVariant,
                      width: _selectedOption == '小于' ? 2 : 1,
                    ),
                  ),
                  child: Text('小于',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.orange.shade800)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _feedback == _Feedback.none ? _restart : null,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('重开'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: _selectedOption != null &&
                        _feedback == _Feedback.none
                    ? () => _submit(_selectedOption!)
                    : null,
                icon: const Icon(Icons.check, size: 18),
                label: const Text('确定'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInput() {
    final scheme = Theme.of(context).colorScheme;
    final useSystem = !widget.useKeypad || _keypadMode == NumpadMode.system;
    return Column(
      children: [
        Container(
          height: 72,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: useSystem
              ? TextField(
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                      signed: true, decimal: true),
                  style: const TextStyle(
                      fontSize: 30, fontWeight: FontWeight.w700),
                  onSubmitted: (_) => _fullInput.trim().isNotEmpty
                      ? _submit(_fullInput.trim())
                      : null,
                  onChanged: (v) => setState(() => _input = v),
                  decoration: const InputDecoration(border: InputBorder.none),
                )
              : Text(
                  _input.isEmpty && _prefix.isEmpty
                      ? '请输入答案'
                      : _prefix + _input,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: _input.isEmpty && _prefix.isEmpty
                        ? scheme.onSurfaceVariant.withValues(alpha: .4)
                        : scheme.onSurface,
                  ),
                ),
        ),
        const SizedBox(height: 10),
        if (useSystem)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () =>
                      setState(() => _keypadMode = NumpadMode.docked),
                  icon: const Icon(Icons.keyboard_alt_outlined, size: 18),
                  label: const Text('返回自定义键盘'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: _fullInput.trim().isNotEmpty &&
                          _feedback == _Feedback.none
                      ? () => _submit(_fullInput.trim())
                      : null,
                  child: const Text('确定'),
                ),
              ),
            ],
          ),
      ],
    );
  }

  static String _fmtTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return m > 0 ? '$m分${s.toString().padLeft(2, '0')}秒' : '$s秒';
  }
}

/// Simple bar chart for 年均增长率 questions.
class _BarChart extends StatelessWidget {
  final Map<String, dynamic> chart;

  const _BarChart({required this.chart});

  @override
  Widget build(BuildContext context) {
    final years = (chart['years'] as List).cast<String>();
    final values = (chart['values'] as List).cast<num>();
    final unit = chart['unit'] as String? ?? '';
    final legend = chart['legend'] as String? ?? '';
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      color: Colors.green.shade600,
                      borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 6),
                Text(legend,
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              width: double.infinity,
              child: CustomPaint(
                painter: _BarChartPainter(years: years, values: values, unit: unit),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<String> years;
  final List<num> values;
  final String unit;

  _BarChartPainter({required this.years, required this.values, required this.unit});

  @override
  void paint(Canvas canvas, Size size) {
    final barColor = Colors.green.shade600;
    final axisColor = Colors.grey.shade400;
    final textColor = Colors.grey.shade700;
    final maxV = values.reduce(max);
    final niceMax = _niceCeil(maxV * 1.15);
    const tickCount = 5;

    final leftPad = 52.0;
    final bottomPad = 22.0;
    final topPad = 18.0;
    final chartH = size.height - bottomPad - topPad;
    final chartW = size.width - leftPad - 4;

    // y axis ticks
    final tickPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1;
    for (var i = 0; i <= tickCount; i++) {
      final v = niceMax * i / tickCount;
      final y = topPad + chartH - chartH * i / tickCount;
      canvas.drawLine(Offset(leftPad, y), Offset(size.width - 4, y), tickPaint);
      final tp = TextPainter(
        text: TextSpan(
            text: _fmtAxis(v) + (i == tickCount ? unit : ''),
            style: TextStyle(fontSize: 10, color: textColor)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - tp.height / 2));
    }

    // bars
    final n = values.length;
    final slot = chartW / n;
    final barW = slot * 0.5;
    for (var i = 0; i < n; i++) {
      final v = values[i];
      final h = chartH * v / niceMax;
      final x = leftPad + slot * i + (slot - barW) / 2;
      final y = topPad + chartH - h;
      final rrect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barW, h), const Radius.circular(4));
      canvas.drawRRect(rrect, Paint()..color = barColor);
      // value label
      final vp = TextPainter(
        text: TextSpan(
            text: _fmtBar(v),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.black87)),
        textDirection: TextDirection.ltr,
      )..layout();
      vp.paint(canvas, Offset(x + (barW - vp.width) / 2, y - vp.height - 2));
      // year label
      final yp = TextPainter(
        text: TextSpan(
            text: years[i], style: TextStyle(fontSize: 10, color: textColor)),
        textDirection: TextDirection.ltr,
      )..layout();
      yp.paint(canvas, Offset(x + (barW - yp.width) / 2, topPad + chartH + 4));
    }
  }

  static double _niceCeil(double v) {
    final mag = pow(10, (log(v) / ln10).floor()).toDouble();
    final norm = v / mag;
    final nice = norm <= 1 ? 1.0 : norm <= 2 ? 2.0 : norm <= 2.5 ? 2.5 : norm <= 5 ? 5.0 : 10.0;
    return nice * mag;
  }

  static String _fmtAxis(double v) {
    if (v >= 10000) return '${(v / 10000).toStringAsFixed(0)}万';
    return v.toStringAsFixed(0);
  }

  static String _fmtBar(num v) {
    if (v >= 10000) return '${(v / 10000).toStringAsFixed(2)}万';
    return '$v';
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter old) =>
      old.values != values || old.years != years;
}
