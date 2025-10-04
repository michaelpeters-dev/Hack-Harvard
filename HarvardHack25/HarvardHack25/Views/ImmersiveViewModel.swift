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
import Photos   // ✅ NEW

@MainActor
final class ImmersiveViewModel: ObservableObject {

    // Public UI state
    @Published private(set) var objects: [TrackedObjectState] = []
    @Published private(set) var isStreaming: Bool = false
    @Published private(set) var lastErrorDescription: String?
    @Published private(set) var helperStatus: HelperStatus = .idle

    // Diagnostics
    @Published private(set) var lastJPEGBytes: Int = 0
    @Published private(set) var lastCropSide: Int = 0
    @Published private(set) var lastLANCaption: String = ""
    @Published private(set) var endpointDescription: String = ""
    @Published private(set) var lastPingStatus: String = "—"

    // Flow control / caching
    @Published private(set) var isBusy: Bool = false
    @Published private(set) var cachedJPEG: Data?
    @Published private(set) var cachedSide: Int = 0

    // Services
    private let ttsSynth = AVSpeechSynthesizer()
    private let lanClient = LANCaptionClient()
    private let fallbackCaption = "Not sure."
    private let helperService: HelperEscalationHandling?

    init(helperService: HelperEscalationHandling? = nil) {
        self.helperService = helperService
    }

    // MARK: Lifecycle
    func onAppear() {
        _ = AVSpeechSynthesisVoice(language: "en-US") // prewarm TTS
        isStreaming = true
        endpointDescription = lanClient.endpointString

        // Preload something so first tap isn't cold. Try latest photo; fall back to bundle.
        Task.detached { [weak self] in
            guard let self else { return }
            do {
                let (jpeg, side) = try await self.latestPhotoOrBundleJPEG()
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

    // MARK: Scan → latest camera roll → POST → TTS (debounced, retry once)
    func scanLatestFromCameraRoll() {
        guard isBusy == false else { return }
        isBusy = true
        lastErrorDescription = nil

        Task { [weak self] in
            guard let self else { return }
            defer { self.isBusy = false }

            // Always refresh from the latest photo; if that fails, fall back to cache/bundle
            let jpegData: Data
            do {
                let (j, side) = try await self.fetchLatestPhotoJPEG()
                self.cachedJPEG = j
                self.cachedSide = side
                self.lastJPEGBytes = j.count
                self.lastCropSide  = side
                jpegData = j
            } catch {
                // Fallback: use whatever we have cached, or a bundled image
                if let cached = self.cachedJPEG {
                    jpegData = cached
                } else {
                    do {
                        guard let url = Bundle.main.url(forResource: "beer", withExtension: "jpg"),
                              let src = CGImageSourceCreateWithURL(url as CFURL, nil),
                              let cg  = CGImageSourceCreateImageAtIndex(src, 0, nil)
                        else { throw SimpleError("Failed to load beer.jpg") }
                        let (j, side) = try centerSquareJPEG(from: cg)
                        self.cachedJPEG = j
                        self.cachedSide = side
                        self.lastJPEGBytes = j.count
                        self.lastCropSide  = side
                        jpegData = j
                    } catch {
                        self.lastErrorDescription = "No latest photo and bundle fallback failed."
                        self.lastLANCaption = self.fallbackCaption
                        self.speak(self.fallbackCaption)
                        return
                    }
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
                // Attempt #2 (retry)
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
                    self.lastLANCaption = self.fallbackCaption
                    self.speak(self.fallbackCaption)
                }
            }
        }
    }

    // MARK: Helper escalation (UI ornament panel)
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
                await MainActor.run { self.helperStatus = .sent }
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
        utterance.rate  = AVSpeechUtteranceDefaultSpeechRate
        ttsSynth.speak(utterance)
    }

    // MARK: Helper status
    enum HelperStatus: Equatable {
        case idle
        case sending
        case sent
        case failed
        case simulatedAcknowledged(context: String)
    }

    // MARK: Photos helpers

    /// Tries latest-camera-roll photo first; on failure, returns bundled beer.jpg
    private func latestPhotoOrBundleJPEG() async throws -> (Data, Int) {
        do {
            return try await fetchLatestPhotoJPEG()
        } catch {
            // Fallback to bundle (non-fatal during preload)
            guard let url = Bundle.main.url(forResource: "beer", withExtension: "jpg"),
                  let src = CGImageSourceCreateWithURL(url as CFURL, nil),
                  let cg  = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
                throw error
            }
            return try centerSquareJPEG(from: cg)
        }
    }

    /// Requests permission if needed, then fetches most recent photo, center-crop to 320×320 JPEG.
    private func fetchLatestPhotoJPEG() async throws -> (Data, Int) {
        // 1) Auth
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status == .notDetermined {
            let newStatus = await withCheckedContinuation { (cont: CheckedContinuation<PHAuthorizationStatus, Never>) in
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { s in cont.resume(returning: s) }
            }
            guard newStatus == .authorized || newStatus == .limited else {
                throw SimpleError("Photos access denied.")
            }
        } else if !(status == .authorized || status == .limited) {
            throw SimpleError("Photos access denied.")
        }

        // 2) Latest asset
        guard let asset = latestImageAsset() else {
            throw SimpleError("No photos found.")
        }

        // 3) Image data (most reliable on Simulator)
        let data: Data = try await withCheckedThrowingContinuation { cont in
            let opts = PHImageRequestOptions()
            opts.isNetworkAccessAllowed = true
            opts.deliveryMode = .highQualityFormat
            opts.version = .current
            opts.isSynchronous = false

            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: opts) { data, _, _, info in
                if let data { cont.resume(returning: data) }
                else { cont.resume(throwing: SimpleError("Failed to load image data.")) }
            }
        }

        // 4) Convert to CGImage → crop/scale to 320² JPEG (your helper)
        guard let src = CGImageSourceCreateWithData(data as CFData, nil),
              let cg  = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
            throw SimpleError("CGImage decode failed.")
        }
        return try centerSquareJPEG(from: cg)
    }

    private func latestImageAsset() -> PHAsset? {
        let opts = PHFetchOptions()
        opts.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        opts.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        opts.fetchLimit = 1
        return PHAsset.fetchAssets(with: opts).firstObject
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
