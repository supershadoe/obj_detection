import 'dart:async' show FutureOr;
import 'package:flutter/material.dart';

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
