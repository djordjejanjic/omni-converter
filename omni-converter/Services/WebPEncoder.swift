import CoreGraphics
import Foundation

enum WebPEncoder {

    enum WebPError: Error, LocalizedError {
        case cannotCreateColorSpace
        case cannotCreateContext
        case cannotRenderPixels
        case encodingFailed

        var errorDescription: String? {
            switch self {
            case .cannotCreateColorSpace:
                return "Could not create sRGB color space for WebP encoding."
            case .cannotCreateContext:
                return "Could not create bitmap context for WebP encoding."
            case .cannotRenderPixels:
                return "Could not render pixel data for WebP encoding."
            case .encodingFailed:
                return "libwebp failed to encode the image."
            }
        }
    }

    static func encode(_ image: CGImage, quality: Float) throws -> Data {
        let width = image.width
        let height = image.height
        let stride = width * 4

        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
            throw WebPError.cannotCreateColorSpace
        }

        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: stride,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            throw WebPError.cannotCreateContext
        }

        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let pixelData = context.data else {
            throw WebPError.cannotRenderPixels
        }

        let rgba = pixelData.assumingMemoryBound(to: UInt8.self)

        unpremultiplyAlpha(rgba, pixelCount: width * height)

        var output: UnsafeMutablePointer<UInt8>?
        let size = WebPEncodeRGBA(
            rgba,
            Int32(width),
            Int32(height),
            Int32(stride),
            quality,
            &output
        )

        guard size > 0, let outputPtr = output else {
            throw WebPError.encodingFailed
        }

        let data = Data(bytes: outputPtr, count: size)
        WebPFree(outputPtr)
        return data
    }

    private static func unpremultiplyAlpha(_ pixels: UnsafeMutablePointer<UInt8>, pixelCount: Int) {
        for i in 0..<pixelCount {
            let offset = i * 4
            let a = UInt16(pixels[offset + 3])
            guard a > 0, a < 255 else { continue }
            pixels[offset + 0] = UInt8(min(UInt16(pixels[offset + 0]) * 255 / a, 255))
            pixels[offset + 1] = UInt8(min(UInt16(pixels[offset + 1]) * 255 / a, 255))
            pixels[offset + 2] = UInt8(min(UInt16(pixels[offset + 2]) * 255 / a, 255))
        }
    }
}
