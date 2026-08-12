import 'package:flutter/material.dart';

import '../db/app_database.dart';
import '../models/question.dart';
import 'quiz_screen.dart';
import 'result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<PracticeRecord> _items = [];
  bool _loading = true;

  static const _moduleColors = {
    'calc': Colors.indigo,
    'data': Colors.teal,
    'seq': Colors.orange,
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await AppDatabase.instance.getRecords(limit: 500);
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _confirmDelete(PracticeRecord r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除这条记录？'),
        content: Text('${r.doneAt.month}月${r.doneAt.day}日 '
            '${r.doneAt.hour.toString().padLeft(2, '0')}:${r.doneAt.minute.toString().padLeft(2, '0')} '
            '${r.typeName} · ${r.correct}/${r.total}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('删除')),
        ],
      ),
    );
    if (ok == true) {
      await AppDatabase.instance.removeRecord(r.id!);
      _load();
    }
  }

  Future<void> _clearAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空历史记录？'),
        content: Text('共 ${_items.length} 条记录，将全部删除'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('清空')),
        ],
      ),
    );
    if (ok == true) {
      await AppDatabase.instance.clearRecords();
      _load();
    }
  }

  void _openDetail(PracticeRecord r) {
    final results = <QuizResult>[
      if (r.details != null)
        for (final d in r.details!)
          QuizResult(
            Question.fromJson(d['question'] as Map<String, dynamic>),
            d['userAnswer'] as String,
            d['correct'] as bool,
            d['seconds'] as int,
          ),
    ];
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ResultScreen(
        moduleName: r.moduleName,
        typeName: r.typeName,
        results: results,
        totalSeconds: r.seconds,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final totalQ = _items.fold<int>(0, (s, r) => s + r.total);
    final totalCorrect = _items.fold<int>(0, (s, r) => s + r.correct);
    final rate = totalQ == 0 ? null : (totalCorrect * 100 / totalQ).round();
    final totalSec = _items.fold<int>(0, (s, r) => s + r.seconds);

    return Scaffold(
      appBar: AppBar(
        title: const Text('练习记录'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: '清空',
            onPressed: _items.isEmpty ? null : _clearAll,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (AppDatabase.lastError != null)
                  Container(
                    width: double.infinity,
                    color: scheme.errorContainer,
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      '存储异常：${AppDatabase.lastError}',
                      style: TextStyle(
                          fontSize: 12, color: scheme.onErrorContainer),
                    ),
                  ),
                if (_items.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            _stat('练习', '${_items.length} 次'),
                            _stat('总题数', '$totalQ 题'),
                            _stat('正确率', rate == null ? '—' : '$rate%'),
                            _stat('总用时', _fmt(totalSec)),
                          ],
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: _items.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history,
                                  size: 64, color: scheme.outlineVariant),
                              const SizedBox(height: 12),
                              Text('暂无练习记录',
                                  style: TextStyle(
                                      color: scheme.onSurfaceVariant)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _items.length,
                          itemBuilder: (context, i) {
                            final r = _items[i];
                            final color = _moduleColors[r.module] ?? Colors.grey;
                            final sameDay = i > 0 &&
                                _sameDay(_items[i - 1].doneAt, r.doneAt);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!sameDay) ...[
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        top: 8, bottom: 4),
                                    child: Text(
                                      '${r.doneAt.year}年${r.doneAt.month}月${r.doneAt.day}日',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: scheme.onSurfaceVariant),
                                    ),
                                  ),
                                ],
                                Card(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  child: ListTile(
                                    onTap: () => _openDetail(r),
                                    onLongPress: () => _confirmDelete(r),
                                    leading: CircleAvatar(
                                      radius: 18,
                                      backgroundColor:
                                          color.withValues(alpha: .15),
                                      child: Text(r.moduleName,
                                          style: TextStyle(
                                              fontSize: 10, color: color)),
                                    ),
                                    title: Text(r.typeName,
                                        style:
                                            const TextStyle(fontSize: 15)),
                                    subtitle: Text(
                                      '${r.doneAt.hour.toString().padLeft(2, '0')}:${r.doneAt.minute.toString().padLeft(2, '0')} · 答对 ${r.correct}/${r.total} · 用时 ${_fmt(r.seconds)}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    trailing: const Icon(
                                        Icons.chevron_right, size: 20),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _fmt(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return m > 0 ? '$m分$s秒' : '$s秒';
  }
}
