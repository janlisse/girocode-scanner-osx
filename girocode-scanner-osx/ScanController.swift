import Cocoa
import AVFoundation

class ScanController: NSViewController {

    static let notificationName = NSNotification.Name(rawValue: "giroCodeNotification")
    
    @IBOutlet weak var captureButton: NSButton!
    var captureSession:AVCaptureSession?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var qrCodeFrameView:CALayer?
    var isCapturing = false
    let detector: CIDetector = CIDetector(ofType: CIDetectorTypeQRCode, context:nil, options:nil)!
    
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
        captureSession?.stopRunning()
        videoPreviewLayer?.removeFromSuperlayer()
        isCapturing = false
    }
    
    func startCapturing() {
        let captureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        
        do {
            // Get an instance of the AVCaptureDeviceInput class using the previous device object.
            let input = try AVCaptureDeviceInput(device: captureDevice)
            
            // Initialize the captureSession object.
            captureSession = AVCaptureSession()
            
            // Set the input device on the capture session.
            captureSession?.addInput(input)
            
            let captureOutput = AVCaptureVideoDataOutput()
            captureOutput.alwaysDiscardsLateVideoFrames = true
            captureSession?.addOutput(captureOutput)
            
            captureOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
            
            // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
            videoPreviewLayer?.frame = view.bounds
            view.layer?.insertSublayer(videoPreviewLayer!, at:0)
            
            // Start video capture.
            captureSession?.startRunning()
            
            isCapturing = true
            
            // Initialize QR Code Frame to highlight the QR code
            qrCodeFrameView = CALayer()
            
            if let qrCodeFrameView = qrCodeFrameView {
                qrCodeFrameView.borderColor = NSColor.green.cgColor
                qrCodeFrameView.borderWidth = 4
                view.layer?.insertSublayer(qrCodeFrameView, above: videoPreviewLayer)
            }
        } catch {
            print(error)
            return
        }

    }
    
    override func viewWillAppear() {
        view.layer?.backgroundColor = NSColor.black.cgColor
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
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
        if let serviceTag = lines[safe: 0], serviceTag == "BCD",  let recipient = lines[safe: 5],
            let iban = lines[safe: 6], let amountStr =   lines[safe: 7] {
            self.amount = 20.00
            self.recipientIban = iban
            self.recipientName = recipient
            self.purpose = ""
            self.wasSent = true
        } else {
            return nil
        }

    }
}

extension Collection where Indices.Iterator.Element == Index {
    
    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Generator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}


extension ScanController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection!) {
        
        let imageBuf = CMSampleBufferGetImageBuffer(sampleBuffer)!
        let ciimg: CIImage = CIImage(cvImageBuffer: imageBuf)
        let features = detector.features(in: ciimg)
        for qrCodeFeature in features as! [CIQRCodeFeature] {
            qrCodeFrameView?.frame = qrCodeFeature.bounds
            stopCapturing()
            captureButton.setNextState()
            //let recipient = (lines.indices.contains(5)) ? lines[5] : "Empfänger"
            //let iban = (lines.indices.contains(6)) ? lines[6] : "DefaultIBAN"
            //let amountStr = (lines.indices.contains(7)) ? lines[7] : "Default"
            //let purpose = (lines.indices.contains(10)) ? lines[10] : ""
            //let index = amountStr.index(amountStr.startIndex, offsetBy: 3)
            //let amount = Double(amountStr.substring(from: index))!
            let giroCode = GiroCode(fromString: qrCodeFeature.messageString!)
            NotificationCenter.default.post(name: ScanController.notificationName, object: nil, userInfo: ["giroCode": giroCode])
        }
    }
}

