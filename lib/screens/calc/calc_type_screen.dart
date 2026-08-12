import 'package:flutter/material.dart';

import '../../generators/calc_generator.dart';
import '../../widgets/type_item.dart';
import '../type_screen.dart';

class CalcTypeScreen extends StatelessWidget {
  const CalcTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TypeScreen(
      module: 'calc',
      moduleName: '基础计算练习',
      types: [
        for (final t in CalcGenerator.types) TypeItem(t.id, t.name, t.subtitle),
      ],
      generator: (id, n, _) => CalcGenerator.generate(id, n),
      showExport: true,
      showKeypadSwitch: true,
      defaultCount: 10,
      quickCounts: const [10, 15],
    );
  }
}
