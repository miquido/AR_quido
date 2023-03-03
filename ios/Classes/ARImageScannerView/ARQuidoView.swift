import Foundation
import Flutter

class ARQuidoView: NSObject, FlutterPlatformView {
    private var viewController: ARQuidoViewController
    
    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        guard let creationParams = args as? Dictionary<String, Any?>, let referenceImageNames = creationParams["referenceImageNames"] as? Array<String> else {
            fatalError("Could not extract story names from creation params")
        }
        let channelName = "plugins.miquido.com/ar_quido"
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
        viewController = ARQuidoViewController(referenceImageNames: referenceImageNames, methodChannel: channel)
        super.init()
    }
    
    func view() -> UIView {
        return viewController.view
    }
    
}
