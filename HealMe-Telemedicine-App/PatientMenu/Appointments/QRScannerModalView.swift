//
//  QRScannerModalView.swift
//  HealMe-Telemedicine-App
//
//  Created by Cristian Montiel García on 17/05/25.
//

import SwiftUI
import AVFoundation

struct QRScannerModalView: View {
    let appointment: Appointment?
    let onQRScanned: (Appointment?) -> Void
    @Environment(\.dismiss) var dismiss
    @StateObject private var scanner = QRCodeScanner()
    @State private var errorMessage: String = ""
    @State private var isProcessing: Bool = false
    @State private var hasStartedScanning: Bool = false

    private let colors = (
        red: Color(hex: "D40035"),
        green: Color(hex: "28A745"),
        background: Color(hex: "F5F6F9")
    )

    var body: some View {
        ZStack {
            colors.background
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Validar Cita")
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.top, 35)

                if appointment == nil {
                    Text("Error: No se proporcionó una cita válida")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(colors.red)
                        .padding(.horizontal)
                } else if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(colors.red)
                        .padding(.horizontal)
                } else {
                    VStack(spacing: 2) {
                        Text("¡Tu médico ha sido encontrado!")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.green)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        Text("Escanea el código QR para validar tu cita:")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }

                if scanner.isCameraAvailable {
                    ZStack {
                        QRScannerView(scanner: scanner)
                            .frame(height: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(colors.green, lineWidth: 2)
                            )

                        // Guía visual para el QR
                        Rectangle()
                            .fill(Color.black.opacity(0.5))
                            .mask(
                                RoundedRectangle(cornerRadius: 12)
                                    .frame(width: 200, height: 200)
                                    .blendMode(.destinationOut)
                            )
                    }
                    .padding(.horizontal, 16)
                } else {
                    Text("No se puede acceder a la cámara. Por favor, habilita los permisos en Configuración.")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(colors.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button(action: {
                    dismiss()
                }) {
                    Text("Cancelar")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 16)
                .disabled(isProcessing)
            }
        }
        .onAppear {
            print("QRScannerModalView appeared with appointment: \(String(describing: appointment))")
            if !hasStartedScanning {
                hasStartedScanning = true
                scanner.startScanning()
            }
        }
        .onDisappear {
            scanner.stopScanning()
        }
        .onChange(of: scanner.scannedCode) { _, newCode in
            if let code = newCode, !isProcessing {
                isProcessing = true
                handleScannedCode(code)
            }
        }
    }

    private func handleScannedCode(_ code: String) {
        print("QR code scanned: \(code)")
        guard let appointment = appointment else {
            errorMessage = "No se proporcionó una cita válida"
            isProcessing = false
            return
        }

        // Parsear el código QR como JSON
        guard let data = code.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: String],
              let appointmentId = json["appointmentId"] else {
            errorMessage = "Código QR inválido: no contiene un appointmentId válido"
            print("Invalid QR code: \(code)")
            isProcessing = false
            return
        }

        // Validar el formato del appointmentId (por ejemplo, XXXX-XXXX-XXXX)
        let idPattern = "^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$"
        guard let regex = try? NSRegularExpression(pattern: idPattern),
              regex.firstMatch(in: appointmentId, range: NSRange(location: 0, length: appointmentId.utf16.count)) != nil else {
            errorMessage = "Formato de appointmentId inválido"
            print("Invalid appointmentId format: \(appointmentId)")
            isProcessing = false
            return
        }

        print("Valid appointmentId: \(appointmentId)")
        onQRScanned(appointment)
        dismiss()
    }
}

