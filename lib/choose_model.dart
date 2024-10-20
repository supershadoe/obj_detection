import 'package:flutter/material.dart';

import 'detectors/efficientdet.dart';
import 'detectors/yolov8.dart';
import 'recog.dart';

class ChooseModelScreen extends StatelessWidget {
  const ChooseModelScreen({super.key});

  void navigate(
    BuildContext context,
    Widget Function(BuildContext) builder,
  ) {
    Navigator.of(context).push(MaterialPageRoute(builder: builder));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Obj detection'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose the model to test.',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => navigate(
                      context,
                      (context) => EfficientDetBuilder(
                        builder: (context) =>
                            const RecogScreen(modelName: 'EfficientDet'),
                      ),
                    ),
                    child: const Text('EfficientDet'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => navigate(
                      context,
                      (context) => YoloV8Builder(
                        builder: (context) =>
                            const RecogScreen(modelName: 'YOLOv8'),
                      ),
                    ),
                    child: const Text('YOLOv8'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
