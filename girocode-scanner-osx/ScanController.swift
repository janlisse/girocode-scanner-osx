import Cocoa
import AVFoundation

class ScanController: NSViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    var captureSession:AVCaptureSession?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var qrCodeFrameView:CALayer?
    var scanResult: Dictionary<String, String>?
    var lastTime : DispatchTime?
    var sourceIban : String?
    
    let detector: CIDetector = CIDetector(ofType: CIDetectorTypeQRCode, context:nil, options:nil)!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.wantsLayer = true
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
            
            let renderLayer = CALayer()
            view.wantsLayer = true   // layer is a NSView
            view.layer = renderLayer
            videoPreviewLayer?.frame = view.bounds
            view.layer?.addSublayer(videoPreviewLayer!)
            
            // Start video capture.
            captureSession?.startRunning()
            
            // Initialize QR Code Frame to highlight the QR code
            qrCodeFrameView = CALayer()
            
            if let qrCodeFrameView = qrCodeFrameView {
                qrCodeFrameView.borderColor = NSColor.green.cgColor
                qrCodeFrameView.borderWidth = 4
                view.layer?.addSublayer(qrCodeFrameView)
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
            qrCodeFrameView?.frame = qrCodeFeature.bounds
            captureSession?.stopRunning()
            print("QR code detected")
            print(qrCodeFeature.messageString!)
            let lines = qrCodeFeature.messageString!.components(separatedBy: "\n")
            let recipient = (lines.indices.contains(5)) ? lines[5] : "Empfänger"
            let iban = (lines.indices.contains(6)) ? lines[6] : "DefaultIBAN"
            let amountStr = (lines.indices.contains(7)) ? lines[7] : "Default"
            let purpose = (lines.indices.contains(10)) ? lines[10] : ""
            let index = amountStr.index(amountStr.startIndex, offsetBy: 3)
            let amount = Double(amountStr.substring(from: index))!
            callInvoiceScript(sourceIban: sourceIban!, recipientName: recipient, recipientIban: iban, amount: amount, purpose: purpose)
        }
    }
    
    func callInvoiceScript(sourceIban: String, recipientName: String, recipientIban: String, amount: Double, purpose: String) {
        let line1 = "tell application \"MoneyMoney\"\n"
        let line2 = "  create bank transfer from account \"\(sourceIban)\" to \"\(recipientName)\" iban \"\(recipientIban)\" amount \(amount) purpose \"\(purpose)\"\n"
        let line3 = "end tell\n"
        let script = line1+line2+line3
        var error: NSDictionary?
        print(script)
        let scriptObject = NSAppleScript(source: script)
        _ = scriptObject!.executeAndReturnError(&error)
        if let error = error {
            print(error)
        } else {
            print("Successfully sent invoice")
        }
    }



    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    


}

