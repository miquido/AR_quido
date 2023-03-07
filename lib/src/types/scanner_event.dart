/// Generic event coming from the native side of the scanner.
abstract class ScannerEvent {}

/// An event fired when the scanner detects a reference image.
class ImageDetectedEvent extends ScannerEvent {
  /// Builds an Image Detected Event with detected image's name.
  ImageDetectedEvent(this.imageName);

  /// The name of the recognized image.
  final String? imageName;
}

/// An event fired when the a marker of the reference image is tapped.
class ImageTappedEvent extends ScannerEvent {
  /// Builds an Image Tapped Event with detected image's name.
  ImageTappedEvent(this.imageName);

  /// The name of the recognized image.
  final String? imageName;
}

/// An event fired when the scanner starts the image recognition.
class RecognitionStartedEvent extends ScannerEvent {}

/// An event fired when the scanner resumes the image recognition after a pause.
class RecognitionResumedEvent extends ScannerEvent {}

/// An event fired when the scanner pauses the image recognition.
class RecognitionPausedEvent extends ScannerEvent {}

/// An event fired when the scanner raises an error.
class ErrorEvent extends ScannerEvent {
  /// Build an Error Event with detected image's name.
  ErrorEvent(this.error);

  /// An error message provided by the scanner.
  final String error;
}
