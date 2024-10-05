import 'package:flutter/material.dart';
import 'tfl.dart';
import 'recog.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'tfl_flutter',
      theme: ThemeData(
        textTheme: Typography.blackMountainView.apply(fontFamily: 'Lato'),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 11, 89, 168),
        ),
      ),
      home: InterpreterWidget(
        child: Builder(
          builder: (context) => const RecogScreen(),
        ),
      ),
    );
  }
}
