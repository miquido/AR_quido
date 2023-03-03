//
//  ARImageScannerViewController.swift
//  Runner
//
//  Created by Piotr Mitkowski on 02/02/2023.
//

import UIKit
import ARKit
import SceneKit
import Flutter

protocol ImageRecognitionDelegate: AnyObject {
    func onRecognitionStarted()
    func onRecognitionPaused()
    func onRecognitionResumed()
    func onDetect(imageKey: String)
}

class ARImageScannerViewController: UIViewController {
    
    var sceneView: ARSCNView!
    
    let updateQueue = DispatchQueue(label: Bundle.main.bundleIdentifier! +
                                    ".serialSceneKitQueue")
    
    var session: ARSession {
        return sceneView.session
    }
    
    private var wasCameraInitialized = false
    private var isResettingTracking = false
    private let referenceImageNames: Array<String>
    private let methodChannel: FlutterMethodChannel
    private var detectedImageNode: SCNNode?
    
    init(referenceImageNames: Array<String>, methodChannel channel: FlutterMethodChannel) {
        self.referenceImageNames = referenceImageNames
        self.methodChannel = channel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        methodChannel.setMethodCallHandler(nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        methodChannel.setMethodCallHandler(handleMethodCall(call:result:))
        sceneView = ARSCNView(frame: CGRect.zero)
        sceneView.delegate = self
        sceneView.session.delegate = self
        view = sceneView
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
        resetTracking()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session.pause()
        onRecognitionPaused()
    }
    
    // MARK: - Session management (Image detection setup)
    
    /// Prevents restarting the session while a restart is in progress.
    var isRestartAvailable = true
    
    func resetTracking() {
        if isResettingTracking {
            return
        }
        isResettingTracking = true
        DispatchQueue.global(qos: .userInteractive).async {
            var referenceImages = [ARReferenceImage]()
            for imageName in self.referenceImageNames {
                let imageKey = FlutterDartProject.lookupKey(forAsset: "assets/reference_images/\(imageName).jpg")
                let imagePath = Bundle.main.path(forResource: imageKey, ofType: nil)
                let image = UIImage(named: imagePath!, in: Bundle.main, compatibleWith: nil)
                let referenceImage = ARReferenceImage(image!.cgImage!, orientation: .up, physicalWidth: 0.5)
                referenceImage.name = imageName
                referenceImages.append(referenceImage)
            }
            
            let configuration = ARWorldTrackingConfiguration()
            configuration.detectionImages = Set(referenceImages)
            configuration.maximumNumberOfTrackedImages = 1
            self.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
            if (!self.wasCameraInitialized) {
                self.onRecognitionStarted()
                self.wasCameraInitialized = true
            } else {
                self.onRecognitionResumed()
            }
            self.isResettingTracking = false
        }
    }
}

extension ARImageScannerViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        if let nodeToRemove = detectedImageNode {
            nodeToRemove.removeFromParentNode()
        }
        
        let referenceImage = imageAnchor.referenceImage
        updateQueue.async {
            let plane = SCNBox(width: referenceImage.physicalSize.width, height: referenceImage.physicalSize.height, length: 0.3, chamferRadius: 0.01)
            let planeNode = SCNNode(geometry: plane)
            planeNode.opacity = 0.75
            planeNode.geometry?.firstMaterial?.diffuse.contents = UIColor(red: 205 / 255, green: 207 / 255, blue: 1.0, alpha: 1.0)
            //rotate plane to match assumed image orientation
            planeNode.eulerAngles.x = -.pi / 2
            planeNode.runAction(self.imageHighlightAction)
            node.addChildNode(planeNode)
            self.detectedImageNode = planeNode
        }
        
        DispatchQueue.main.async {
            let imageName = referenceImage.name ?? ""
            self.onDetect(imageKey: imageName)
        }
    }
    
    var imageHighlightAction: SCNAction {
        return .repeatForever(
            .sequence([
                .wait(duration: 0.25),
                .fadeOpacity(to: 0.85, duration: 0.3),
                .fadeOpacity(to: 0.15, duration: 0.3),
            ])
        )
    }
}

extension ARImageScannerViewController: ARSessionDelegate {
    func session(_ session: ARSession, didFailWithError error: Error) {
        guard error is ARError else { return }
        
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        
        DispatchQueue.main.async {
            self.displayErrorMessage(title: "The AR session failed.", message: errorMessage)
        }
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        restartExperience()
    }
    
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
    }
    
    // MARK: - Error handling
    
    func displayErrorMessage(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
            alertController.dismiss(animated: true, completion: nil)
            self.resetTracking()
        }
        alertController.addAction(restartAction)
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Interface Actions
    
    func restartExperience() {
        guard isRestartAvailable else { return }
        isRestartAvailable = false
        resetTracking()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.isRestartAvailable = true
        }
    }
}

// MARK: PlatformView interface implementation

extension ARImageScannerViewController {
    private func handleMethodCall(call: FlutterMethodCall, result: FlutterResult) {
        if call.method == "scanner#toggleFlashlight" {
            let arguments = call.arguments as? Dictionary<String, Any?>
            let shouldTurnOn = (arguments?["shouldTurnOn"] as? Bool) ?? false
            toggleFlashlight(shouldTurnOn)
            result(nil)
        } else {
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func toggleFlashlight(_ shouldTurnOn: Bool) {
        guard let camera = AVCaptureDevice.default(for: AVMediaType.video) else {
            return
        }
        if camera.hasTorch {
            do {
                try camera.lockForConfiguration()
                camera.torchMode = shouldTurnOn ? .on : .off
                camera.unlockForConfiguration()
            } catch {
                print("Torch cound not be used")
            }
        } else {
            print("Torch is not available")
        }
    }
}

extension ARImageScannerViewController: ImageRecognitionDelegate {
    func onRecognitionPaused() {
        methodChannel.invokeMethod("scanner#recognitionPaused", arguments: nil)
    }
    
    func onRecognitionResumed() {
        methodChannel.invokeMethod("scanner#recognitionResumed", arguments: nil)
    }
    
    func onRecognitionStarted() {
        methodChannel.invokeMethod("scanner#start", arguments: [:])
    }
    
    func onDetect(imageKey: String) {
        methodChannel.invokeMethod("scanner#onImageDetected", arguments: ["imageName": imageKey])
    }
}
