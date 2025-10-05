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
import Photos

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

    // Preview (optional)
    @Published var latestPreview: UIImage?

    // Flow control / caching
    @Published private(set) var isBusy: Bool = false
    @Published private(set) var cachedJPEG: Data?
    @Published private(set) var cachedSide: Int = 0

    // Services
    private let ttsSynth = AVSpeechSynthesizer()
    private let lanClient = LANCaptionClient()
    private let watcher = PhotoWatcher()
    private let fallbackCaption = "Not sure."
    private let helperService: HelperEscalationHandling?
    private let ownerContact = OwnerContact()

    init(helperService: HelperEscalationHandling? = nil) {
        self.helperService = helperService
    }

    // MARK: - Lifecycle

    func onAppear() {
        _ = AVSpeechSynthesisVoice(language: "en-US") // prewarm TTS
        isStreaming = true
        endpointDescription = lanClient.endpointString

        // Wire watcher → central processing
        watcher.onNewAsset = { [weak self] asset in
            self?.process(asset: asset)
        }
        watcher.onError = { [weak self] msg in
            self?.lastErrorDescription = msg
        }
        watcher.onStatus = { [weak self] msg in
            self?.lastPingStatus = msg
        }
        watcher.start(fireLatestImmediately: false)

        // Warm cache (try latest photo; fall back to bundled image)
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

    func onDisappear() {
        watcher.stop()
        isStreaming = false
    }

    // MARK: - Manual trigger (button)

    func processLatestPhotoNow() {
        guard isBusy == false else { return }
        if let asset = latestImageAsset() {
            process(asset: asset)
        } else {
            lastErrorDescription = "No photos found."
        }
    }

    // MARK: - Ping

    func pingServer() {
        Task { [weak self] in
            guard let self else { return }
            let status = await lanClient.ping()
            self.lastPingStatus = status
            if status != "OK" { self.lastErrorDescription = status }
        }
    }

    // MARK: - Central pipeline (shared by watcher + button)

    private func process(asset: PHAsset) {
        guard isBusy == false else { return }
        isBusy = true
        lastErrorDescription = nil

        Task { [weak self] in
            guard let self else { return }
            defer { self.isBusy = false }

            do {
                // 1) Fetch original/adjusted image bytes (HEIC & iCloud safe)
                let data: Data = try await withCheckedThrowingContinuation { cont in
                    let opts = PHImageRequestOptions()
                    opts.isNetworkAccessAllowed = true
                    opts.deliveryMode = .highQualityFormat
                    opts.version = .current
                    PHImageManager.default().requestImageDataAndOrientation(for: asset, options: opts) { data, _, _, _ in
                        if let data { cont.resume(returning: data) }
                        else { cont.resume(throwing: SimpleError("Failed to load image data.")) }
                    }
                }

                // 2) Optional: keep a UI preview
                if let ui = UIImage(data: data) {
                    await MainActor.run { self.latestPreview = ui }
                }

                // 3) Decode → center-square 320×320 JPEG (your current spec)
                guard let src = CGImageSourceCreateWithData(data as CFData, nil),
                      let cg  = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
                    throw SimpleError("CGImage decode failed.")
                }
                let jpeg = try ROIEncoder.centerSquareJPEG(from: cg)
                self.lastJPEGBytes = jpeg.count
                self.lastCropSide  = 320

                // 4) POST to LAN server
                let prompt = "Return one short sentence (<=12 words) describing the central object."
                let caption = try await self.lanClient.caption(
                    jpeg: jpeg,
                    prompt: prompt,
                    timeoutMs: self.lanClient.firstByteDeadlineMs
                )

                // 5) UI + TTS
                let spoken = caption.isEmpty ? self.fallbackCaption : caption
                self.lastLANCaption = spoken
                self.speak(spoken)

                // cache
                self.cachedJPEG = jpeg
                self.cachedSide = 320

            } catch {
                self.lastErrorDescription = error.localizedDescription
                self.lastLANCaption = self.fallbackCaption
                self.speak(self.fallbackCaption)
            }
        }
    }

    // MARK: - Helper escalation (UI ornament panel)

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

    func callPierce(using opener: (URL) async -> Void) async {
        do {
            helperStatus = .dialing
            let urls = try ownerContact.prioritizedContactURLs()
            for url in urls {
                await opener(url)
                helperStatus = .dialed
                return
            }
            helperStatus = .dialFailed
            lastErrorDescription = "Could not start a call to Pierce."
        } catch {
            helperStatus = .dialFailed
            lastErrorDescription = error.localizedDescription
        }
    }

    // MARK: - TTS

    private func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text.isEmpty ? "Not sure." : text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate  = AVSpeechUtteranceDefaultSpeechRate
        ttsSynth.speak(utterance)
    }

    // MARK: - Status enums

    enum HelperStatus: Equatable {
        case idle
        case sending
        case sent
        case failed
        case dialing
        case dialed
        case dialFailed
        case simulatedAcknowledged(context: String)
    }

    // MARK: - Utility: preload latest or bundle

    private func latestPhotoOrBundleJPEG() async throws -> (Data, Int) {
        do {
            return try await fetchLatestPhotoJPEG()
        } catch {
            // Fallback to bundle for warmup
            guard let url = Bundle.main.url(forResource: "beer", withExtension: "jpg"),
                  let src = CGImageSourceCreateWithURL(url as CFURL, nil),
                  let cg  = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
                throw error
            }
            let jpeg = try ROIEncoder.centerSquareJPEG(from: cg)
            return (jpeg, 320)
        }
    }

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

        // 3) Get bytes
        let data: Data = try await withCheckedThrowingContinuation { cont in
            let opts = PHImageRequestOptions()
            opts.isNetworkAccessAllowed = true
            opts.deliveryMode = .highQualityFormat
            opts.version = .current
            PHImageManager.default().requestImageDataAndOrientation(for: asset, options: opts) { data, _, _, _ in
                if let data { cont.resume(returning: data) }
                else { cont.resume(throwing: SimpleError("Failed to load image data.")) }
            }
        }

        // 4) JPEG via ROIEncoder
        guard let src = CGImageSourceCreateWithData(data as CFData, nil),
              let cg  = CGImageSourceCreateImageAtIndex(src, 0, nil) else {
            throw SimpleError("CGImage decode failed.")
        }
        let jpeg = try ROIEncoder.centerSquareJPEG(from: cg)
        return (jpeg, 320)
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
