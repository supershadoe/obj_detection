import 'dart:async' show FutureOr;

import 'package:flutter/services.dart' show Uint8List, rootBundle;
import 'package:image/image.dart' show copyResize, decodeImageFile;

import 'package:tflite_flutter/tflite_flutter.dart'
    show IsolateInterpreter, Interpreter;

import 'api.dart' show Detector;

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

Future<List<String>> loadSimpleLabelsFile(String labelsPath) => rootBundle
    .loadString(labelsPath)
    .then((data) => data.split(RegExp(r'[\r\n]')));

Future<T> loadDetector<T extends Detector>({
  required String modelPath,
  required String labelsPath,
  required FutureOr<List<String>> Function(String labelsPath) labelsLoader,
  required T Function({
    required IsolateInterpreter interpreter,
    required List<String> labels,
  }) builder,
}) async {
  final interpreter = await Interpreter.fromAsset(modelPath);
  final isolateInterpreter =
      await IsolateInterpreter.create(address: interpreter.address);

  final labels = await labelsLoader(labelsPath);

  return builder(interpreter: isolateInterpreter, labels: labels);
}
