import 'package:flutter/material.dart';

enum NumpadMode { docked, floating, system }

/// Draggable custom numeric keypad (standard 1-9 keypad layout).
/// Dock at the bottom by default; can float (drag anywhere) or switch to
/// the system keyboard.
class CustomNumpad extends StatefulWidget {
  final NumpadMode mode;
  final bool enabled; // false while a brief feedback strip is showing
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final VoidCallback onRestart;
  final VoidCallback onSubmit;
  final ValueChanged<NumpadMode> onModeChanged;

  const CustomNumpad({
    super.key,
    required this.mode,
    this.enabled = true,
    required this.onDigit,
    required this.onBackspace,
    required this.onClear,
    required this.onRestart,
    required this.onSubmit,
    required this.onModeChanged,
  });

  @override
  State<CustomNumpad> createState() => _CustomNumpadState();
}

class _CustomNumpadState extends State<CustomNumpad> {
  Offset _pos = const Offset(24, 260);
  final double _floatW = 210;

  @override
  Widget build(BuildContext context) {
    if (widget.mode == NumpadMode.system) return const SizedBox.shrink();
    if (widget.mode == NumpadMode.floating) return _buildFloating(context);
    return _buildDocked(context);
  }

  Widget _buildDocked(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: scheme.surfaceContainerHigh,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => widget.onModeChanged(NumpadMode.system),
                  icon: const Icon(Icons.keyboard_alt_outlined, size: 18),
                  label: const Text('系统键盘'),
                ),
                TextButton.icon(
                  onPressed: () => widget.onModeChanged(NumpadMode.floating),
                  icon: const Icon(Icons.open_with, size: 18),
                  label: const Text('悬浮'),
                ),
              ],
            ),
            _buildKeys(context, docked: true),
          ],
        ),
      ),
    );
  }

  Widget _buildFloating(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Positioned(
          left: _pos.dx,
          top: _pos.dy,
          child: GestureDetector(
            onPanUpdate: (d) => setState(() {
              _pos = Offset(
                (_pos.dx + d.delta.dx).clamp(
                    0, MediaQuery.sizeOf(context).width - _floatW),
                (_pos.dy + d.delta.dy).clamp(
                    0, MediaQuery.sizeOf(context).height - 240),
              );
            }),
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(14),
              color: scheme.surfaceContainerHigh,
              child: Container(
                width: _floatW,
                padding: const EdgeInsets.all(6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.drag_indicator,
                            size: 16, color: scheme.onSurfaceVariant),
                        const Spacer(),
                        InkWell(
                          onTap: () => widget.onModeChanged(NumpadMode.system),
                          child: Icon(Icons.keyboard_alt_outlined,
                              size: 16, color: scheme.onSurfaceVariant),
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: () => widget.onModeChanged(NumpadMode.docked),
                          child: Icon(Icons.close,
                              size: 16, color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    _buildKeys(context, docked: false),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeys(BuildContext context, {required bool docked}) {
    final scheme = Theme.of(context).colorScheme;
    final btnH = docked ? 46.0 : 30.0;
    final gap = docked ? 6.0 : 3.0;

    Widget key(String label,
        {VoidCallback? onTap,
        Widget? child,
        Color? bg,
        Color? fg,
        FontWeight? fw,
        double? fs}) {
      return Expanded(
        child: Padding(
          padding: EdgeInsets.all(gap / 2),
          child: Material(
            color: bg ?? scheme.surface,
            borderRadius: BorderRadius.circular(docked ? 10 : 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(docked ? 10 : 8),
              onTap: widget.enabled ? onTap : null,
              child: SizedBox(
                height: btnH,
                child: Center(
                  child: child ??
                      Text(label,
                          style: TextStyle(
                            fontSize: fs ?? (docked ? 22 : 15),
                            fontWeight: fw ?? FontWeight.w600,
                            color: fg ?? scheme.onSurface,
                          )),
                ),
              ),
            ),
          ),
        ),
      );
    }

    Widget fnKey(String label, IconData icon, VoidCallback onTap) {
      return key(label,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: docked ? 18 : 13, color: scheme.primary),
              if (docked) ...[
                const SizedBox(width: 4),
                Text(label,
                    style: TextStyle(fontSize: 13, color: scheme.primary)),
              ],
            ],
          ),
          bg: scheme.primaryContainer.withValues(alpha: .5),
          onTap: onTap);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // function row: 重开 / 清空 / 退格
        Row(
          children: [
            fnKey('重开', Icons.refresh, widget.onRestart),
            fnKey('清空', Icons.backspace_outlined, widget.onClear),
            fnKey('退格', Icons.keyboard_backspace, widget.onBackspace),
          ],
        ),
        // standard keypad: 1-9 top-to-bottom
        for (final r in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Row(
            children: [
              for (final k in r)
                key(k, onTap: () => widget.onDigit(k)),
            ],
          ),
        // bottom row: . / 0 / 确定
        Row(
          children: [
            key('.', onTap: () => widget.onDigit('.')),
            key('0', onTap: () => widget.onDigit('0')),
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(gap / 2),
                child: SizedBox(
                  height: btnH,
                  child: FilledButton(
                    onPressed: widget.enabled ? widget.onSubmit : null,
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(docked ? 10 : 8)),
                    ),
                    child: const Text('确定',
                        style:
                            TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
