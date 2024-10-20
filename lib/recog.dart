import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'interpreter/api.dart' show InterpreterWidget, Result;
import 'widgets.dart';

class RecogScreen extends StatefulWidget {
  final String modelName;
  const RecogScreen({super.key, required this.modelName});

  @override
  State<RecogScreen> createState() => _RecogScreenState();
}

class _RecogScreenState extends State<RecogScreen> {
  var filePath = '';
  var results = <Result>[];
  var error = false;
  late final ImagePicker picker;

  @override
  void initState() {
    super.initState();
    picker = ImagePicker();
  }

  Future<void> _onPress(
    BuildContext context,
    ImagePicker picker,
    ImageSource source,
  ) async {
    final image = await picker.pickImage(source: source);
    if (image == null || !context.mounted) return;
    setState(() {
      filePath = image.path;
      results = [];
      error = false;
    });
    final tflResult =
        await InterpreterWidget.of(context).detect(filePath: image.path);
    if (!context.mounted || filePath.isEmpty) return;
    setState(() {
      error = tflResult == null;
      results = tflResult ?? const [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final imageSize = InterpreterWidget.of(context).inputImageSize;

    return PopScope(
      canPop: filePath.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          setState(() {
            error = false;
            results = [];
            filePath = '';
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.modelName),
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Find objects in image.',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconTextButton(
                      text: 'Take picture',
                      icon: Icons.camera_outlined,
                      onPressed: () =>
                          _onPress(context, picker, ImageSource.camera),
                    ),
                    const SizedBox(height: 8),
                    IconTextButton(
                      text: 'Select image',
                      icon: Icons.photo_album_outlined,
                      onPressed: () =>
                          _onPress(context, picker, ImageSource.gallery),
                    ),
                  ],
                ),
              ),
              if (filePath.isNotEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Text(
                      'Detection results',
                      style: TextStyle(
                        fontSize: 20,
                        height: 1.25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              if (filePath.isNotEmpty)
                Expanded(
                  child: Center(
                    child: Stack(
                      children: [
                        Image.file(
                          File(filePath),
                          width: imageSize.toDouble(),
                          height: imageSize.toDouble(),
                          fit: BoxFit.fill,
                        ),
                        for (final result in results) ...[
                          Positioned.fromRect(
                            rect: result.box,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.red),
                              ),
                            ),
                          ),
                          Positioned(
                            top: result.box.top - 24,
                            left: result.box.left,
                            child: Container(
                              color: Colors.amber,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                '${result.label} '
                                '(${(result.score * 100).toStringAsFixed(2)}%)',
                                style: const TextStyle(
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
