import SwiftUI
import Photos
import PhotosUI

struct LatestPhotoPreview: View {
    @State private var image: UIImage?
    @State private var status: String = "Tap to load the latest photo."

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Latest Photo")
                .font(.subheadline.weight(.semibold))

            ZStack {
                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 240)
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

            Button {
                loadMostRecentPhoto()
            } label: {
                Label("Show Latest Photo", systemImage: "photo.on.rectangle")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            Text(status)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Button action

    private func loadMostRecentPhoto() {
        let auth = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch auth {
        case .authorized, .limited:
            fetchLatest()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        self.fetchLatest()
                    } else {
                        self.status = "Photos access denied."
                    }
                }
            }
        default:
            status = "Photos access denied in Settings."
        }
    }

    // MARK: - Fetch logic

    private func fetchLatest() {
        status = "Loading…"

        guard let asset = mostRecentImageAsset() else {
            self.image = nil
            self.status = "No photos found."
            return
        }

        // Prefer original data (most reliable in Simulator)
        let dataOpts = PHImageRequestOptions()
        dataOpts.isNetworkAccessAllowed = true
        dataOpts.deliveryMode = .highQualityFormat
        dataOpts.version = .current
        dataOpts.isSynchronous = false

        PHImageManager.default().requestImageDataAndOrientation(for: asset, options: dataOpts) { data, _, _, _ in
            if let data, let ui = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.image = ui
                    self.status = "Preview ready."
                }
                return
            }

            // Fallback: rendered image
            let targetSize = CGSize(width: max(asset.pixelWidth, 800),
                                    height: max(asset.pixelHeight, 800))
            let imgOpts = PHImageRequestOptions()
            imgOpts.isNetworkAccessAllowed = true
            imgOpts.deliveryMode = .highQualityFormat
            imgOpts.resizeMode = .none

            PHImageManager.default().requestImage(for: asset,
                                                  targetSize: targetSize,
                                                  contentMode: .aspectFit,
                                                  options: imgOpts) { img, _ in
                DispatchQueue.main.async {
                    if let img {
                        self.image = img
                        self.status = "Preview ready."
                    } else {
                        self.image = nil
                        self.status = "Preview failed."
                    }
                }
            }
        }
    }

    private func mostRecentImageAsset() -> PHAsset? {
        let opts = PHFetchOptions()
        opts.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        opts.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        opts.fetchLimit = 1
        return PHAsset.fetchAssets(with: opts).firstObject
    }
}

