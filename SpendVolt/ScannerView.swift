import SwiftUI
import AVFoundation

struct ScannerView: UIViewControllerRepresentable {
    var completion: (String) -> Void
    var validation: ((String) -> QRType)

    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.completion = completion
        controller.validation = validation
        return controller
    }

    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}

    class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
        var captureSession: AVCaptureSession!
        var previewLayer: AVCaptureVideoPreviewLayer!
        var completion: ((String) -> Void)?
        var validation: ((String) -> QRType)?
        
        private var isProcessing = false
        private var errorLabel: UILabel?

        override func viewDidLoad() {
            super.viewDidLoad()

            view.backgroundColor = .black
            
            #if targetEnvironment(simulator)
            // Show message for simulator
            let label = UILabel()
            label.text = "Camera not available on Simulator.\nPlease use a physical device."
            label.textColor = .white
            label.numberOfLines = 0
            label.textAlignment = .center
            label.frame = view.bounds
            view.addSubview(label)
            #else
            setupCaptureSession()
            addOverlay()
            #endif
            
            addCloseButton()
            setupErrorLabel()
        }
        
        private func setupErrorLabel() {
            let label = UILabel()
            label.backgroundColor = UIColor.red.withAlphaComponent(0.8)
            label.textColor = .white
            label.textAlignment = .center
            label.font = .systemFont(ofSize: 14, weight: .bold)
            label.layer.cornerRadius = 8
            label.clipsToBounds = true
            label.alpha = 0
            label.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(label)
            self.errorLabel = label
            
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
                label.widthAnchor.constraint(equalToConstant: 280),
                label.heightAnchor.constraint(equalToConstant: 44)
            ])
        }
        
        func showScanError(message: String) {
            guard let label = errorLabel, label.alpha == 0 else { return }
            
            label.text = message
            UIView.animate(withDuration: 0.3) {
                label.alpha = 1
            }
            
            // Vibrate for error
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                UIView.animate(withDuration: 0.3) {
                    label.alpha = 0
                } completion: { _ in
                    self.isProcessing = false
                }
            }
        }
        
        func setupCaptureSession() {
            captureSession = AVCaptureSession()

            guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
                showError(message: "Rear camera not found")
                return
            }
            
            let videoInput: AVCaptureDeviceInput

            do {
                videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            } catch {
                showError(message: "Could not create camera input")
                return
            }

            if (captureSession.canAddInput(videoInput)) {
                captureSession.addInput(videoInput)
            } else {
                showError(message: "Could not add input to session")
                return
            }

            let metadataOutput = AVCaptureMetadataOutput()

            if (captureSession.canAddOutput(metadataOutput)) {
                captureSession.addOutput(metadataOutput)

                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr]
            } else {
                showError(message: "Could not add output for QR scanning")
                return
            }

            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = view.layer.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)

            // Start session in background thread to avoid blocking UI
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
        }
        
        func addOverlay() {
            let overlay = ScannerOverlayView(frame: view.bounds)
            overlay.backgroundColor = .clear
            view.addSubview(overlay)
            
            let label = UILabel()
            label.text = "Align QR Code within the frame"
            label.textColor = .white
            label.font = .systemFont(ofSize: 14, weight: .medium)
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(label)
            
            NSLayoutConstraint.activate([
                label.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100),
                label.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            ])
        }
        
        func addCloseButton() {
            let button = UIButton(type: .system)
            button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
            button.tintColor = .white.withAlphaComponent(0.8)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.addTarget(self, action: #selector(closeScanner), for: .touchUpInside)
            
            let config = UIImage.SymbolConfiguration(pointSize: 28, weight: .medium)
            button.setPreferredSymbolConfiguration(config, forImageIn: .normal)
            
            view.addSubview(button)
            
            NSLayoutConstraint.activate([
                button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
                button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
            ])
        }
        
        @objc func closeScanner() {
            dismiss(animated: true)
        }
        
        func showError(message: String) {
            let label = UILabel()
            label.text = message
            label.textColor = .red
            label.textAlignment = .center
            label.frame = view.bounds
            view.addSubview(label)
        }

        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            guard !isProcessing else { return }
            
            if let metadataObject = metadataObjects.first {
                guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
                guard let stringValue = readableObject.stringValue else { return }
                
                isProcessing = true
                
                let result = self.validation?(stringValue) ?? .invalid
                
                switch result {
                case .merchant:
                    // Vibrate and return result
                    AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                    
                    DispatchQueue.main.async {
                        self.captureSession.stopRunning()
                        self.completion?(stringValue)
                        self.dismiss(animated: true)
                    }
                    
                case .personal:
                    // Vibrate and return result (we'll show alert in HomeView)
                    AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                    
                    DispatchQueue.main.async {
                        self.captureSession.stopRunning()
                        self.completion?(stringValue) // We still return the string so HomeView knows it was a personal QR
                        self.dismiss(animated: true)
                    }
                    
                case .invalid:
                    showScanError(message: "Invalid Merchant QR Code")
                }
            }
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            if (captureSession?.isRunning == false) {
                DispatchQueue.global(qos: .userInitiated).async {
                    self.captureSession.startRunning()
                }
            }
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            if (captureSession?.isRunning == true) {
                captureSession.stopRunning()
            }
        }

        override var prefersStatusBarHidden: Bool {
            return true
        }

        override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
            return .portrait
        }
    }
}

