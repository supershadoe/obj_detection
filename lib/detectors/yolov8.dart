import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/widgets.dart';
import 'package:tflite_flutter/tflite_flutter.dart' show ListShape;

import '../interpreter/api.dart';
import '../interpreter/internals.dart';

class _OutputTensor {
  static const int boxes = 0;
  static const int scores = 1;
  static const int classIdx = 2;
}

class YoloV8Detector extends TFLInterpreter {
  static const _inputSize = 640;
  static const _outputSize = 8400;
  static const _scoreThreshold = 0.7;
  static const _iouThreshold = 0.4;

  const YoloV8Detector({required super.interpreter, required super.labels});

  @override
  int get inputImageSize => _inputSize;

  /// Implements non-maximum suppression to filter out similar bounding boxes
  /// of same class and remove boxes that do not cross the confidence
  /// threshold.
  List<Result> _postProcessUsingNMS(List<Result> modelOutput) {
    // Filter and Sort by score
    final outputs = modelOutput
        .where((op) => op.score >= _scoreThreshold)
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    // To mark which elements to keep
    final keep = List<bool?>.filled(outputs.length, null);

    while (keep.any((e) => e == null)) {
      for (final (i, r1) in outputs.indexed) {
        if (keep[i] != null) continue;

        keep[i] = true;

        final area = r1.box.width * r1.box.height;

        for (final (j, r2) in outputs.indexed) {
          // Skip the previous boxes and match only boxes of same class
          // after current box
          if (j <= i || keep[j] != null || r1.label != r2.label) continue;

          final pickedArea = r2.box.width * r2.box.height;

          final intersectRect = r1.box.intersect(r2.box);
          final intersectArea = intersectRect.width * intersectRect.height;

          final unionArea = area + pickedArea - intersectArea;
          final iou = intersectArea / unionArea;

          if (iou > _iouThreshold) {
            keep[j] = false;
          }
        }
      }
    }

    return outputs.indexed
        .where((e) => keep[e.$1] ?? false)
        .map((e) => e.$2)
        .toList();
  }

  @override
  Future<List<Result>?> detect({required String filePath}) async {
    // Pre-process image
    final data = await compute(
      (path) => copyResizeFile(path, _inputSize, _inputSize),
      filePath,
      debugLabel: 'image_process',
    );
    if (data == null) return null;

    // Normalize and reshape data
    final input = data
        .map((pixel) => pixel / 255.0)
        .toList()
        .reshape([1, _inputSize, _inputSize, 3]);

    final outputs = {
      _OutputTensor.boxes:
          List.filled(1 * _outputSize * 4, 0.0).reshape([1, _outputSize, 4]),
      _OutputTensor.scores:
          List.filled(1 * _outputSize, 0.0).reshape([1, _outputSize]),
      _OutputTensor.classIdx:
          List.filled(1 * _outputSize, 0.0).reshape([1, _outputSize]),
    };
    await interpreter.runForMultipleInputs([input], outputs);

    final results = <Result>[];
    for (var i = 0; i < _outputSize; ++i) {
      final rawBox =
          List.castFrom<dynamic, double>(outputs[_OutputTensor.boxes]![0][i]);
      final box = Rect.fromLTRB(rawBox[0], rawBox[1], rawBox[2], rawBox[3]);
      results.add(
        Result(
          box: box,
          score: outputs[_OutputTensor.scores]![0][i],
          label: labels[
              (outputs[_OutputTensor.classIdx]![0][i] as double).toInt()],
        ),
      );
    }

    return _postProcessUsingNMS(results);
  }
}

class YoloV8Builder extends StatelessWidget {
  final Widget Function(BuildContext) builder;
  const YoloV8Builder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return InterpreterBuilder(
      modelPath: 'assets/yolov8-detection/YOLOv8-Detection.tflite',
      labelsPath: 'assets/yolov8-detection/coco-labels-2014_2017.txt',
      detectorBuilder: (interpreter, labels) =>
          YoloV8Detector(interpreter: interpreter, labels: labels),
      builder: builder,
    );
  }
}
