import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' show copyResize, decodeImageFile;
import 'package:tflite_flutter/tflite_flutter.dart';

Future<Uint8List?> copyResizeFile(
  String filePath, [
  int? width,
  int? height,
]) async {
  final decoded = await decodeImageFile(filePath);
  if (decoded == null) return null;
  return copyResize(
    decoded,
    width: width,
    height: height,
    maintainAspect: false,
  ).getBytes();
}

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

abstract class TFLInterpreter extends InheritedWidget {
  final IsolateInterpreter interpreter;
  final List<String> labels;

  const TFLInterpreter({
    super.key,
    required this.interpreter,
    required this.labels,
    required super.child,
  });

  int get inputImageSize;

  Future<List<Result>?> detect({required String filePath});

  static TFLInterpreter? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<TFLInterpreter>();
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
  bool updateShouldNotify(TFLInterpreter oldWidget) =>
      oldWidget.interpreter.address != interpreter.address;
}

mixin InterpreterLoader {
  String get modelPath;
  String get labelsPath;

  Future<IsolateInterpreter> _loadInterpreter() async {
    final interpreter = await Interpreter.fromAsset(modelPath);
    return IsolateInterpreter.create(address: interpreter.address);
  }

  Future<List<String>> _loadLabels() async {
    final labels = await rootBundle
        .loadString(labelsPath)
        .then((data) => data.split(RegExp(r'[\r\n]')));
    return labels;
  }

  Future<(IsolateInterpreter, List<String>)> loadDependencies() async =>
      (await _loadInterpreter(), await _loadLabels());
}
