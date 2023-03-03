import 'dart:async';

import 'package:image_recognition_scanner/image_recognition_scanner.dart';
import 'package:image_recognition_scanner/image_recognition_scanner_platform.dart';

class ImageScannerViewController {
  ImageScannerViewController(this._scannerViewState) {
    ImageRecognitionScannerPlatform.instance.init();
    _connectStreams();
  }

  final ImageScannerViewState _scannerViewState;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
  }

  Future<void> toggleFlashlight({required bool shouldTurnOn}) {
    return ImageRecognitionScannerPlatform.instance.toggleFlashlight(
      shouldTurnOn: shouldTurnOn,
    );
  }

  void _connectStreams() {
    final platformInstance = ImageRecognitionScannerPlatform.instance;
    final scannerViewWidget = _scannerViewState.widget;
    if (scannerViewWidget.onRecognitionStarted != null) {
      _subscriptions.add(
        platformInstance.onRecognitionStarted().listen(
              (event) => _scannerViewState.widget.onRecognitionStarted!(),
            ),
      );
    }
    if (scannerViewWidget.onRecognitionResumed != null) {
      _subscriptions.add(
        platformInstance.onRecognitionResumed().listen(
              (event) => _scannerViewState.widget.onRecognitionResumed!(),
            ),
      );
    }
    if (scannerViewWidget.onRecognitionPaused != null) {
      _subscriptions.add(
        platformInstance.onRecognitionPaused().listen(
              (event) => _scannerViewState.widget.onRecognitionPaused!(),
            ),
      );
    }
    if (scannerViewWidget.onError != null) {
      _subscriptions.add(
        platformInstance.onError().listen(
              (event) => _scannerViewState.widget.onError!(event.error),
            ),
      );
    }

    _subscriptions.add(
      platformInstance.onImageDetected().listen(
            (event) => scannerViewWidget.onImageDetected(event.imageName),
          ),
    );
  }
}
