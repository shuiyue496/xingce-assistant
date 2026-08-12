import 'package:flutter/material.dart';

import '../../generators/data_generator.dart';
import '../../widgets/type_item.dart';
import '../type_screen.dart';

class DataTypeScreen extends StatelessWidget {
  const DataTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TypeScreen(
      module: 'data',
      moduleName: '资料分析专项',
      types: [
        for (final t in DataGenerator.types) TypeItem(t.id, t.name, t.subtitle),
      ],
      generator: (id, n, custom) => DataGenerator.generate(id, n),
      showKeypadSwitch: true,
      showFastFeedback: true,
      defaultCount: 10,
      quickCounts: const [10, 15],
    );
  }
}
