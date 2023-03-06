import 'dart:io';

import 'package:ar_quido/ar_quido.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class ARQuidoView extends StatefulWidget {
  const ARQuidoView({
    required this.referenceImageNames,
    required this.onImageDetected,
    this.onViewCreated,
    this.onRecognitionStarted,
    this.onRecognitionPaused,
    this.onRecognitionResumed,
    this.onError,
    super.key,
  });

  final List<String> referenceImageNames;
  final void Function(ARQuidoViewController controller)? onViewCreated;
  final void Function(String? imageName) onImageDetected;
  final VoidCallback? onRecognitionStarted;
  final VoidCallback? onRecognitionPaused;
  final VoidCallback? onRecognitionResumed;
  final void Function(String error)? onError;

  static const String _androidViewType = 'plugins.miquido.com/ar_quido_view_android';
  static const String _iOSViewType = 'plugins.miquido.com/ar_quido_view_ios';

  @override
  State<ARQuidoView> createState() => ARQuidoViewState();
}

class ARQuidoViewState extends State<ARQuidoView> {
  ARQuidoViewController? _controller;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  AndroidViewController _onCreatePlatformView(
    PlatformViewCreationParams params,
  ) {
    final viewId = params.id;
    return PlatformViewsService.initAndroidView(
      id: viewId,
      viewType: ARQuidoView._androidViewType,
      layoutDirection: TextDirection.ltr,
      creationParams: _creationParams,
      creationParamsCodec: const StandardMessageCodec(),
    )
      ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
      ..addOnPlatformViewCreatedListener(_onPlatformViewCreated)
      ..create();
  }

  void _onPlatformViewCreated(int id) {
    final controller = ARQuidoViewController(this);
    widget.onViewCreated?.call(controller);
  }

  Map<String, dynamic> get _creationParams => <String, dynamic>{
        'referenceImageNames': widget.referenceImageNames,
      };

  @override
  Widget build(BuildContext context) {
    if (Platform.isAndroid) {
      return PlatformViewLink(
        viewType: ARQuidoView._androidViewType,
        surfaceFactory: (context, controller) {
          return AndroidViewSurface(
            controller: controller as AndroidViewController,
            hitTestBehavior: PlatformViewHitTestBehavior.opaque,
            gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
          );
        },
        onCreatePlatformView: _onCreatePlatformView,
      );
    } else if (Platform.isIOS) {
      return UiKitView(
        viewType: ARQuidoView._iOSViewType,
        layoutDirection: TextDirection.ltr,
        creationParams: _creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    } else {
      throw Exception('$defaultTargetPlatform is not supported by ARQuidoView');
    }
  }
}
