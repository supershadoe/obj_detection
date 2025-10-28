import 'dart:async' show FutureOr;

import 'package:flutter/material.dart';

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

