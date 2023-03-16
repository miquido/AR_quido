import 'dart:async';

import 'package:ar_quido/ar_quido.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

void main() {
  late ARQuidoPlatformMock mockPlatform;

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    mockPlatform = ARQuidoPlatformMock();
    ARQuidoPlatform.instance = mockPlatform;
  });

  testWidgets('Should correctly request enabling the flashlight',
      (tester) async {
    when(mockPlatform.toggleFlashlight(shouldTurnOn: anyNamed('shouldTurnOn')))
        .thenAnswer((realInvocation) => Future.value());
    final completer = Completer<ARQuidoViewController>();
    await tester.pumpWidget(
      ARQuidoView(
        referenceImageNames: const [],
        onImageDetected: (_) {},
        onViewCreated: completer.complete,
      ),
    );
    final controller = await completer.future;
    await controller.toggleFlashlight(shouldTurnOn: true);
    verify(
      mockPlatform.toggleFlashlight(
        shouldTurnOn: argThat(isTrue, named: 'shouldTurnOn'),
      ),
    );
  });

  testWidgets('Should correctly request disabling the flashlight',
      (tester) async {
    when(mockPlatform.toggleFlashlight(shouldTurnOn: anyNamed('shouldTurnOn')))
        .thenAnswer((realInvocation) => Future.value());
    final completer = Completer<ARQuidoViewController>();
    await tester.pumpWidget(
      ARQuidoView(
        referenceImageNames: const [],
        onImageDetected: (_) {},
        onViewCreated: completer.complete,
      ),
    );
    final controller = await completer.future;
    await controller.toggleFlashlight(shouldTurnOn: false);
    verify(
      mockPlatform.toggleFlashlight(
        shouldTurnOn: argThat(isFalse, named: 'shouldTurnOn'),
      ),
    );
  });

  testWidgets('Should receive onImageDetected callback', (tester) async {
    final completer = Completer<String>();
    await tester.pumpWidget(
      ARQuidoView(
        referenceImageNames: const [],
        onImageDetected: completer.complete,
      ),
    );
    mockPlatform.streamController.add(ImageDetectedEvent('test_image'));
    await expectLater(completer.future, completes);
    await expectLater(completer.future, completion(equals('test_image')));
  });
}

/// Platform interfaces must not be implemented with `implements`, so platform
/// mock requires the "manual" approach
class ARQuidoPlatformMock extends Mock
    with MockPlatformInterfaceMixin
    implements ARQuidoPlatform {
  final streamController = StreamController<ImageDetectedEvent>.broadcast();

  @override
  Stream<ImageDetectedEvent> onImageDetected() {
    return streamController.stream;
  }

  @override
  Future<void> toggleFlashlight({required bool? shouldTurnOn}) async =>
      super.noSuchMethod(
        Invocation.method(#toggleFlashlight, [], {#shouldTurnOn: shouldTurnOn}),
      );

  @override
  Widget buildView(
    PlatformViewCreatedCallback? onPlatformViewCreated, {
    required List<String>? referenceImageNames,
  }) {
    onPlatformViewCreated?.call(0);
    return Container();
  }

  @override
  void dispose() {
    streamController.close();
  }
}
