//
//  ImmersiveViewModel.swift
//  HarvardHack25
//

import SwiftUI
import Combine
import AVFoundation
import ImageIO
import UniformTypeIdentifiers
import CoreGraphics

@MainActor
final class ImmersiveViewModel: ObservableObject {

    // MARK: Public UI state (kept for compatibility with your views)
    @Published private(set) var objects: [TrackedObjectState] = []
    @Published private(set) var isStreaming: Bool = false
    @Published private(set) var lastErrorDescription: String?

    // Optional debug
    @Published private(set) var lastJPEGBytes: Int = 0
    @Published private(set) var lastCropSide: Int = 0
    @Published private(set) var lastLANCaption: String = ""

    // MARK: Private
    private let ttsSynth = AVSpeechSynthesizer()
    private let fallbackCaption = "beer."

    // Use the LAN client from Services/
    private let lanClient = LANCaptionClient()

    // MARK: Lifecycle
    func onAppear() {
        _ = AVSpeechSynthesisVoice(language: "en-US") // prewarm TTS
        isStreaming = true // cosmetic for the header
    }

    func onDisappear() { isStreaming = false }

    // MARK: Action: ONE button path — load image -> ROI/JPEG -> POST (local) -> speak
    /// Uses "gift.jpg" from your app bundle (change name/extension below if needed).
    func scanOnceHardcoded() {
        Task { [weak self] in
            guard let self else { return }
            do {
                // 1) Load bundled image
                guard let url = Bundle.main.url(forResource: "gift", withExtension: "jpg"),
                      let src = CGImageSourceCreateWithURL(url as CFURL, nil),
                      let cg  = CGImageSourceCreateImageAtIndex(src, 0, nil)
                else {
                    throw SimpleError("Failed to load bundled gift.jpg")
                }

                // 2) ROI -> JPEG
                let (jpeg, side) = try Self.centerSquareJPEG(from: cg)
                self.lastJPEGBytes = jpeg.count
                self.lastCropSide  = side

                // 3) POST to local server; if it fails, fall back to a local caption
                let prompt = "Return one short sentence (<=12 words) describing the central object."
                let caption = await lanClient.caption(jpeg: jpeg, prompt: prompt)
                let spoken  = (caption?.isEmpty == false) ? caption! : fallbackCaption
                self.lastLANCaption = spoken

                // 4) Speak
                self.speak(spoken)

            } catch {
                self.lastErrorDescription = error.localizedDescription
                self.lastLANCaption = "Not sure."
                self.speak("Not sure.")
            }
        }
    }

    // MARK: TTS
    private func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text.isEmpty ? "Not sure." : text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate  = AVSpeechUtteranceDefaultSpeechRate
        ttsSynth.speak(utterance)
    }

    // MARK: Image processing (self-contained)
    /// Returns (jpegData, outputSide). Hardcoded 320x320 @ ~0.65 quality.
    private static func centerSquareJPEG(from cg: CGImage) throws -> (Data, Int) {
        let outputSide = 320
        let quality: CGFloat = 0.65

        // Center square crop
        let w = cg.width, h = cg.height
        let cropSide = min(w, h)
        let x = (w - cropSide) / 2
        let y = (h - cropSide) / 2
        guard let cropped = cg.cropping(to: CGRect(x: x, y: y, width: cropSide, height: cropSide)) else {
            throw SimpleError("Crop failed")
        }

        // Scale to outputSide x outputSide
        let cs = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(data: nil,
                                  width: outputSide, height: outputSide,
                                  bitsPerComponent: 8,
                                  bytesPerRow: outputSide * 4,
                                  space: cs,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { throw SimpleError("Scale context failed") }

        ctx.interpolationQuality = .high
        ctx.draw(cropped, in: CGRect(x: 0, y: 0, width: outputSide, height: outputSide))
        guard let scaled = ctx.makeImage() else {
            throw SimpleError("Scale image failed")
        }

        // JPEG encode
        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw SimpleError("JPEG destination failed")
        }
        CGImageDestinationAddImage(dest, scaled, [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
        guard CGImageDestinationFinalize(dest) else {
            throw SimpleError("JPEG finalize failed")
        }
        return (data as Data, outputSide)
    }
}

// Tiny local error helper
private struct SimpleError: LocalizedError {
    let message: String
    init(_ message: String) { self.message = message }
    var errorDescription: String? { message }
}

