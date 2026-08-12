import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../models/question.dart';
import '../widgets/type_item.dart';
import 'history_screen.dart';
import 'quiz_screen.dart';

typedef QuestionGenerator =
    List<Question> Function(String typeId, int count, Map<String, String> custom);

/// Shared type-selection + config page for all three modules.
class TypeScreen extends StatefulWidget {
  final String module; // 'calc' | 'data' | 'seq'
  final String moduleName;
  final List<TypeItem> types;
  final QuestionGenerator generator;
  final bool showExport; // calc module exports the generated sheet
  final bool showKeypadSwitch;
  final bool showFastFeedback;
  final int defaultCount;
  final List<int> quickCounts; // e.g. [10, 15]

  const TypeScreen({
    super.key,
    required this.module,
    required this.moduleName,
    required this.types,
    required this.generator,
    this.showExport = false,
    this.showKeypadSwitch = true,
    this.showFastFeedback = false,
    this.defaultCount = 10,
    this.quickCounts = const [10, 15],
  });

  @override
  State<TypeScreen> createState() => _TypeScreenState();
}

class _TypeScreenState extends State<TypeScreen> {
  String _selectedId = '';
  String _sort = 'asc'; // asc | desc | shuffle
  int _count = 10;
  bool _customCount = false;
  bool _useKeypad = true;
  bool _fastFeedback = false;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.types.first.id;
    _count = widget.defaultCount;
  }

  List<Question> _generate() {
    final base = widget.generator(_selectedId, _count, const {});
    switch (_sort) {
      case 'desc':
        return base.reversed.toList();
      case 'shuffle':
        return (base..shuffle());
      default:
        return base;
    }
  }

  void _start() {
    final qs = _generate();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => QuizScreen(
        module: widget.module,
        moduleName: widget.moduleName,
        typeName: _selectedType.name,
        questions: qs,
        fastFeedback: widget.showFastFeedback && _fastFeedback,
        useKeypad: widget.showKeypadSwitch ? _useKeypad : true,
      ),
    ));
  }

  Future<void> _export() async {
    final qs = _generate();
    final buf = StringBuffer()
      ..writeln('【${widget.moduleName} · ${_selectedType.name}】${qs.length} 题')
      ..writeln();
    for (var i = 0; i < qs.length; i++) {
      final q = qs[i];
      buf.writeln('${i + 1}. ${q.prompt.replaceAll('\n', ' ')}');
      buf.writeln('   答案：${q.answerText}');
      if (q.explanation.isNotEmpty) buf.writeln('   解析：${q.explanation}');
      buf.writeln();
    }
    await Share.share(buf.toString(), subject: '行测速算题目');
  }

  TypeItem get _selectedType =>
      widget.types.firstWhere((t) => t.id == _selectedId);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.moduleName),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: '历史记录',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.4,
                  children: [
                    for (final t in widget.types)
                      _TypeCard(
                        item: t,
                        selected: t.id == _selectedId,
                        onTap: () => setState(() => _selectedId = t.id),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('排序方式'),
                        const SizedBox(height: 8),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'asc', label: Text('正序')),
                            ButtonSegment(value: 'desc', label: Text('倒序')),
                            ButtonSegment(value: 'shuffle', label: Text('乱序')),
                          ],
                          selected: {_sort},
                          onSelectionChanged: (s) =>
                              setState(() => _sort = s.first),
                        ),
                        const SizedBox(height: 16),
                        _sectionTitle('题量'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final c in widget.quickCounts)
                              ChoiceChip(
                                label: Text(c == widget.quickCounts.first ? '快速($c题)' : '正常($c题)'),
                                selected: !_customCount && _count == c,
                                onSelected: (_) => setState(() {
                                  _customCount = false;
                                  _count = c;
                                }),
                              ),
                            ChoiceChip(
                              label: const Text('自定义'),
                              selected: _customCount,
                              onSelected: (_) => setState(() {
                                _customCount = true;
                                _count = 20;
                              }),
                            ),
                          ],
                        ),
                        if (_customCount) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Slider(
                                  min: 5,
                                  max: 100,
                                  divisions: 95,
                                  value: _count.toDouble(),
                                  label: '$_count',
                                  onChanged: (v) =>
                                      setState(() => _count = v.round()),
                                ),
                              ),
                              Text('$_count 题'),
                            ],
                          ),
                        ],
                        if (widget.showKeypadSwitch) ...[
                          const SizedBox(height: 12),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('自定义数字键盘'),
                            subtitle: const Text('关闭则使用系统键盘'),
                            value: _useKeypad,
                            onChanged: (v) => setState(() => _useKeypad = v),
                          ),
                        ],
                        if (widget.showFastFeedback) ...[
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('快速反馈'),
                            subtitle: const Text('答错立即弹窗显示正确答案与误差'),
                            value: _fastFeedback,
                            onChanged: (v) => setState(() => _fastFeedback = v),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _start,
                      icon: const Icon(Icons.play_arrow),
                      label: Text('开始练习（${_selectedType.name}）'),
                      style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14)),
                    ),
                  ),
                  if (widget.showExport) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _export,
                        icon: const Icon(Icons.ios_share, size: 18),
                        label: const Text('导出题目'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String s) => Text(s,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600));
}

class _TypeCard extends StatelessWidget {
  final TypeItem item;
  final bool selected;
  final VoidCallback onTap;

  const _TypeCard(
      {required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: selected ? scheme.primaryContainer : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 1.6 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
                  )),
              const SizedBox(height: 2),
              Text(item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11, color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}
