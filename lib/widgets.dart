import 'dart:async' show FutureOr;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:tflite_flutter/tflite_flutter.dart'
    show Interpreter, IsolateInterpreter;

import 'api.dart' show Detector;

class IconTextButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final FutureOr<void> Function() onPressed;
  const IconTextButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 8),
            child: Text(text),
          ),
        ],
      ),
    );
  }
}

class DetectorWrapper extends InheritedWidget {
  final Detector interpreter;

  const DetectorWrapper({
    super.key,
    required this.interpreter,
    required super.child,
  });

  static Detector? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<DetectorWrapper>()
        ?.interpreter;
  }

  static Detector of(BuildContext context) {
    final result = maybeOf(context);
    assert(
      result != null,
      'InterpreterWidget was not found in the widget tree.',
    );
    return result!;
  }

  @override
  bool updateShouldNotify(DetectorWrapper oldWidget) =>
      oldWidget.interpreter != interpreter;
}

class DetectorBuilder extends StatefulWidget {
  final String modelPath;
  final String labelsPath;
  final Detector Function(
    IsolateInterpreter interpreter,
    List<String> labels,
  ) detectorBuilder;
  final Widget Function(BuildContext context) builder;

  const DetectorBuilder({
    super.key,
    required this.modelPath,
    required this.labelsPath,
    required this.detectorBuilder,
    required this.builder,
  });

  @override
  State<DetectorBuilder> createState() => _DetectorBuilderState();
}

class _DetectorBuilderState extends State<DetectorBuilder> {
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
        return DetectorWrapper(
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
