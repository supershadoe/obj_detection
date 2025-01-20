# obj_detection

This app serves as a demo of the [tflite_flutter](https://pub.dev/packages/tflite_flutter)
package in flutter for object detection.

The repo has demo of two models - [EfficientDet](https://www.kaggle.com/models/tensorflow/efficientdet/tfLite/lite0-detection-metadata/1)
and [YOLOv8-Detection](https://huggingface.co/qualcomm/YOLOv8-Detection)

Labels for the dataset were taken from [here](https://github.com/amikelive/coco-labels)

For YOLOv8, post-processing was attempted to be done entirely using dart without
any external dependencies. (**Did not really accomplish that, it's still a WIP**)

## How to run
1. Install Flutter by following the [docs](https://docs.flutter.dev/get-started/install)
2. Clone this repo.
3. Run `flutter pub get` in the project folder
4. Run `flutter run` or `flutter build apk` to either run on an
emulator/device or generate an APK file to install on any device.