class ScannerOverlayView: UIView {
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let overlayColor = UIColor.black.withAlphaComponent(0.5)
        let rectSize: CGFloat = 260
        let scanRect = CGRect(
            x: (rect.width - rectSize) / 2,
            y: (rect.height - rectSize) / 2 - 50, // Slightly above center
            width: rectSize,
            height: rectSize
        )
        
        // 1. Draw darkened background
        context.setFillColor(overlayColor.cgColor)
        context.fill(rect)
        
        // 2. Clear the middle square
        context.setBlendMode(.clear)
        let path = UIBezierPath(roundedRect: scanRect, cornerRadius: 20)
        path.fill()
        
        // 3. Draw white corners
        context.setBlendMode(.normal)
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(4.0)
        context.setLineCap(.round)
        
        let cornerLength: CGFloat = 30
        let offset: CGFloat = 2
        
        // Top Left
        let topLeft = UIBezierPath()
        topLeft.move(to: CGPoint(x: scanRect.minX + offset, y: scanRect.minY + cornerLength + offset))
        topLeft.addLine(to: CGPoint(x: scanRect.minX + offset, y: scanRect.minY + offset))
        topLeft.addLine(to: CGPoint(x: scanRect.minX + cornerLength + offset, y: scanRect.minY + offset))
        topLeft.stroke()
        
        // Top Right
        let topRight = UIBezierPath()
        topRight.move(to: CGPoint(x: scanRect.maxX - cornerLength - offset, y: scanRect.minY + offset))
        topRight.addLine(to: CGPoint(x: scanRect.maxX - offset, y: scanRect.minY + offset))
        topRight.addLine(to: CGPoint(x: scanRect.maxX - offset, y: scanRect.minY + cornerLength + offset))
        topRight.stroke()
        
        // Bottom Left
        let bottomLeft = UIBezierPath()
        bottomLeft.move(to: CGPoint(x: scanRect.minX + offset, y: scanRect.maxY - cornerLength - offset))
        bottomLeft.addLine(to: CGPoint(x: scanRect.minX + offset, y: scanRect.maxY - offset))
        bottomLeft.addLine(to: CGPoint(x: scanRect.minX + cornerLength + offset, y: scanRect.maxY - offset))
        bottomLeft.stroke()
        
        // Bottom Right
        let bottomRight = UIBezierPath()
        bottomRight.move(to: CGPoint(x: scanRect.maxX - cornerLength - offset, y: scanRect.maxY - offset))
        bottomRight.addLine(to: CGPoint(x: scanRect.maxX - offset, y: scanRect.maxY - offset))
        bottomRight.addLine(to: CGPoint(x: scanRect.maxX - offset, y: scanRect.maxY - cornerLength - offset))
        bottomRight.stroke()
    }
}
