import 'package:flutter/material.dart';

import '../../generators/seq_generator.dart';
import '../../widgets/type_item.dart';
import '../type_screen.dart';

class SeqTypeScreen extends StatelessWidget {
  const SeqTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TypeScreen(
      module: 'seq',
      moduleName: '数字推理训练',
      types: [
        for (final t in SeqGenerator.types) TypeItem(t.id, t.name, t.subtitle),
      ],
      generator: (id, n, custom) => SeqGenerator.generate(id, n),
      showKeypadSwitch: false,
      defaultCount: 10,
      quickCounts: const [10, 15],
    );
  }
}
