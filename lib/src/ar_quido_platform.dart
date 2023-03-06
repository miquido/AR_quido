import 'package:ar_quido/ar_quido.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class ARQuidoPlatform extends PlatformInterface {
  /// Constructs a ImageRecognitionScannerPlatform.
  ARQuidoPlatform() : super(token: _token);

  // Required by the platform interface
  // ignore: no-object-declaration
  static final Object _token = Object();

  static ARQuidoPlatform _instance = ARQuidoMethodChannel();

  /// The default instance of [ARQuidoPlatform] to use.
  ///
  /// Defaults to [ARQuidoPlatform].
  static ARQuidoPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [ARQuidoPlatform] when
  /// they register themselves.
  static set instance(ARQuidoPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  void init() {
    throw UnimplementedError('init() has not been implemented.');
  }

  Future<void> toggleFlashlight({required bool shouldTurnOn}) {
    throw UnimplementedError('toggleFlashlight() has not been implemented.');
  }

  Stream<ImageDetectedEvent> onImageDetected() {
    throw UnimplementedError('onImageDetected() has not been implemented.');
  }

  Stream<ImageTappedEvent> onDetectedImageTapped() {
    throw UnimplementedError('onImageDetected() has not been implemented.');
  }

  Stream<RecognitionStartedEvent> onRecognitionStarted() {
    throw UnimplementedError(
      'onRecognitionStarted() has not been implemented.',
    );
  }

  Stream<RecognitionResumedEvent> onRecognitionResumed() {
    throw UnimplementedError(
      'onRecognitionResumed() has not been implemented.',
    );
  }

  Stream<RecognitionPausedEvent> onRecognitionPaused() {
    throw UnimplementedError(
      'onRecognitionResumed() has not been implemented.',
    );
  }

  Stream<ErrorEvent> onError() {
    throw UnimplementedError('onError() has not been implemented.');
  }

  void dispose() {
    throw UnimplementedError('dispose() has not been implemented.');
  }
}
