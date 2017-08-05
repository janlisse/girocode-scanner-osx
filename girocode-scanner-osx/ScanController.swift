import Cocoa
import AVFoundation

class ScanController: NSViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    var captureSession:AVCaptureSession?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var qrCodeFrameView:CALayer?
    var scanResult: Dictionary<String, String>?
    var giroCodeScannerDelegate: GiroCodeScannerDelegate?
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
        view.wantsLayer = true   // layer is a NSView
        view.layer = renderLayer
        //self.view.layer?.borderWidth = 6.0
        //self.view.layer?.borderColor = CGColor.black
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
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection!) {
        
        let imageBuf = CMSampleBufferGetImageBuffer(sampleBuffer)!
        let ciimg: CIImage = CIImage(cvImageBuffer: imageBuf)
        let features = detector.features(in: ciimg)
        for qrCodeFeature in features as! [CIQRCodeFeature] {
            stopCapturing()
            qrCodeFrameView?.frame = qrCodeFeature.bounds
            print("QR code detected")
            print(qrCodeFeature.messageString!)
            let lines = qrCodeFeature.messageString!.components(separatedBy: "\n")
            let recipient = (lines.indices.contains(5)) ? lines[5] : "Empfänger"
            let iban = (lines.indices.contains(6)) ? lines[6] : "DefaultIBAN"
            let amountStr = (lines.indices.contains(7)) ? lines[7] : "Default"
            let purpose = (lines.indices.contains(10)) ? lines[10] : ""
            let index = amountStr.index(amountStr.startIndex, offsetBy: 3)
            let amount = Double(amountStr.substring(from: index))!
            let giroCode = GiroCode(recipientName : recipient, recipientIban : iban, amount: amount, purpose: purpose, wasSent: false)
            giroCodeScannerDelegate?.giroCodeScanned(giroCode: giroCode)
        }
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
    let wasSent: Bool
}

protocol GiroCodeScannerDelegate {
    func giroCodeScanned(giroCode: GiroCode)
}

