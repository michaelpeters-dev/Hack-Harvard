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

    // UI state
    @Published private(set) var objects: [TrackedObjectState] = []
    @Published private(set) var isStreaming: Bool = false
    @Published private(set) var lastErrorDescription: String?

    @Published private(set) var lastJPEGBytes: Int = 0
    @Published private(set) var lastCropSide: Int = 0
    @Published private(set) var lastLANCaption: String = ""
    @Published private(set) var endpointDescription: String = ""
    @Published private(set) var lastPingStatus: String = "—"

    // Hardened flow helpers
    @Published private(set) var isBusy: Bool = false
    @Published private(set) var cachedJPEG: Data?
    @Published private(set) var cachedSide: Int = 0

    // Services
    private let ttsSynth = AVSpeechSynthesizer()
    private let lanClient = LANCaptionClient()
    private let fallbackCaption = "beer."

    // MARK: Lifecycle
    func onAppear() {
        _ = AVSpeechSynthesisVoice(language: "en-US") // prewarm TTS
        isStreaming = true
        endpointDescription = lanClient.endpointString

        // Preload & encode once to avoid first-tap flakiness
        Task.detached { [weak self] in
            guard let self else { return }
            do {
                guard let url = Bundle.main.url(forResource: "beer", withExtension: "jpg"),
                      let src = CGImageSourceCreateWithURL(url as CFURL, nil),
                      let cg  = CGImageSourceCreateImageAtIndex(src, 0, nil)
                else {
                    await MainActor.run {
                        self.lastErrorDescription = "Failed to load beer.jpg (check filename & Target Membership)"
                    }
                    return
                }
                let (jpeg, side) = try centerSquareJPEG(from: cg) // ← free function
                await MainActor.run {
                    self.cachedJPEG    = jpeg
                    self.cachedSide    = side
                    self.lastJPEGBytes = jpeg.count
                    self.lastCropSide  = side
                }
            } catch {
                await MainActor.run { self.lastErrorDescription = error.localizedDescription }
            }
        }
    }

    func onDisappear() { isStreaming = false }

    // MARK: Ping
    func pingServer() {
        Task { [weak self] in
            guard let self else { return }
            let status = await lanClient.ping()
            self.lastPingStatus = status
            if status != "OK" { self.lastErrorDescription = status }
        }
    }

    // MARK: One-button scan -> POST -> TTS (debounced, retry once)
    func scanOnceHardcoded() {
        guard isBusy == false else { return }
        isBusy = true
        lastErrorDescription = nil

        Task { [weak self] in
            guard let self else { return }
            defer { self.isBusy = false }

            // Use cached JPEG if available; otherwise generate once
            let jpegData: Data
            if let cached = cachedJPEG {
                jpegData = cached
            } else {
                do {
                    guard let url = Bundle.main.url(forResource: "beer", withExtension: "jpg"),
                          let src = CGImageSourceCreateWithURL(url as CFURL, nil),
                          let cg  = CGImageSourceCreateImageAtIndex(src, 0, nil)
                    else { throw SimpleError("Failed to load beer.jpg") }
                    let (j, side) = try centerSquareJPEG(from: cg) // ← free function
                    self.cachedJPEG = j
                    self.cachedSide = side
                    self.lastJPEGBytes = j.count
                    self.lastCropSide  = side
                    jpegData = j
                } catch {
                    self.lastErrorDescription = error.localizedDescription
                    self.lastLANCaption = "Not sure."
                    self.speak("Not sure.")
                    return
                }
            }

            let prompt = "Return one short sentence (<=12 words) describing the central object."

            // Attempt #1
            do {
                let c1 = try await lanClient.caption(
                    jpeg: jpegData,
                    prompt: prompt,
                    timeoutMs: lanClient.firstByteDeadlineMs
                )
                let spoken = c1.isEmpty ? fallbackCaption : c1
                self.lastLANCaption = spoken
                self.speak(spoken)
                return
            } catch {
                // Attempt #2 (retry with a slightly longer timeout)
                do {
                    let c2 = try await lanClient.caption(
                        jpeg: jpegData,
                        prompt: prompt,
                        timeoutMs: lanClient.retryDeadlineMs
                    )
                    let spoken = c2.isEmpty ? fallbackCaption : c2
                    self.lastLANCaption = spoken
                    self.speak(spoken)
                } catch {
                    self.lastErrorDescription = "POST failed: \(error.localizedDescription)"
                    self.lastLANCaption = "Not sure."
                    self.speak("Not sure.")
                }
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
}

// Tiny local error helper
private struct SimpleError: LocalizedError {
    let message: String
    init(_ message: String) { self.message = message }
    var errorDescription: String? { message }
}

// MARK: - Free function (non-actor-isolated) JPEG helper
/// Returns (jpegData, outputSide). Hardcoded 320x320 @ ~0.65 quality.
private func centerSquareJPEG(from cg: CGImage) throws -> (Data, Int) {
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
    guard let scaled = ctx.makeImage() else { throw SimpleError("Scale image failed") }

    // JPEG encode
    let data = NSMutableData()
    guard let dest = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil)
    else { throw SimpleError("JPEG destination failed") }
    CGImageDestinationAddImage(dest, scaled, [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
    guard CGImageDestinationFinalize(dest) else { throw SimpleError("JPEG finalize failed") }
    return (data as Data, outputSide)
}

