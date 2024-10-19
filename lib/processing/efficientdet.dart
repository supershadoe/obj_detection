import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart'
    show IsolateInterpreter, ListShape;

import '../utils.dart'
    show InterpreterLoader, Result, TFLInterpreter, copyResizeFile;

class _OutputTensor {
  static const int boxes = 0;
  static const int scores = 1;
  static const int classes = 2;
  static const int numDetections = 3;
}

class EfficientDetDetector extends TFLInterpreter {
  static const modelInputSize = 320;
  static const modelOutputSize = 25;
  static const modelScoreThreshold = 0.4;

  @override
  int get inputImageSize => modelInputSize;

  const EfficientDetDetector({
    super.key,
    required super.interpreter,
    required super.labels,
    required super.child,
  });

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
      _OutputTensor.classes:
          List.filled(1 * modelOutputSize, 0.0).reshape([1, modelOutputSize]),
      _OutputTensor.numDetections: [0.0],
    };
    await interpreter.runForMultipleInputs([input], outputs);

    final results = <Result>[];
    final numDetections = outputs[_OutputTensor.numDetections]![0] as double;
    for (var i = 0; i < numDetections; ++i) {
      results.add(
        Result(
          box: outputs[_OutputTensor.boxes]![0][i],
          score: outputs[_OutputTensor.classes]![0][i],
          label:
              labels[(outputs[_OutputTensor.scores]![0][i] as double).toInt()],
        ),
      );
    }

    return results
        .where((result) => result.score >= modelScoreThreshold)
        .toList();
  }
}

class EfficientDetLoader extends StatefulWidget {
  final Widget child;
  const EfficientDetLoader({super.key, required this.child});

  @override
  State<EfficientDetLoader> createState() => _EfficientDetLoaderState();
}

class _EfficientDetLoaderState extends State<EfficientDetLoader>
    with InterpreterLoader {
  @override
  final modelPath = 'assets/efficientdet/efficientdet.tflite';
  @override
  final labelsPath = 'assets/efficientdet/coco-labels-paper.txt';

  late final Future<(IsolateInterpreter, List<String>)> _future;

  @override
  void initState() {
    super.initState();
    _future = loadDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('${snapshot.error}'));
        }
        return EfficientDetDetector(
          interpreter: snapshot.requireData.$1,
          labels: snapshot.requireData.$2,
          child: widget.child,
        );
      },
    );
  }
}
