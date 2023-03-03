import Flutter
import UIKit

public class ARQuidoPlugin: NSObject, FlutterPlugin {
    private static let scannerViewId = "plugins.miquido.com/ar_quido_view_ios"

    public static func register(with registrar: FlutterPluginRegistrar) {
        let factory = ARQuidoViewFactory(messenger: registrar.messenger())
        registrar.register(factory, withId: scannerViewId)
    }
}
