import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

enum ROIEncoder {
    static func centerSquareJPEG(from cg: CGImage) throws -> Data {
        // Hardcoded: 320×320 output @ ~0.65 quality
        let side = 320
        let quality: CGFloat = 0.65

        let w = cg.width, h = cg.height
        let cropSide = min(w, h)
        let x = (w - cropSide) / 2
        let y = (h - cropSide) / 2
        guard let cropped = cg.cropping(to: CGRect(x: x, y: y, width: cropSide, height: cropSide)) else {
            throw AppError.serviceFailure(underlying: NSError(domain: "ROI", code: 1))
        }

        let cs = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(data: nil,
                                  width: side, height: side,
                                  bitsPerComponent: 8,
                                  bytesPerRow: side * 4,
                                  space: cs,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { throw AppError.serviceFailure(underlying: NSError(domain: "ROI", code: 2)) }

        ctx.interpolationQuality = .high
        ctx.draw(cropped, in: CGRect(x: 0, y: 0, width: side, height: side))
        guard let scaled = ctx.makeImage() else {
            throw AppError.serviceFailure(underlying: NSError(domain: "ROI", code: 3))
        }

        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil) else {
            throw AppError.serviceFailure(underlying: NSError(domain: "ROI", code: 4))
        }
        CGImageDestinationAddImage(dest, scaled, [kCGImageDestinationLossyCompressionQuality: quality] as CFDictionary)
        guard CGImageDestinationFinalize(dest) else {
            throw AppError.serviceFailure(underlying: NSError(domain: "ROI", code: 5))
        }
        return data as Data
    }
}
