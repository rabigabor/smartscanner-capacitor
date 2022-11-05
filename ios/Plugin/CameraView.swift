//
//  CameraView.swift
//  Plugin
//
//  Created by rabigabor on 2021. 12. 06..
//  Copyright © 2021. Max Lynch. All rights reserved.
//

import Foundation
import Capacitor
import Photos
import PhotosUI
import MLImage
import MLKitTextRecognition
import MLKitVision
import MLKitBarcodeScanning


extension SmartScannerPlugin {
    func showCamera(_ mode: String, _ format: String) {
        // check if we have a camera
        if (bridge?.isSimEnvironment ?? false) || !UIImagePickerController.isSourceTypeAvailable(UIImagePickerController.SourceType.camera) {
            CAPLog.print("⚡️ ", self.pluginId, "-", "Camera not available in simulator")
            bridge?.alert("Camera Error", "Camera not available in Simulator")
            call?.reject("Camera not available while running in Simulator")
            return 
        }
        // check for permission
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if authStatus == .restricted || authStatus == .denied {
            call?.reject("Hiányzó kamera jogosultság")
            return
        }
        // we either already have permission or can prompt
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            if granted {
                DispatchQueue.main.async {
                    let viewController = SmartScannerViewController(nibName: "SmartScannerUIView", bundle: nil, mode: mode, format: format, call: (self?.call)!)
                    self?.bridge?.viewController?.present(viewController, animated: true, completion: nil)
                    print("HELLO")
                }
            } else {
                self?.call?.reject("Hiányzó kamera jogosultság")
            }
        }
    }
    
}


class SmartScannerViewController: UIViewController {
    
    private var isUsingFrontCamera = false
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private lazy var captureSession = AVCaptureSession()
    private lazy var sessionQueue = DispatchQueue(label: Constant.sessionQueueLabel)
    private var lastFrame: CMSampleBuffer?
    
    private var call: CAPPluginCall?
    
    private var cleaner: MrzCleaner;
    
    private var mode: String = ""
    private var format: String = ""
    
    private var analyzeStart: Int64 = Int64(Date().timeIntervalSince1970*1000)
    
    private var analyzeTime: Int64 = 5000;
    
