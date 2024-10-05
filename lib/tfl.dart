import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' show copyResize, decodeImageFile;
import 'package:tflite_flutter/tflite_flutter.dart';

const modelInputSize = 320;
const modelOutputSize = 25;
const modelScoreThreshold = 0.4;

class ModelTensor {
  static const int boxes = 0;
  static const int scores = 1;
  static const int classes = 2;
  static const int numDetections = 3;
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

class TFLInterpreter extends InheritedWidget {
  final IsolateInterpreter interpreter;
  final List<String> labels;

  const TFLInterpreter({
    super.key,
    required this.interpreter,
    required this.labels,
    required super.child,
  });

  static Future<Uint8List?> _processImage(String filePath) async {
    final decoded = await decodeImageFile(filePath);
    if (decoded == null) return null;
    return copyResize(
      decoded,
      width: modelInputSize,
      height: modelInputSize,
      maintainAspect: false,
    ).getBytes();
  }

  Future<List<Result>?> detect({required String filePath}) async {
    final data =
        await compute(_processImage, filePath, debugLabel: 'image_process');
    if (data == null) return null;
    final input = data.reshape([1, modelInputSize, modelInputSize, 3]);
    final outputs = {
      ModelTensor.boxes: List.filled(1 * modelOutputSize * 4, 0.0)
          .reshape([1, modelOutputSize, 4]),
      ModelTensor.scores:
          List.filled(1 * modelOutputSize, 0.0).reshape([1, modelOutputSize]),
      ModelTensor.classes:
          List.filled(1 * modelOutputSize, 0.0).reshape([1, modelOutputSize]),
      ModelTensor.numDetections: [0.0],
    };
    await interpreter.runForMultipleInputs([input], outputs);
    final results = <Result>[];
    for (var i = 0; i < outputs[ModelTensor.numDetections]![0]; ++i) {
      results.add(
        Result(
          box: outputs[ModelTensor.boxes]![0][i],
          score: outputs[ModelTensor.classes]![0][i],
          label: labels[(outputs[ModelTensor.scores]![0][i] as double).toInt()],
        ),
      );
    }
    return results
        .where((result) => result.score >= modelScoreThreshold)
        .toList();
  }

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

class InterpreterWidget extends StatefulWidget {
  final Widget child;
  const InterpreterWidget({super.key, required this.child});

  @override
  State<InterpreterWidget> createState() => _InterpreterWidgetState();
}

class _InterpreterWidgetState extends State<InterpreterWidget> {
  late final Future<(IsolateInterpreter, List<String>)> _future;

  @override
  void initState() {
    super.initState();
    _future = loadDependencies();
  }

  Future<IsolateInterpreter> loadInterpreter() async {
    final interpreter = await Interpreter.fromAsset(
      'assets/efficientdet.tflite',
    );
    return IsolateInterpreter.create(address: interpreter.address);
  }

  Future<List<String>> loadLabels() async {
    final labels = await rootBundle
        .loadString('assets/labels.txt')
        .then((data) => data.split(RegExp(r'[\r\n]')));
    return labels;
  }

  Future<(IsolateInterpreter, List<String>)> loadDependencies() async =>
      (await loadInterpreter(), await loadLabels());

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
        return TFLInterpreter(
          interpreter: snapshot.requireData.$1,
          labels: snapshot.requireData.$2,
          child: widget.child,
        );
      },
    );
  }
}
