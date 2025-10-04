import Foundation
import AVFoundation

@MainActor
final class CameraService: NSObject, ObservableObject {
    private let session = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "mobile.camera.session")
    private let streamingService: MobileStreamingService
    private var authorizationStatus: AVAuthorizationStatus {
        AVCaptureDevice.authorizationStatus(for: .video)
    }

    init(streamingService: MobileStreamingService) {
        self.streamingService = streamingService
        super.init()
    }

    func start() {
        Task {
            guard await requestAuthorizationIfNeeded() else { return }
            sessionQueue.async { [weak self] in
                guard let self else { return }
                do {
                    try configureSession()
                    if self.session.isRunning == false {
                        self.session.startRunning()
                    }
                } catch {
                    // TODO: propagate error to observable property for UI feedback.
                }
            }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if self.session.isRunning {
                self.session.stopRunning()
            }
            self.session.inputs.forEach { self.session.removeInput($0) }
            self.session.outputs.forEach { self.session.removeOutput($0) }
        }
    }

    private func configureSession() throws {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        session.sessionPreset = .hd1280x720

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw AppError.invalidState(reason: "No suitable camera found")
        }

        let input = try AVCaptureDeviceInput(device: camera)
        if session.canAddInput(input) {
            session.addInput(input)
        }

        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: sessionQueue)
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
    }

    private func requestAuthorizationIfNeeded() async -> Bool {
        switch authorizationStatus {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        case .denied, .restricted:
            return false
        @unknown default:
            return false
        }
    }
}

extension CameraService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        let frame = CameraFrame(buffer: sampleBuffer)
        Task {
            await streamingService.enqueue(frame: frame)
        }
    }
}
