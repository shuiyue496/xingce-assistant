import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const XingceApp());
}

class XingceApp extends StatelessWidget {
  const XingceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '行测小助手',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const HomeScreen(),
    );
  }
}
