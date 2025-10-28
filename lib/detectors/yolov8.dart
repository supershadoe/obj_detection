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

    final areas = outputs
        .map((op) => op.box.width * op.box.height)
        .toList(growable: false);
    final picked = <int>[];

    for (final (i, candidate) in outputs.indexed) {
      var keep = true;
      final candidateArea = areas[i];
      for (final j in picked) {
        final pickedBox = outputs[j];

        if (candidate.label != pickedBox.label) continue;

        final pickedArea = areas[j];

        final intersectRect = candidate.box.intersect(pickedBox.box);
        final intersectArea = intersectRect.width * intersectRect.height;

        final unionArea = candidateArea + pickedArea - intersectArea;

        final iou = intersectArea / unionArea;

        if (unionArea > 0 && iou > _iouThreshold) {
          keep = false;
          break;
        }
      }
      if (keep) {
        picked.add(i);
      }
    }

    return picked.map((i) => outputs[i]).toList();
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
