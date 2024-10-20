import 'package:flutter/widgets.dart';
import 'package:tflite_flutter/tflite_flutter.dart' show IsolateInterpreter;

class Result {
  final List<double> box;
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

abstract class TFLInterpreter {
  final IsolateInterpreter interpreter;
  final List<String> labels;

  const TFLInterpreter({required this.interpreter, required this.labels});

  int get inputImageSize;

  Future<List<Result>?> detect({required String filePath});

  @override
  bool operator ==(Object other) =>
      other is TFLInterpreter &&
      interpreter.address == other.interpreter.address &&
      labels == other.labels;

  @override
  int get hashCode => Object.hash(interpreter, labels);
}

class InterpreterWidget extends InheritedWidget {
  final TFLInterpreter interpreter;

  const InterpreterWidget({
    super.key,
    required this.interpreter,
    required super.child,
  });

  static TFLInterpreter? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<InterpreterWidget>()
        ?.interpreter;
  }

  static TFLInterpreter of(BuildContext context) {
    final result = maybeOf(context);
    assert(
      result != null,
      'InterpreterWidget was not found in the widget tree.',
    );
    return result!;
  }

  @override
  bool updateShouldNotify(InterpreterWidget oldWidget) =>
      oldWidget.interpreter != interpreter;
}