    required init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?, mode: String, format: String, call: CAPPluginCall) {
        self.mode = mode
        self.format = format
        self.call = call
        self.cleaner = MrzCleaner()
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        self.cleaner = MrzCleaner()
        super.init(coder: coder)
    }
    
    private lazy var previewOverlayView: UIImageView = {

      precondition(isViewLoaded)
      let previewOverlayView = UIImageView(frame: .zero)
      previewOverlayView.contentMode = UIView.ContentMode.scaleAspectFill
      previewOverlayView.translatesAutoresizingMaskIntoConstraints = false
      return previewOverlayView
    }()

    private lazy var annotationOverlayView: UIView = {
      precondition(isViewLoaded)
      let annotationOverlayView = UIView(frame: .zero)
      annotationOverlayView.translatesAutoresizingMaskIntoConstraints = false
      return annotationOverlayView
    }()

    // MARK: - IBOutlets
    @IBOutlet private var cameraView: UIView!

    // MARK: - UIViewController
    override func viewDidLoad() {
      super.viewDidLoad()
        
        //let mainWindow = UIApplication.shared.keyWindow!
        //cameraView = UIView(frame: CGRect(x: mainWindow.frame.origin.x, y: mainWindow.frame.origin.y, width: mainWindow.frame.width/2, height: mainWindow.frame.height/2))
        //mainWindow.addSubview(cameraView);
        cameraView.backgroundColor = .black
        //cameraView.layer.zPosition = -1

      previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
      setUpPreviewOverlayView()
      setUpAnnotationOverlayView()
      setUpCaptureSessionOutput()
      setUpCaptureSessionInput()
        
    }

    override func viewDidAppear(_ animated: Bool) {
      super.viewDidAppear(animated)
      startSession()
    }

    override func viewDidDisappear(_ animated: Bool) {
      super.viewDidDisappear(animated)
      stopSession()
    }

    override func viewDidLayoutSubviews() {
      super.viewDidLayoutSubviews()
      previewLayer.frame = cameraView.frame
    }

    // MARK: - IBActions
    @IBAction func switchCamera(_ sender: Any) {
      isUsingFrontCamera = !isUsingFrontCamera
      removeDetectionAnnotations()
      setUpCaptureSessionInput()
    }
    
    @IBAction func toggleTorch(_ sender: Any){
        let device = self.captureDevice(forPosition: .back)!
        print("toggleTorch")
        if device.hasTorch {
            // lock your device for configuration
            do {
                try device.lockForConfiguration()
                print("locked")
            } catch {
                print("Could not lock for configuration")
            }

            // check if your torchMode is on or off. If on turns it off otherwise turns it on
            if device.isTorchActive {
                print("isTorchActive")
                device.torchMode = AVCaptureDevice.TorchMode.off
            } else {
                print("not isTorchActive")
                device.torchMode = AVCaptureDevice.TorchMode.on
            }
            device.unlockForConfiguration()
            print("unlocked")
        }else{
            print("no hasTorch")
            
        }
    }
    
    @IBAction func exitRecognition(_ sender: Any){
        self.call?.reject("A kamera be lett zárva")
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }

    // MARK: Detections
    
    private func recognizeQR(in image: VisionImage){
        var barcodes: [Barcode];
        let barcodeOptions = BarcodeScannerOptions(formats: .qrCode)
        let barcodeScanner = BarcodeScanner.barcodeScanner(options: barcodeOptions)
        do {
            barcodes = try barcodeScanner.results(in: image)
            if barcodes.count > 0{
                let barcode = (barcodes[0].rawValue)!
                self.call?.resolve(["scanner_result":["value":barcode]])
                print("BARCODE", (barcodes[0].rawValue)!)
                DispatchQueue.main.async {
                    self.dismiss(animated: true, completion: nil)
                }
            }
            
        } catch let error {
          print("Failed to recognize text with error: \(error.localizedDescription).")
          self.updatePreviewOverlayViewWithLastFrame()
          return
        }
        self.updatePreviewOverlayViewWithLastFrame()
    }
    
    private func recognizeText(in image: VisionImage, width: CGFloat, height: CGFloat) {
      
      var recognizedText: Text
      do {
        recognizedText = try TextRecognizer.textRecognizer()
          .results(in: image)
      } catch let error {
        print("Failed to recognize text with error: \(error.localizedDescription).")
        self.updatePreviewOverlayViewWithLastFrame()
        return
      }
      self.updatePreviewOverlayViewWithLastFrame()
      weak var weakSelf = self
      DispatchQueue.main.sync {
        guard let strongSelf = weakSelf else {
          print("Self is nil!")
          return
        }

        var prevLine = ""
        var rawAll = ""
        var rawFullRead = ""
        // Blocks.
        for block in recognizedText.blocks {
          // Lines.
          for line in block.lines {
            rawAll.append(line.text+"\n")
            if (line.text.contains("<") || (prevLine != "" && prevLine.contains("<") && prevLine.length == line.text.length)
            ) {
                rawFullRead.append(line.text+"\n")
                
                /*
                  let points = strongSelf.convertedPoints(
                    from: line.cornerPoints, width: width, height: height)
                  UIUtilities.addShape(
                    withPoints: points,
                    to: strongSelf.annotationOverlayView,
                    color: UIColor.orange
                  )
                */
            }
            prevLine = line.text;
          }
        }
        
        do{
            let cleanMrz = try self.cleaner.clean(rawFullRead)
            print("\n\n\n\(cleanMrz)")
            print("timeee", analyzeStart, Int64(Date().timeIntervalSince1970*1000)-analyzeStart, analyzeTime)
            
            if (!cleanMrz.starts(with: "I<HUN") || ((Int64(Date().timeIntervalSince1970*1000)-analyzeStart) > analyzeTime)){
                print("ignoring analyzeTime \((!cleanMrz.starts(with: "I<HUN"))) or \(((Int64(Date().timeIntervalSince1970*1000)-analyzeStart) > analyzeTime)))")
            }else{
                print("still in analyzeTime and format is ok!")

                if(
                    !rawAll.contains("Anyja") &&
                  !rawAll.contains("anyja") &&
                  !rawAll.contains("Mother") &&
                  !rawAll.contains("mother")
                ){
                    throw MrzError.IllegalArgument("Could not find mother's name.")
                }else{
                  print("Check mother's name OK")
                }
                if(
                  !rawAll.contains("hely") &&
                  !rawAll.contains("place") &&
                  !rawAll.contains("Hely") &&
                  !rawAll.contains("Place")
                ){
                    throw MrzError.IllegalArgument("Could not find birth place.")
                }else{
                  print("Check birth place OK")
                }
                print("rawAll", rawAll)
            }
            let record = try self.cleaner.parseAndClean(cleanMrz)
            
            let dateOfBirth = record.dateOfBirth.toStringNormal()
            let expirationDate = record.expirationDate.toStringNormal()
            
            let code = record.code.rawValue
            let code1 = record.code1
            let code2 = record.code2
            let documentNumber = record.documentNumber
            let issuingCountry = record.issuingCountry
            let givenNames = record.givenNames
            let nationality = record.nationality
            let validComposite = record.validComposite
            let sex = (record.sex.rawValue == "M" ? "Male" : (record.sex.rawValue == "F" ? "Female" : "Unspecified"))
            let mrz = try record.toMrz()
            let surname = record.surname
            let format = record.format.toString()
            
            let scannerResult: Dictionary<String, Any> = (["image": "---",
                "code": code,
                "code1": code1,
                "code2": code2,
                "dateOfBirth": dateOfBirth,
                "documentNumber": documentNumber,
                "expirationDate": expirationDate,
                "format": format,
                "givenNames": givenNames,
                "issuingCountry": issuingCountry,
                "nationality": nationality,
                "sex": sex,
                "surname": surname,
                "mrz": mrz,
                "validComposite": validComposite,
                "rawAll": rawAll
            ])
            
            self.call?.resolve(["scanner_result": scannerResult])
            self.dismiss(animated: true, completion: nil)
        } catch{
            print("Parsing error", error)
            return
        }
      }
        
    }

    // MARK: - Private
    private func setUpCaptureSessionOutput() {
      weak var weakSelf = self
      sessionQueue.async {
        guard let strongSelf = weakSelf else {
          print("Self is nil!")
          return
        }
        strongSelf.captureSession.beginConfiguration()
        // When performing latency tests to determine ideal capture settings,
        // run the app in 'release' mode to get accurate performance metrics
        strongSelf.captureSession.sessionPreset = AVCaptureSession.Preset.high

        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [
          (kCVPixelBufferPixelFormatTypeKey as String): kCVPixelFormatType_32BGRA
        ]
        output.alwaysDiscardsLateVideoFrames = true
        let outputQueue = DispatchQueue(label: Constant.videoDataOutputQueueLabel)
        output.setSampleBufferDelegate(strongSelf, queue: outputQueue)
        guard strongSelf.captureSession.canAddOutput(output) else {
          print("Failed to add capture session output.")
          return
        }
        strongSelf.captureSession.addOutput(output)
        strongSelf.captureSession.commitConfiguration()
      }
    }

    private func setUpCaptureSessionInput() {
      weak var weakSelf = self
      sessionQueue.async {
        guard let strongSelf = weakSelf else {
          print("Self is nil!")
          return
        }
        let cameraPosition: AVCaptureDevice.Position = strongSelf.isUsingFrontCamera ? .front : .back
        guard let device = strongSelf.captureDevice(forPosition: cameraPosition) else {
          print("Failed to get capture device for camera position: \(cameraPosition)")
          return
        }
        do {
          strongSelf.captureSession.beginConfiguration()
          let currentInputs = strongSelf.captureSession.inputs
          for input in currentInputs {
            strongSelf.captureSession.removeInput(input)
          }

          let input = try AVCaptureDeviceInput(device: device)
          guard strongSelf.captureSession.canAddInput(input) else {
            print("Failed to add capture session input.")
            return
          }
          strongSelf.captureSession.addInput(input)
            print("Device formats")
            for format in device.formats {
                print(format)
            }
          strongSelf.captureSession.commitConfiguration()
        } catch {
          print("Failed to create capture device input: \(error.localizedDescription)")
        }
      }
    }

    private func startSession() {
      weak var weakSelf = self
      sessionQueue.async {
        guard let strongSelf = weakSelf else {
          print("Self is nil!")
          return
        }
        strongSelf.captureSession.startRunning()
      }
    }

    private func stopSession() {
      weak var weakSelf = self
      sessionQueue.async {
        guard let strongSelf = weakSelf else {
          print("Self is nil!")
          return
        }
        strongSelf.captureSession.stopRunning()
      }
    }

    private func setUpPreviewOverlayView() {
      cameraView.addSubview(previewOverlayView)
      NSLayoutConstraint.activate([
        previewOverlayView.centerXAnchor.constraint(equalTo: cameraView.centerXAnchor),
        previewOverlayView.centerYAnchor.constraint(equalTo: cameraView.centerYAnchor),
        previewOverlayView.leadingAnchor.constraint(equalTo: cameraView.leadingAnchor),
        previewOverlayView.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor),

      ])
    }

    private func setUpAnnotationOverlayView() {
      cameraView.addSubview(annotationOverlayView)
      NSLayoutConstraint.activate([
        annotationOverlayView.topAnchor.constraint(equalTo: cameraView.topAnchor),
        annotationOverlayView.leadingAnchor.constraint(equalTo: cameraView.leadingAnchor),
        annotationOverlayView.trailingAnchor.constraint(equalTo: cameraView.trailingAnchor),
        annotationOverlayView.bottomAnchor.constraint(equalTo: cameraView.bottomAnchor),
      ])
    }

    private func captureDevice(forPosition position: AVCaptureDevice.Position) -> AVCaptureDevice? {
      if #available(iOS 10.0, *) {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .back
        )
        return discoverySession.devices.first { $0.position == position }
      }
      return nil
    }

    private func removeDetectionAnnotations() {
      for annotationView in annotationOverlayView.subviews {
        annotationView.removeFromSuperview()
      }
    }

    private func updatePreviewOverlayViewWithLastFrame() {
      weak var weakSelf = self
      DispatchQueue.main.sync {
        guard let strongSelf = weakSelf else {
          print("Self is nil!")
          return
        }

        guard let lastFrame = lastFrame,
          let imageBuffer = CMSampleBufferGetImageBuffer(lastFrame)
        else {
          return
        }
        strongSelf.updatePreviewOverlayViewWithImageBuffer(imageBuffer)
        strongSelf.removeDetectionAnnotations()
      }
    }
    
    private func updatePreviewOverlayViewWithImageBuffer(_ imageBuffer: CVImageBuffer?) {
      guard let imageBuffer = imageBuffer else {
        return
      }
        let orientation = UIUtilities.imageOrientation(
            fromDevicePosition: .back
          )
        let image = UIUtilities.createUIImage(from: imageBuffer, orientation: orientation)
      
        previewOverlayView.image = image
    }

    private func convertedPoints(
      from points: [NSValue]?,
      width: CGFloat,
      height: CGFloat
    ) -> [NSValue]? {
      return points?.map {
        let cgPointValue = $0.cgPointValue
        let normalizedPoint = CGPoint(x: cgPointValue.x / width, y: cgPointValue.y / height)
        let cgPoint = previewLayer.layerPointConverted(fromCaptureDevicePoint: normalizedPoint)
        let value = NSValue(cgPoint: cgPoint)
        return value
      }
    }

    private func normalizedPoint(
      fromVisionPoint point: VisionPoint,
      width: CGFloat,
      height: CGFloat
    ) -> CGPoint {
      let cgPoint = CGPoint(x: point.x, y: point.y)
      var normalizedPoint = CGPoint(x: cgPoint.x / width, y: cgPoint.y / height)
      normalizedPoint = previewLayer.layerPointConverted(fromCaptureDevicePoint: normalizedPoint)
      return normalizedPoint
    }

    private func rotate(_ view: UIView, orientation: UIImage.Orientation) {
      var degree: CGFloat = 0.0
      switch orientation {
      case .up, .upMirrored:
        degree = 90.0
      case .rightMirrored, .left:
        degree = 180.0
      case .down, .downMirrored:
        degree = 270.0
      case .leftMirrored, .right:
        degree = 0.0
      }
      view.transform = CGAffineTransform.init(rotationAngle: degree * 3.141592654 / 180)
    }
    
    
    
    
    
}
extension SmartScannerViewController: AVCaptureVideoDataOutputSampleBufferDelegate {

