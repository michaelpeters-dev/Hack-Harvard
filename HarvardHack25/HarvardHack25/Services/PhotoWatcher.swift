//
//  PhotoWatcher.swift
//  HarvardHack25
//
//  Observes the Photos library and notifies when a new image arrives.
//  This file does NOT do any processing/network/TTS. It only emits the newest PHAsset.
//

import Foundation
import Photos

final class PhotoWatcher: NSObject, PHPhotoLibraryChangeObserver {

    /// Called on main thread when a new image asset is available (inserted or on initial fire).
    var onNewAsset: ((PHAsset) -> Void)?

    /// Called on main thread for lightweight status (optional).
    var onStatus: ((String) -> Void)?

    /// Called on main thread for errors (permission, etc.).
    var onError: ((String) -> Void)?

    private var fetchResult: PHFetchResult<PHAsset>?
    private var debounceWork: DispatchWorkItem?

    func start(fireLatestImmediately: Bool = false) {
        ensureAuthThenBuildFetch(fireLatestImmediately: fireLatestImmediately)
        PHPhotoLibrary.shared().register(self)
    }

    func stop() {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
        fetchResult = nil
        debounceWork?.cancel()
    }

    // MARK: - Auth + initial fetch

    private func ensureAuthThenBuildFetch(fireLatestImmediately: Bool) {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            buildFetch(fireLatestImmediately: fireLatestImmediately)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] newStatus in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if newStatus == .authorized || newStatus == .limited {
                        self.buildFetch(fireLatestImmediately: fireLatestImmediately)
                    } else {
                        self.onError?("Photos access denied.")
                    }
                }
            }
        default:
            onError?("Photos access denied in Settings.")
        }
    }

    private func buildFetch(fireLatestImmediately: Bool) {
        let opts = PHFetchOptions()
        opts.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        opts.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        fetchResult = PHAsset.fetchAssets(with: opts)

        if fireLatestImmediately, let asset = fetchResult?.firstObject {
            onNewAsset?(asset) // process the current newest one once on startup
        }
    }

    // MARK: - PHPhotoLibraryChangeObserver

    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let fr = fetchResult,
              let details = changeInstance.changeDetails(for: fr) else { return }

        // update our snapshot
        fetchResult = details.fetchResultAfterChanges

        // if there are insertions, emit newest after a short debounce
        if let inserts = details.insertedIndexes, inserts.count > 0 {
            debounceWork?.cancel()
            let work = DispatchWorkItem { [weak self] in
                guard let self, let latest = self.fetchResult?.firstObject else { return }
                self.onNewAsset?(latest)
            }
            debounceWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: work)
        }
    }
}

