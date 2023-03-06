import 'dart:async';

import 'package:ar_quido/ar_quido.dart';

class ARQuidoViewController {
  ARQuidoViewController(this._scannerViewState) {
    ARQuidoPlatform.instance.init();
    _connectStreams();
  }

  final ARQuidoViewState _scannerViewState;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
  }

  Future<void> toggleFlashlight({required bool shouldTurnOn}) {
    return ARQuidoPlatform.instance.toggleFlashlight(
      shouldTurnOn: shouldTurnOn,
    );
  }

  void _connectStreams() {
    final platformInstance = ARQuidoPlatform.instance;
    final scannerViewWidget = _scannerViewState.widget;
    if (scannerViewWidget.onRecognitionStarted != null) {
      _subscriptions.add(
        platformInstance.onRecognitionStarted().listen((event) => _scannerViewState.widget.onRecognitionStarted!()),
      );
    }
    if (scannerViewWidget.onRecognitionResumed != null) {
      _subscriptions.add(
        platformInstance.onRecognitionResumed().listen((event) => _scannerViewState.widget.onRecognitionResumed!()),
      );
    }
    if (scannerViewWidget.onRecognitionPaused != null) {
      _subscriptions.add(
        platformInstance.onRecognitionPaused().listen((event) => _scannerViewState.widget.onRecognitionPaused!()),
      );
    }
    if (scannerViewWidget.onError != null) {
      _subscriptions.add(
        platformInstance.onError().listen((event) => _scannerViewState.widget.onError!(event.error)),
      );
    }
    if (scannerViewWidget.onDetectedImageTapped != null) {
      _subscriptions.add(
        platformInstance
            .onDetectedImageTapped()
            .listen((event) => scannerViewWidget.onDetectedImageTapped!(event.imageName)),
      );
    }

    _subscriptions.add(
      platformInstance.onImageDetected().listen((event) => scannerViewWidget.onImageDetected(event.imageName)),
    );
  }
}
