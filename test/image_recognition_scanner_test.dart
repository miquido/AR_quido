import 'package:flutter_test/flutter_test.dart';
import 'package:image_recognition_scanner/image_recognition_scanner_platform.dart';
import 'package:mockito/annotations.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'image_recognition_scanner_test.mocks.dart' as base_mock;

class MockImageRecognitionScannerPlatform extends base_mock
    .MockImageRecognitionScannerPlatform with MockPlatformInterfaceMixin {}

@GenerateMocks([ImageRecognitionScannerPlatform])
void main() {
  late MockImageRecognitionScannerPlatform mockPlatform;

  setUp(() {
    mockPlatform = MockImageRecognitionScannerPlatform();
    ImageRecognitionScannerPlatform.instance = mockPlatform;
  });

  // TODO(piotrmitkowski): implement tests for app facing code
}
