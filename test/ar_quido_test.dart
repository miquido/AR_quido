import 'package:ar_quido/ar_quido.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';

import 'ar_quido_test.mocks.dart';

@GenerateMocks([ARQuidoPlatform])
void main() {
  late MockARQuidoPlatform mockPlatform;

  setUp(() {
    mockPlatform = MockARQuidoPlatform();
    ARQuidoPlatform.instance = mockPlatform;
  });

  // TODO(piotrmitkowski): implement tests for app facing code
}
