import 'package:flutter/widgets.dart' show Rect;

import 'package:tflite_flutter/tflite_flutter.dart' show IsolateInterpreter;

class Result {
  final Rect box;
  final double score;
  final String label;

  const Result({
    required this.box,
    required this.score,
    required this.label,
  });

  @override
  String toString() => 'Result(box: $box, score: $score, label: $label)';
}

abstract class Detector {
  final IsolateInterpreter interpreter;
  final List<String> labels;

  const Detector({required this.interpreter, required this.labels});

  int get inputImageSize;

  Future<List<Result>?> detect({required String filePath});

  @override
  bool operator ==(Object other) =>
      other is Detector &&
      interpreter.address == other.interpreter.address &&
      labels == other.labels;

  @override
  int get hashCode => Object.hash(interpreter, labels);
}
