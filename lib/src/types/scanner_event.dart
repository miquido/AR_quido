abstract class ScannerEvent {}

class ImageDetectedEvent extends ScannerEvent {
  ImageDetectedEvent(this.imageName);

  final String? imageName;
}

class ImageTappedEvent extends ScannerEvent {
  ImageTappedEvent(this.imageName);

  final String? imageName;
}

class RecognitionStartedEvent extends ScannerEvent {}

class RecognitionResumedEvent extends ScannerEvent {}

class RecognitionPausedEvent extends ScannerEvent {}

class ErrorEvent extends ScannerEvent {
  ErrorEvent(this.error);

  final String error;
}
