import 'dart:async';

import 'package:ar_quido/ar_quido.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:stream_transform/stream_transform.dart';

/// An implementation of [ARQuidoPlatform] that uses method channels.
class ARQuidoMethodChannel extends ARQuidoPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('plugins.miquido.com/ar_quido');

  final StreamController<ScannerEvent> _scannerEventStreamController = StreamController<ScannerEvent>.broadcast();

  @override
  void init() {
    methodChannel.setMethodCallHandler(_handleMethodCall);
  }

  @override
  void dispose() {
    _scannerEventStreamController.close();
    super.dispose();
  }

  @override
  Future<void> toggleFlashlight({required bool shouldTurnOn}) async {
    final arguments = {'shouldTurnOn': shouldTurnOn};
    await methodChannel.invokeMethod<void>(
      'scanner#toggleFlashlight',
      arguments,
    );
  }

  @override
  Stream<ImageDetectedEvent> onImageDetected() => _scannerEventStreamController.stream.whereType<ImageDetectedEvent>();

  @override
  Stream<ImageTappedEvent> onDetectedImageTapped() =>
      _scannerEventStreamController.stream.whereType<ImageTappedEvent>();

  @override
  Stream<RecognitionStartedEvent> onRecognitionStarted() =>
      _scannerEventStreamController.stream.whereType<RecognitionStartedEvent>();

  @override
  Stream<RecognitionResumedEvent> onRecognitionResumed() =>
      _scannerEventStreamController.stream.whereType<RecognitionResumedEvent>();

  @override
  Stream<RecognitionPausedEvent> onRecognitionPaused() =>
      _scannerEventStreamController.stream.whereType<RecognitionPausedEvent>();

  @override
  Stream<ErrorEvent> onError() => _scannerEventStreamController.stream.whereType<ErrorEvent>();

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'scanner#start':
        _scannerEventStreamController.add(RecognitionStartedEvent());
        break;
      case 'scanner#recognitionPaused':
        _scannerEventStreamController.add(RecognitionPausedEvent());
        break;
      case 'scanner#recognitionResumed':
        _scannerEventStreamController.add(RecognitionResumedEvent());
        break;
      case 'scanner#onImageDetected':
        final arguments = (call.arguments as Map).cast<String, String?>();
        final imageName = arguments['imageName'];
        _scannerEventStreamController.add(ImageDetectedEvent(imageName));
        break;
      case 'scanner#onDetectedImageTapped':
        final arguments = (call.arguments as Map).cast<String, String?>();
        final imageName = arguments['imageName'];
        _scannerEventStreamController.add(ImageTappedEvent(imageName));
        break;
      case 'scanner#error':
        final arguments = (call.arguments as Map).cast<String, String?>();
        final error = arguments['errorCode'];
        _scannerEventStreamController.add(ErrorEvent(error!));
        break;
      default:
        throw MissingPluginException();
    }
  }
}
