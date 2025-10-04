import Foundation
import AVFoundation

struct CameraFrame: Sendable {
    let buffer: CMSampleBuffer
    let captureDate: Date

    init(buffer: CMSampleBuffer, captureDate: Date = Date()) {
        self.buffer = buffer
        self.captureDate = captureDate
    }
}
