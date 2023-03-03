import Flutter
import UIKit

public class ImageRecognitionScannerPlugin: NSObject, FlutterPlugin {
    private static let scannerViewId = "plugins.miquido.com/image_scanner_view_ios"

    public static func register(with registrar: FlutterPluginRegistrar) {
        let factory = FLARImageScannerViewFactory(messenger: registrar.messenger())
        registrar.register(factory, withId: scannerViewId)
    }
}
