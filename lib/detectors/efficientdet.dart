import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/widgets.dart';
import 'package:tflite_flutter/tflite_flutter.dart' show ListShape;

import '../interpreter/api.dart';
import '../interpreter/internals.dart';

class _OutputTensor {
  static const int boxes = 0;
  static const int classes = 1;
  static const int scores = 2;
  static const int numDetections = 3;
}

class EfficientDetDetector extends TFLInterpreter {
  static const _inputSize = 320;
  static const _outputSize = 25;
  static const _scoreThreshold = 0.4;

  @override
  int get inputImageSize => _inputSize;

  const EfficientDetDetector({
    required super.interpreter,
    required super.labels,
  });

  @override
  Future<List<Result>?> detect({required String filePath}) async {
    // Pre-process image
    final data = await compute(
      (path) => copyResizeFile(path, _inputSize, _inputSize),
      filePath,
      debugLabel: 'image_process',
    );
    if (data == null) return null;

    // Re-shape data
    final input = data.reshape([1, _inputSize, _inputSize, 3]);

    final outputs = {
      _OutputTensor.boxes: List.filled(1 * _outputSize * 4, 0.0)
          .reshape([1, _outputSize, 4]),
      _OutputTensor.classes:
          List.filled(1 * _outputSize, 0.0).reshape([1, _outputSize]),
      _OutputTensor.scores:
          List.filled(1 * _outputSize, 0.0).reshape([1, _outputSize]),
      _OutputTensor.numDetections: [0.0],
    };
    await interpreter.runForMultipleInputs([input], outputs);

    final results = <Result>[];
    final numDetections = outputs[_OutputTensor.numDetections]![0] as double;
    for (var i = 0; i < numDetections; ++i) {
      final rawBox = List.castFrom<dynamic, double>(outputs[_OutputTensor.boxes]![0][i]);
      final box = Rect.fromLTWH(
        rawBox[1] * _inputSize,
        rawBox[0] * _inputSize,
        (rawBox[3] - rawBox[1]) * _inputSize,
        (rawBox[2] - rawBox[0]) * _inputSize,
      );
      results.add(
        Result(
          box: box,
          score: outputs[_OutputTensor.scores]![0][i],
          label:
              labels[(outputs[_OutputTensor.classes]![0][i] as double).toInt()],
        ),
      );
    }

    return results
        .where((result) => result.score >= _scoreThreshold)
        .toList();
  }
}

class EfficientDetBuilder extends StatelessWidget {
  final Widget Function(BuildContext) builder;
  const EfficientDetBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return InterpreterBuilder(
      modelPath: 'assets/efficientdet/efficientdet.tflite',
      labelsPath: 'assets/efficientdet/coco-labels-paper.txt',
      detectorBuilder: (interpreter, labels) => EfficientDetDetector(
        interpreter: interpreter,
        labels: labels,
      ),
      builder: builder,
    );
  }
}
