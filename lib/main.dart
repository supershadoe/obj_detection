import 'package:flutter/material.dart';
import 'detectors/efficientdet.dart';
import 'recog.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'obj_detection',
      theme: ThemeData(
        textTheme: Typography.blackMountainView.apply(fontFamily: 'Lato'),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 11, 89, 168),
        ),
      ),
      home: EfficientDetBuilder(builder: (context) => const RecogScreen()),
    );
  }
}
