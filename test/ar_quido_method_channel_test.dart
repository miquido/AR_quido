import 'package:ar_quido/ar_quido.dart';
import 'package:async/async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = ARQuidoMethodChannel();
  final log = <MethodCall>[];

  setUpAll(platform.init);

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      platform.methodChannel,
      (message) async {
        log.add(message);
        return '';
      },
    );

    log.clear();
  });

  group('scanner#toggleFlashlight', () {
    test('is handled correctly', () async {
      await platform.toggleFlashlight(shouldTurnOn: true);
      expect(log, <Matcher>[
        isMethodCall(
          'scanner#toggleFlashlight',
          arguments: <String, dynamic>{'shouldTurnOn': true},
        ),
      ]);
    });

    test('correctly passes arguments', () async {
      await platform.toggleFlashlight(shouldTurnOn: true);
      await platform.toggleFlashlight(shouldTurnOn: false);
      expect(log, <Matcher>[
        isMethodCall(
          'scanner#toggleFlashlight',
          arguments: <String, dynamic>{'shouldTurnOn': true},
        ),
        isMethodCall(
          'scanner#toggleFlashlight',
          arguments: <String, dynamic>{'shouldTurnOn': false},
        ),
      ]);
    });
  });

  test('Recognition started event is fired correctly', () async {
    final recognitionStartedStream =
        StreamQueue(platform.onRecognitionStarted());
    await _sendPlatformMessage('scanner#start', <String, Object?>{});

    final receivedMessage = await recognitionStartedStream.next;
    expect(recognitionStartedStream.eventsDispatched, equals(1));
    expect(receivedMessage, isA<RecognitionStartedEvent>());
  });

  test('Recognition resumed event is fired correctly', () async {
    final recognitionResumedStream =
        StreamQueue(platform.onRecognitionResumed());
    await _sendPlatformMessage(
      'scanner#recognitionResumed',
      <String, Object?>{},
    );

    final receivedMessage = await recognitionResumedStream.next;
    expect(recognitionResumedStream.eventsDispatched, equals(1));
    expect(receivedMessage, isA<RecognitionResumedEvent>());
  });

  test('Recognition paused event is fired correctly', () async {
    final recognitionPausedStream = StreamQueue(platform.onRecognitionPaused());
    await _sendPlatformMessage(
      'scanner#recognitionPaused',
      <String, Object?>{},
    );

    final receivedMessage = await recognitionPausedStream.next;
    expect(recognitionPausedStream.eventsDispatched, equals(1));
    expect(receivedMessage, isA<RecognitionPausedEvent>());
  });

  test('Error event is fired correctly', () async {
    final errorStream = StreamQueue(platform.onError());
    await _sendPlatformMessage(
      'scanner#error',
      <String, Object?>{
        'errorCode': 'Some test error',
      },
    );

    final receivedMessage = await errorStream.next;
    expect(errorStream.eventsDispatched, equals(1));
    expect(receivedMessage, isA<ErrorEvent>());
    expect(receivedMessage.error, equals('Some test error'));
  });

  test('Image detected event is fired correctly', () async {
    final errorStream = StreamQueue(platform.onImageDetected());
    await _sendPlatformMessage(
      'scanner#onImageDetected',
      <String, Object?>{
        'imageName': 'applandroid',
      },
    );

    final receivedMessage = await errorStream.next;
    expect(errorStream.eventsDispatched, equals(1));
    expect(receivedMessage, isA<ImageDetectedEvent>());
    expect(receivedMessage.imageName, equals('applandroid'));
  });

  test('Image tapped event is fired correctly', () async {
    final detectedImageTappedStream =
        StreamQueue(platform.onDetectedImageTapped());
    await _sendPlatformMessage(
      'scanner#onDetectedImageTapped',
      <String, Object?>{
        'imageName': 'applandroid',
      },
    );

    final receivedMessage = await detectedImageTappedStream.next;
    expect(detectedImageTappedStream.eventsDispatched, equals(1));
    expect(receivedMessage, isA<ImageTappedEvent>());
    expect(receivedMessage.imageName, equals('applandroid'));
  });
}

Future<void> _sendPlatformMessage(
  String method,
  Map<dynamic, dynamic> data,
) async {
  final byteData =
      const StandardMethodCodec().encodeMethodCall(MethodCall(method, data));
  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
    'plugins.miquido.com/ar_quido',
    byteData,
    (data) {},
  );
}
