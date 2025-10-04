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

    // MARK: Public UI state
    @Published private(set) var objects: [TrackedObjectState] = []
    @Published private(set) var isStreaming: Bool = false
    @Published private(set) var lastErrorDescription: String?
    @Published private(set) var helperStatus: HelperStatus = .idle

    // Optional debug
    @Published private(set) var lastJPEGBytes: Int = 0
    @Published private(set) var lastCropSide: Int = 0
    @Published private(set) var lastLANCaption: String = ""

    // MARK: Private
    private let ttsSynth = AVSpeechSynthesizer()
    private let fallbackCaption = "beer."
    private let lanClient = LANCaptionClient()
    private let helperService: HelperEscalationHandling?

    init(helperService: HelperEscalationHandling? = nil) {
        self.helperService = helperService
    }

    // MARK: Lifecycle
    func onAppear() {
        _ = AVSpeechSynthesisVoice(language: "en-US") // prewarm TTS
        isStreaming = true
    }

    func onDisappear() {
        isStreaming = false
    }

    // MARK: Actions
    func scanOnceHardcoded() {
        Task { [weak self] in
            guard let self else { return }
            do {
                guard let url = Bundle.main.url(forResource: "gift", withExtension: "jpg"),
                      let src = CGImageSourceCreateWithURL(url as CFURL, nil),
                      let cg = CGImageSourceCreateImageAtIndex(src, 0, nil)
                else {
                    throw SimpleError("Failed to load bundled gift.jpg")
                }

                let (jpeg, side) = try Self.centerSquareJPEG(from: cg)
                self.lastJPEGBytes = jpeg.count
                self.lastCropSide = side

                let prompt = "Return one short sentence (<=12 words) describing the central object."
                let caption = await lanClient.caption(jpeg: jpeg, prompt: prompt)
                let spoken = (caption?.isEmpty == false) ? caption! : fallbackCaption
                self.lastLANCaption = spoken

                self.speak(spoken)
            } catch {
                self.lastErrorDescription = error.localizedDescription
                self.lastLANCaption = "Not sure."
                self.speak("Not sure.")
            }
        }
    }

    func submitHelperRequest(with context: String) {
        let trimmed = context.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.isEmpty == false else { return }

        helperStatus = .sending

        guard let helperService else {
            helperStatus = .simulatedAcknowledged(context: trimmed)
            return
        }

        Task { [weak self] in
            guard let self else { return }
            do {
                try await helperService.requestHelper(with: .manualRequest(context: trimmed))
                await MainActor.run {
                    self.helperStatus = .sent
                }
            } catch {
                await MainActor.run {
                    self.helperStatus = .failed
                    self.lastErrorDescription = error.localizedDescription
                }
            }
        }
    }

    // MARK: TTS
    private func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text.isEmpty ? "Not sure." : text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        ttsSynth.speak(utterance)
    }

    // MARK: Image processing
    private static func centerSquareJPEG(from cg: CGImage) throws -> (Data, Int) {
        let outputSide = 320
        let quality: CGFloat = 0.65

        let w = cg.width
        let h = cg.height
        let cropSide = min(w, h)
        let x = (w - cropSide) / 2
        let y = (h - cropSide) / 2

        guard let cropped = cg.cropping(to: CGRect(x: x, y: y, width: cropSide, height: cropSide)) else {
            throw SimpleError("Crop failed")
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: nil,
                                      width: outputSide,
                                      height: outputSide,
                                      bitsPerComponent: 8,
                                      bytesPerRow: outputSide * 4,
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            throw SimpleError("Scale context failed")
        }

        context.interpolationQuality = .high
        context.draw(cropped, in: CGRect(x: 0, y: 0, width: outputSide, height: outputSide))
        guard let scaled = context.makeImage() else {
            throw SimpleError("Scale image failed")
        }

        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw SimpleError("JPEG destination failed")
        }

        CGImageDestinationAddImage(destination, scaled, [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            throw SimpleError("JPEG finalize failed")
        }
        return (data as Data, outputSide)
    }

    enum HelperStatus: Equatable {
        case idle
        case sending
        case sent
        case failed
        case simulatedAcknowledged(context: String)
    }
}

// Tiny local error helper
private struct SimpleError: LocalizedError {
    let message: String
    init(_ message: String) { self.message = message }
    var errorDescription: String? { message }
}
