//
//  FLARImageScannerView.swift
//  Runner
//
//  Created by Piotr Mitkowski on 03/02/2023.
//

import Foundation
import Flutter

class FLARImageScannerView: NSObject, FlutterPlatformView {
    private var viewController: ARImageScannerViewController
    
    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger
    ) {
        guard let creationParams = args as? Dictionary<String, Any?>, let referenceImageNames = creationParams["referenceImageNames"] as? Array<String> else {
            fatalError("Could not extract story names from creation params")
        }
        let channelName = "plugins.miquido.com/image_recognition_scanner"
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
        viewController = ARImageScannerViewController(referenceImageNames: referenceImageNames, methodChannel: channel)
        super.init()
    }
    
    func view() -> UIView {
        return viewController.view
    }
    
}
