import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' show copyResize, decodeImageFile;
import 'package:tflite_flutter/tflite_flutter.dart'
    show Interpreter, IsolateInterpreter;

import 'api.dart';

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

class InterpreterBuilder extends StatefulWidget {
  final String modelPath;
  final String labelsPath;
  final TFLInterpreter Function(
    IsolateInterpreter interpreter,
    List<String> labels,
  ) detectorBuilder;
  final Widget Function(BuildContext context) builder;

  const InterpreterBuilder({
    super.key,
    required this.modelPath,
    required this.labelsPath,
    required this.detectorBuilder,
    required this.builder,
  });

  @override
  State<InterpreterBuilder> createState() => _InterpreterBuilderState();
}

class _InterpreterBuilderState extends State<InterpreterBuilder> {
  late final Future<(IsolateInterpreter, List<String>)> _future;

  @override
  void initState() {
    super.initState();
    _future = loadDependencies();
  }

  @override
  void dispose() {
    _future.ignore();
    super.dispose();
  }

  Future<IsolateInterpreter> _loadInterpreter() async {
    final interpreter = await Interpreter.fromAsset(widget.modelPath);
    return IsolateInterpreter.create(address: interpreter.address);
  }

  Future<List<String>> _loadLabels() async {
    final labels = await rootBundle
        .loadString(widget.labelsPath)
        .then((data) => data.split(RegExp(r'[\r\n]')));
    return labels;
  }

  Future<(IsolateInterpreter, List<String>)> loadDependencies() async =>
      (await _loadInterpreter(), await _loadLabels());

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
        return InterpreterWidget(
          interpreter: widget.detectorBuilder(
            snapshot.requireData.$1,
            snapshot.requireData.$2,
          ),
          child: widget.builder(context),
        );
      },
    );
  }
}
