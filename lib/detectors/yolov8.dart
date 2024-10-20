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
  static const modelInputSize = 640;
  static const modelOutputSize = 8400;
  static const modelScoreThreshold = 0.4;

  const YoloV8Detector({required super.interpreter, required super.labels});

  @override
  int get inputImageSize => modelInputSize;

  @override
  Future<List<Result>?> detect({required String filePath}) async {
    // Pre-process image
    final data = await compute(
      (path) => copyResizeFile(path, modelInputSize, modelInputSize),
      filePath,
      debugLabel: 'image_process',
    );
    if (data == null) return null;

    // Re-shape data
    final input = data.reshape([1, modelInputSize, modelInputSize, 3]);

    final outputs = {
      _OutputTensor.boxes: List.filled(1 * modelOutputSize * 4, 0.0)
          .reshape([1, modelOutputSize, 4]),
      _OutputTensor.scores:
          List.filled(1 * modelOutputSize, 0.0).reshape([1, modelOutputSize]),
      _OutputTensor.classIdx:
          List.filled(1 * modelOutputSize, 0.0).reshape([1, modelOutputSize]),
    };
    await interpreter.runForMultipleInputs([input], outputs);

    final results = <Result>[];
    for (var i = 0; i < modelOutputSize; ++i) {
      results.add(
        Result(
          box: outputs[_OutputTensor.boxes]![0][i],
          score: outputs[_OutputTensor.scores]![0][i],
          label:
              labels[(outputs[_OutputTensor.classIdx]![0][i] as double).toInt()],
        ),
      );
    }

    // TODO: add post-processing

    return results
        .where((result) => result.score >= modelScoreThreshold)
        .toList();
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
