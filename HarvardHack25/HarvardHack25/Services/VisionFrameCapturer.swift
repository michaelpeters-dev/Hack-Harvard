import Foundation
#if canImport(ARKit) && canImport(WebRTC)
import ARKit
import WebRTC

@MainActor
protocol VisionFrameCapturerDelegate: AnyObject {
    func frameCapturerDidStart(_ capturer: VisionFrameCapturer)
    func frameCapturer(_ capturer: VisionFrameCapturer, didFail error: Error)
}

/// Bridges ARKit camera frames into the WebRTC pipeline.
@MainActor
final class VisionFrameCapturer: NSObject {
    weak var delegate: VisionFrameCapturerDelegate?

    private let session: ARSession
    private let videoSource: RTCVideoSource
    private let rtcCapturer = RTCVideoCapturer(delegate: nil)
    private var isCapturing = false

    init(session: ARSession, videoSource: RTCVideoSource) {
        self.session = session
        self.videoSource = videoSource
        super.init()
    }

    func start() {
        guard isCapturing == false else { return }
        session.delegate = self
        session.run(Self.configuration(), options: [.resetTracking, .removeExistingAnchors])
        isCapturing = true
        delegate?.frameCapturerDidStart(self)
    }

    func stop() {
        guard isCapturing else { return }
        session.pause()
        session.delegate = nil
        isCapturing = false
    }

    private static func configuration() -> ARWorldTrackingConfiguration {
        let config = ARWorldTrackingConfiguration()
        config.environmentTexturing = .automatic
        config.worldAlignment = .gravity
        return config
    }
}

extension VisionFrameCapturer: ARSessionDelegate {
    func session(_ session: ARSession, didFailWithError error: Error) {
        delegate?.frameCapturer(self, didFail: error)
    }

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard isCapturing else { return }
        let pixelBuffer = frame.capturedImage
        let rtcPixelBuffer = RTCCVPixelBuffer(pixelBuffer: pixelBuffer)
        let timestamp = Int64(frame.timestamp * Double(NSEC_PER_SEC))
        let rtcFrame = RTCVideoFrame(buffer: rtcPixelBuffer, rotation: ._0, timeStampNs: timestamp)
        videoSource.capturer(rtcCapturer, didCapture: rtcFrame)
    }
}

#else

@MainActor
protocol VisionFrameCapturerDelegate: AnyObject {
    func frameCapturerDidStart(_ capturer: VisionFrameCapturer)
    func frameCapturer(_ capturer: VisionFrameCapturer, didFail error: Error)
}

@MainActor
final class VisionFrameCapturer {
    weak var delegate: VisionFrameCapturerDelegate?

    init(session: Any, videoSource: Any) {}

    func start() {
        delegate?.frameCapturer(self, didFail: AppError.notImplemented(feature: "ARKit/WebRTC capture unavailable"))
    }

    func stop() {}
}

#endif