// Clase para manejar el escáner de QR
class QRCodeScanner: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    @Published var scannedCode: String?
    @Published var isCameraAvailable: Bool = false
    @Published var captureSession: AVCaptureSession? // Ahora Published para notificar cambios
    private let scanningQueue = DispatchQueue(label: "com.healme.qrscanner", qos: .userInitiated)
    private var isScanning: Bool = false

    override init() {
        super.init()
        checkCameraPermission()
    }

    func checkCameraPermission() {
        print("Checking camera permission")
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            print("Camera permission authorized")
            isCameraAvailable = true
        case .notDetermined:
            print("Camera permission not determined, requesting access")
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                print("Camera permission request result: \(granted)")
                DispatchQueue.main.async {
                    self?.isCameraAvailable = granted
                    if granted {
                        self?.startScanning()
                    }
                }
            }
        case .denied, .restricted:
            print("Camera permission denied or restricted")
            isCameraAvailable = false
        @unknown default:
            print("Camera permission unknown status")
            isCameraAvailable = false
        }
    }

    func startScanning() {
        scanningQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.isCameraAvailable, !self.isScanning else {
                print("Cannot start scanning: isCameraAvailable=\(self.isCameraAvailable), isScanning=\(self.isScanning)")
                return
            }
            self.isScanning = true
            print("Starting camera scanning")

            self.captureSession = AVCaptureSession()
            guard let captureSession = self.captureSession else {
                print("Failed to create AVCaptureSession")
                DispatchQueue.main.async {
                    self.isCameraAvailable = false
                    self.isScanning = false
                }
                return
            }

            // Configurar el dispositivo de captura (cámara trasera)
            guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
                print("Failed to get video capture device")
                DispatchQueue.main.async {
                    self.isCameraAvailable = false
                    self.isScanning = false
                    self.captureSession = nil
                }
                return
            }

            guard let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice) else {
                print("Failed to create AVCaptureDeviceInput")
                DispatchQueue.main.async {
                    self.isCameraAvailable = false
                    self.isScanning = false
                    self.captureSession = nil
                }
                return
            }

            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
                print("Video input added successfully")
            } else {
                print("Failed to add video input")
                DispatchQueue.main.async {
                    self.isCameraAvailable = false
                    self.isScanning = false
                    self.captureSession = nil
                }
                return
            }

            // Configurar la salida de metadatos
            let metadataOutput = AVCaptureMetadataOutput()
            if captureSession.canAddOutput(metadataOutput) {
                captureSession.addOutput(metadataOutput)
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr]
                print("Metadata output added successfully")
            } else {
                print("Failed to add metadata output")
                DispatchQueue.main.async {
                    self.isCameraAvailable = false
                    self.isScanning = false
                    self.captureSession = nil
                }
                return
            }

            // Iniciar la sesión
            print("Starting AVCaptureSession")
            captureSession.startRunning()
            DispatchQueue.main.async {
                self.captureSession = captureSession // Notificar cambio
            }
        }
    }

    func stopScanning() {
        scanningQueue.async { [weak self] in
            guard let self = self else { return }
            print("Stopping camera scanning")
            self.captureSession?.stopRunning()
            DispatchQueue.main.async {
                self.captureSession = nil
                self.isScanning = false
            }
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              metadataObject.type == .qr,
              let stringValue = metadataObject.stringValue else {
            return
        }
        print("Metadata output received: \(stringValue)")
        DispatchQueue.main.async { [weak self] in
            self?.scannedCode = stringValue
            self?.stopScanning()
        }
    }
}

// Vista para mostrar la previsualización de la cámara
struct QRScannerView: UIViewControllerRepresentable {
    @ObservedObject var scanner: QRCodeScanner

    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .black // Fondo por defecto
        updatePreviewLayer(for: controller)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        updatePreviewLayer(for: uiViewController)
    }

    private func updatePreviewLayer(for controller: UIViewController) {
        // Limpiar capas existentes
        controller.view.layer.sublayers?.filter { $0 is AVCaptureVideoPreviewLayer }.forEach { $0.removeFromSuperlayer() }

        guard let captureSession = scanner.captureSession else {
            print("No capture session available for preview")
            return
        }

        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = controller.view.bounds
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        controller.view.layer.addSublayer(previewLayer)
        print("Preview layer added with frame: \(previewLayer.frame)")
    }
}

struct QRScannerModalView_Previews: PreviewProvider {
    static var previews: some View {
        QRScannerModalView(appointment: nil) { _ in }
    }
}