  public func captureOutput(
    _ output: AVCaptureOutput,
    didOutput sampleBuffer: CMSampleBuffer,
    from connection: AVCaptureConnection
  ) {
    guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
      print("Failed to get image buffer from sample buffer.")
      return
    }
    lastFrame = sampleBuffer
    let visionImage = VisionImage(buffer: sampleBuffer)
    let orientation = UIUtilities.imageOrientation(
      fromDevicePosition: .back
    )
    
    visionImage.orientation = orientation
    
    /*
    guard let inputImage = MLImage(sampleBuffer: sampleBuffer) else {
      print("Failed to create MLImage from sample buffer.")
      return
    }
    inputImage.orientation = orientation
    */

    let imageWidth = CGFloat(CVPixelBufferGetWidth(imageBuffer))
    let imageHeight = CGFloat(CVPixelBufferGetHeight(imageBuffer))
    if self.mode == "barcode"{
        recognizeQR(in: visionImage)
    }else{
        recognizeText(in: visionImage, width: imageWidth, height: imageHeight)
    }
  }
    
}





// MARK: - Constants
private enum Constant {
  static let videoDataOutputQueueLabel = "com.google.mlkit.textrecognizer.VideoDataOutputQueue"
  static let sessionQueueLabel = "com.google.mlkit.textrecognizer.SessionQueue"
}
