import Cocoa
import AVFoundation
import os.log

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}

class ScanController: NSViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    static let notificationName = NSNotification.Name(rawValue: "giroCodeNotification")
    
    @IBOutlet weak var captureButton: NSButton!
    @IBOutlet var output: NSTextField!
    
    var session:AVCaptureSession!
    var queue: DispatchQueue!
    
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var isCapturing = false
    let detector: CIDetector = CIDetector(ofType: CIDetectorTypeQRCode, context:nil, options:nil)!
    let log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "capturing")
    
    @IBAction func captureButton(_ sender: Any) {
        if (isCapturing) {
            stopCapturing()
        } else {
            startCapturing()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let renderLayer = CALayer()
        view.wantsLayer = true
        view.layer = renderLayer
    }
    
    func stopCapturing() {
        self.session?.stopRunning()
        videoPreviewLayer?.removeFromSuperlayer()
        isCapturing = false
    }
    
    func startCapturing() {
        
        self.session = AVCaptureSession()
        self.session.sessionPreset = .low
        
        let device = AVCaptureDevice.default(for: .video)
        let input = try! AVCaptureDeviceInput(device: device!)
        
        self.session.addInput(input)
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = self.view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        
        self.view.wantsLayer = true
        self.view.layer?.insertSublayer(previewLayer, at:0)
        
        self.queue = DispatchQueue(label: "queue", attributes: .concurrent)
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: queue)
        output.alwaysDiscardsLateVideoFrames = true
        
        session.addOutput(output)
        
        session.startRunning()
    }
    
    override func viewWillAppear() {
        view.layer?.backgroundColor = NSColor.black.cgColor
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // This is called repeatedly at the video frame rate! Be careful not to call api here!
        
        let context = CIContext()
        let detector = CIDetector(ofType: "CIDetectorTypeQRCode", context: context, options: [:])
        
        let ciImage = CIImage(cvImageBuffer: CMSampleBufferGetImageBuffer(sampleBuffer)!)
        
        if let features = detector?.features(in: ciImage) {
            guard let feature = features.first as? CIQRCodeFeature else { return }
            guard let message = feature.messageString else { return }
            DispatchQueue.main.sync {
                if let giroCode = GiroCode(fromString: message) {
                    self.output.stringValue = "Found"
                    stopCapturing()
                    captureButton.setNextState()
                    
                    NotificationCenter.default.post(name: ScanController.notificationName, object: nil, userInfo: ["giroCode": giroCode])
                } else {
                    self.output.stringValue = "Not a valid GiroCode"
                }
            }
        }
    }
}

struct GiroCode {
    let recipientName: String
    let recipientIban: String
    let amount: Double
    let purpose: String?
    var wasSent: Bool
    
}

extension GiroCode {
    init?(fromString: String) {
        let lines = fromString.components(separatedBy: "\n")
        let serviceTag = lines[0].trimmingCharacters(in: .whitespacesAndNewlines)
        let purpose = lines[10]
        let iban = lines[6]
        let recipient = lines[safe: 5]
        let amount = GiroCode.parseAmount(s: lines[safe: 7])
        if serviceTag == "BCD", recipient != nil, amount != nil  {
            self.amount = amount!
            self.recipientIban = iban.trimmingCharacters(in: .whitespacesAndNewlines)
            self.recipientName = recipient!.trimmingCharacters(in: .whitespacesAndNewlines)
            self.purpose = purpose.trimmingCharacters(in: .whitespacesAndNewlines)
            self.wasSent = false
        } else {
            return nil
        }
    }
    
    static func parseAmount(s: String?) -> Double? {
        if let amountStr = s, amountStr.count > 4 {
            let index = amountStr.index(amountStr.startIndex, offsetBy: 3)
            return Double(String(amountStr[index...]).trimmingCharacters(in: .whitespacesAndNewlines))
        } else {
            return nil
        }
    }
}

extension Collection where Indices.Iterator.Element == Index {
    
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
