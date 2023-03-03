import 'package:ar_quido/ar_quido.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';

import 'image_recognition_scanner_test.mocks.dart';

@GenerateMocks([ImageRecognitionScannerPlatform])
void main() {
  late MockImageRecognitionScannerPlatform mockPlatform;

  setUp(() {
    mockPlatform = MockImageRecognitionScannerPlatform();
    ImageRecognitionScannerPlatform.instance = mockPlatform;
  });

  // TODO(piotrmitkowski): implement tests for app facing code
}
