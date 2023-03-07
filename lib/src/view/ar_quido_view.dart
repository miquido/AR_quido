import 'dart:io';

import 'package:ar_quido/ar_quido.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// A widget which displays a camera stream with image recognition features enabled.
class ARQuidoView extends StatefulWidget {
  const ARQuidoView({
    required this.referenceImageNames,
    required this.onImageDetected,
    this.onDetectedImageTapped,
    this.onViewCreated,
    this.onRecognitionStarted,
    this.onRecognitionPaused,
    this.onRecognitionResumed,
    this.onError,
    super.key,
  });

  /// A list of names of files, that contain reference images. The names should
  /// be provided without their path and extension.
  ///
  /// All image files should be placed in `assets/reference_images` directory
  /// and should be listed in the `assets` section of `pubspec.yaml`.
  ///
  /// Only `.jpg` image files are supported at this time.
  final List<String> referenceImageNames;

  /// Callback method for when the view is ready to be used.
  ///
  /// Used to receive a [ARQuidoViewController] for this [ARQuidoView].
  final void Function(ARQuidoViewController controller)? onViewCreated;

  /// Called when one of the reference images is detected in the current camera
  /// stream.
  final void Function(String? imageName) onImageDetected;

  /// Called when a marker for detected reference image is tapped.
  final void Function(String? imageName)? onDetectedImageTapped;

  /// Called when all reference images are loaded to the recognition module and
  /// the view starts the detection.
  final VoidCallback? onRecognitionStarted;

  /// iOS only; called when the view becomes invisible in the current context
  /// (e.g. after navigating to another [Route]).
  final VoidCallback? onRecognitionPaused;

  /// iOS only; called when the view is restored after being paused (e.g. after
  /// navigating to the [Route] with the view).
  final VoidCallback? onRecognitionResumed;

  /// Called when the view encounters an error.
  final void Function(String error)? onError;

  static const String _androidViewType =
      'plugins.miquido.com/ar_quido_view_android';
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
