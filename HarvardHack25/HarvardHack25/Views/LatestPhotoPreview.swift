import SwiftUI
import Photos
import PhotosUI

struct LatestPhotoPreview: View {
    @State private var thumbnail: UIImage?
    @State private var status: String = "Idle"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Latest Photo")
                .font(.subheadline.weight(.semibold))

            ZStack {
                if let ui = thumbnail {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(.white.opacity(0.15), lineWidth: 1)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.white.opacity(0.06))
                        .overlay(Text("No preview").foregroundStyle(.secondary))
                        .frame(height: 140)
                }
            }

            HStack {
                Button("Refresh") { fetchLatestThumbnail() }
                    .buttonStyle(.bordered)

                Button("Open Photos") {
                    // Just a hint for users: open Photos app manually.
                    status = "Open the Photos app to take/select a picture."
                }
                .buttonStyle(.bordered)
            }

            Text(status)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .onAppear { ensureAuthThenFetch() }
    }

    // MARK: - Permissions + fetch
    private func ensureAuthThenFetch() {
        let cur = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if cur == .authorized || cur == .limited {
            fetchLatestThumbnail()
            return
        }
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
            DispatchQueue.main.async {
                if newStatus == .authorized || newStatus == .limited {
                    self.fetchLatestThumbnail()
                } else {
                    self.status = "Photos access denied."
                }
            }
        }
    }

    private func latestImageAsset() -> PHAsset? {
        let opts = PHFetchOptions()
        opts.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        opts.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        opts.fetchLimit = 1
        let result = PHAsset.fetchAssets(with: opts)
        return result.firstObject
    }

    private func fetchLatestThumbnail() {
        status = "Loading…"
        guard let asset = latestImageAsset() else {
            status = "No photos found."
            thumbnail = nil
            return
        }

        let target = CGSize(width: 600, height: 600)
        let opts = PHImageRequestOptions()
        opts.deliveryMode = .fastFormat
        opts.resizeMode = .fast
        opts.isSynchronous = false
        opts.isNetworkAccessAllowed = true // iCloud

        PHImageManager.default().requestImage(for: asset,
                                              targetSize: target,
                                              contentMode: .aspectFit,
                                              options: opts) { image, _ in
            DispatchQueue.main.async {
                self.thumbnail = image
                self.status = image == nil ? "Preview failed." : "Preview ready."
            }
        }
    }
}

