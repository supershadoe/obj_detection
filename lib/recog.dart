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
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return _RecogImage(
                          constraints: constraints,
                          imageSize: imageSize,
                          imagePath: filePath,
                          results: results,
                        );
                      },
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

class _RecogImage extends StatelessWidget {
  final BoxConstraints constraints;
  final int imageSize;
  final String imagePath;
  final List<Result> results;

  const _RecogImage({
    required this.constraints,
    required this.imageSize,
    required this.imagePath,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    final availableWidth = constraints.maxWidth;
    final availableHeight = constraints.maxHeight;
    // should be 1 because we are just using square images for now.
    final imageAspectRatio = imageSize / imageSize;

    double displayedWidth;
    double displayedHeight;

    final containerAspectRatio = availableWidth / availableHeight;
    if (containerAspectRatio > imageAspectRatio) {
      displayedHeight = availableHeight;
      displayedWidth = availableHeight * imageAspectRatio;
    } else {
      displayedWidth = availableWidth;
      displayedHeight = availableWidth / imageAspectRatio;
    }

    final scale = displayedWidth / imageSize;

    // offset is necessary if the image is already smaller than the
    // available space.
    final offsetX = (availableWidth - displayedWidth) / 2;
    final offsetY = (availableHeight - displayedHeight) / 2;

    return Stack(
      children: [
        Image.file(
          File(imagePath),
          width: imageSize.toDouble(),
          height: imageSize.toDouble(),
          fit: BoxFit.contain,
        ),
        for (final result in results) ...[
          Positioned.fromRect(
            rect: Rect.fromLTWH(
              result.box.left * scale + offsetX,
              result.box.top * scale + offsetY,
              result.box.width * scale,
              result.box.height * scale,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 2),
              ),
            ),
          ),
          Positioned(
            top: result.box.top * scale + offsetY - 24,
            left: result.box.left * scale + offsetX,
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
    );
  }
}
