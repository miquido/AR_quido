import 'dart:async';

import 'package:ar_quido/ar_quido.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:stream_transform/stream_transform.dart';

/// An implementation of [ARQuidoPlatform] that uses method channels.
class ARQuidoMethodChannel extends ARQuidoPlatform {
  static const String _androidViewType =
      'plugins.miquido.com/ar_quido_view_android';
  static const String _iOSViewType = 'plugins.miquido.com/ar_quido_view_ios';

  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('plugins.miquido.com/ar_quido');

  final StreamController<ScannerEvent> _scannerEventStreamController =
      StreamController<ScannerEvent>.broadcast();

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
  Stream<ImageDetectedEvent> onImageDetected() =>
      _scannerEventStreamController.stream.whereType<ImageDetectedEvent>();

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
  Stream<ErrorEvent> onError() =>
      _scannerEventStreamController.stream.whereType<ErrorEvent>();

  @override
  Widget buildView(
    PlatformViewCreatedCallback onPlatformViewCreated, {
    required List<String> referenceImageNames,
  }) {
    final creationParams = _buildCreationParams(referenceImageNames);
    if (defaultTargetPlatform == TargetPlatform.android) {
      return PlatformViewLink(
        viewType: ARQuidoMethodChannel._androidViewType,
        surfaceFactory: (context, controller) {
          return AndroidViewSurface(
            controller: controller as AndroidViewController,
            hitTestBehavior: PlatformViewHitTestBehavior.opaque,
            gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
          );
        },
        onCreatePlatformView: (params) => _onCreatePlatformView(
          params,
          creationParams,
          onPlatformViewCreated,
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      return UiKitView(
        viewType: ARQuidoMethodChannel._iOSViewType,
        layoutDirection: TextDirection.ltr,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
        onPlatformViewCreated: onPlatformViewCreated,
      );
    } else {
      throw Exception('$defaultTargetPlatform is not supported by ARQuidoView');
    }
  }

  AndroidViewController _onCreatePlatformView(
    PlatformViewCreationParams params,
    Map<String, dynamic> creationParams,
    PlatformViewCreatedCallback onPlatformViewCreated,
  ) {
    final viewId = params.id;
    return PlatformViewsService.initAndroidView(
      id: viewId,
      viewType: ARQuidoMethodChannel._androidViewType,
      layoutDirection: TextDirection.ltr,
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
    )
      ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
      ..addOnPlatformViewCreatedListener(onPlatformViewCreated)
      ..create();
  }

  Map<String, dynamic> _buildCreationParams(List<String> referenceImageNames) =>
      <String, dynamic>{
        'referenceImageNames': referenceImageNames,
      };

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'scanner#start':
        _scannerEventStreamController.add(RecognitionStartedEvent());
      case 'scanner#recognitionPaused':
        _scannerEventStreamController.add(RecognitionPausedEvent());
      case 'scanner#recognitionResumed':
        _scannerEventStreamController.add(RecognitionResumedEvent());
      case 'scanner#onImageDetected':
        final arguments = (call.arguments as Map).cast<String, String?>();
        final imageName = arguments['imageName'];
        _scannerEventStreamController.add(ImageDetectedEvent(imageName));
      case 'scanner#onDetectedImageTapped':
        final arguments = (call.arguments as Map).cast<String, String?>();
        final imageName = arguments['imageName'];
        _scannerEventStreamController.add(ImageTappedEvent(imageName));
      case 'scanner#error':
        final arguments = (call.arguments as Map).cast<String, String?>();
        final error = arguments['errorCode'];
        _scannerEventStreamController.add(ErrorEvent(error!));
      default:
        throw MissingPluginException();
    }
  }
}
