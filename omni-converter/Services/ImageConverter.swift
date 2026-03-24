//
//  ImageConverter.swift
//  omni-converter
//

import AppKit
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum ConversionError: Error, LocalizedError {
    case sourceCreationFailed(filename: String)
    case imageDecodeFailed(filename: String)
    case destinationCreationFailed(filename: String)
    case encodingFailed(filename: String)
    case pdfRenderFailed(filename: String)
    case outputDirectoryNotWritable(path: String)

    var errorDescription: String? {
        switch self {
        case .sourceCreationFailed(let f):
            return "Could not read '\(f)'. The file may be corrupt or in an unsupported format."
        case .imageDecodeFailed(let f):
            return "Could not decode image data from '\(f)'."
        case .destinationCreationFailed(let f):
            return "Could not create output file for '\(f)'."
        case .encodingFailed(let f):
            return "Failed to encode '\(f)' to the target format."
        case .pdfRenderFailed(let f):
            return "Failed to render '\(f)' as PDF."
        case .outputDirectoryNotWritable(let p):
            return "Cannot write to directory: \(p)"
        }
    }
}

struct ConversionResult: Identifiable {
    let id: UUID
    let sourceFile: ImageFile
    let result: Result<URL, ConversionError>
}

enum ImageConverter {

    /// Convert a single image file to the target format.
    ///
    /// - Parameters:
    ///   - file: The source image file.
    ///   - format: The desired output format.
    ///   - quality: Compression quality for lossy formats (0.0–1.0). Ignored for lossless.
    ///   - outputDirectory: Where to save the converted file.
    /// - Returns: The URL of the converted file on disk.
    static func convert(
        file: ImageFile,
        to format: OutputFormat,
        quality: Double = 0.85,
        outputDirectory: URL,
        targetSize: CGSize? = nil
    ) async throws -> URL {
        // Compute a unique output path so we never overwrite existing files
        let baseName = file.url.deletingPathExtension().lastPathComponent
        let outputURL = uniqueOutputURL(
            directory: outputDirectory,
            baseName: baseName,
            fileExtension: format.fileExtension
        )

        try writeConversion(file: file, to: format, quality: quality, outputURL: outputURL, targetSize: targetSize)
        return outputURL
    }

    static func convertToURL(
        file: ImageFile,
        to format: OutputFormat,
        quality: Double = 0.85,
        outputURL: URL,
        targetSize: CGSize? = nil
    ) async throws {
        try writeConversion(file: file, to: format, quality: quality, outputURL: outputURL, targetSize: targetSize)
    }

    /// Shared conversion logic — routes to PDF or raster pipeline.
    private static func writeConversion(
        file: ImageFile,
        to format: OutputFormat,
        quality: Double,
        outputURL: URL,
        targetSize: CGSize? = nil
    ) throws {
        if format == .pdf {
            try renderToPDF(sourceURL: file.url, outputURL: outputURL, filename: file.filename, targetSize: targetSize)
        } else {
            try renderToImage(
                sourceURL: file.url,
                outputURL: outputURL,
                format: format,
                quality: quality,
                filename: file.filename,
                targetSize: targetSize
            )
        }
    }

    static func convertBatch(
        files: [ImageFile],
        to format: OutputFormat,
        quality: Double = 0.85,
        outputDirectory: URL,
        targetSize: CGSize? = nil
    ) async -> [ConversionResult] {
        var results: [ConversionResult] = []

        for file in files {
            let result: Result<URL, ConversionError>
            do {
                let url = try await convert(
                    file: file,
                    to: format,
                    quality: quality,
                    outputDirectory: outputDirectory,
                    targetSize: targetSize
                )
                result = .success(url)
            } catch let error as ConversionError {
                result = .failure(error)
            } catch {
                result = .failure(.encodingFailed(filename: file.filename))
            }
            results.append(ConversionResult(
                id: file.id,
                sourceFile: file,
                result: result
            ))
        }

        return results
    }

    /// Core Graphics pipeline for raster formats (PNG, JPEG, WebP, GIF, TIFF, HEIC, BMP).
    ///
    /// The pipeline: file on disk → CGImageSource (decode) → CGImage (raw bitmap)
    ///             → CGImageDestination (encode) → file on disk
    private static func renderToImage(
        sourceURL: URL,
        outputURL: URL,
        format: OutputFormat,
        quality: Double,
        filename: String,
        targetSize: CGSize? = nil
    ) throws {
        guard let imageSource = CGImageSourceCreateWithURL(sourceURL as CFURL, nil) else {
            throw ConversionError.sourceCreationFailed(filename: filename)
        }

        guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw ConversionError.imageDecodeFailed(filename: filename)
        }

        let finalImage: CGImage
        if let size = targetSize,
           Int(size.width) != cgImage.width || Int(size.height) != cgImage.height {
            finalImage = try resizeImage(cgImage, to: size, filename: filename)
        } else {
            finalImage = cgImage
        }

        guard let destination = CGImageDestinationCreateWithURL(
            outputURL as CFURL,
            format.utType.identifier as CFString,
            1,
            nil
        ) else {
            throw ConversionError.destinationCreationFailed(filename: filename)
        }

        var properties: [CFString: Any] = [:]
        if format.supportsQuality {
            properties[kCGImageDestinationLossyCompressionQuality] = quality
        }

        CGImageDestinationAddImage(destination, finalImage, properties as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw ConversionError.encodingFailed(filename: filename)
        }
    }

    private static func resizeImage(_ image: CGImage, to size: CGSize, filename: String) throws -> CGImage {
        let width = Int(size.width)
        let height = Int(size.height)

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: image.bitsPerComponent,
            bytesPerRow: 0,
            space: image.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: image.bitmapInfo.rawValue
        ) else {
            throw ConversionError.encodingFailed(filename: filename)
        }

        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        guard let resized = context.makeImage() else {
            throw ConversionError.encodingFailed(filename: filename)
        }
        return resized
    }

    /// Special path for PDF output.
    private static func renderToPDF(
        sourceURL: URL,
        outputURL: URL,
        filename: String,
        targetSize: CGSize? = nil
    ) throws {
        guard let image = NSImage(contentsOf: sourceURL) else {
            throw ConversionError.imageDecodeFailed(filename: filename)
        }

        guard let rep = image.representations.first else {
            throw ConversionError.imageDecodeFailed(filename: filename)
        }
        let width: Int
        let height: Int
        if let size = targetSize {
            width = Int(size.width)
            height = Int(size.height)
        } else {
            width = rep.pixelsWide > 0 ? rep.pixelsWide : Int(image.size.width)
            height = rep.pixelsHigh > 0 ? rep.pixelsHigh : Int(image.size.height)
        }

        var mediaBox = CGRect(x: 0, y: 0, width: width, height: height)

        guard let pdfContext = CGContext(outputURL as CFURL, mediaBox: &mediaBox, nil) else {
            throw ConversionError.pdfRenderFailed(filename: filename)
        }

        pdfContext.beginPDFPage(nil)

        let nsContext = NSGraphicsContext(cgContext: pdfContext, flipped: false)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = nsContext
        image.draw(in: mediaBox)
        NSGraphicsContext.restoreGraphicsState()

        pdfContext.endPDFPage()
        pdfContext.closePDF()
    }

    static func renderMultipleToPDF(
        files: [ImageFile],
        outputURL: URL,
        targetSize: CGSize? = nil
    ) async throws {
        let a4Width: CGFloat = 595.28
        let a4Height: CGFloat = 841.89
        let maxContentWidth = a4Width * 0.9
        let maxContentHeight = a4Height * 0.9

        var pageBox = CGRect(x: 0, y: 0, width: a4Width, height: a4Height)

        guard let pdfContext = CGContext(outputURL as CFURL, mediaBox: &pageBox, nil) else {
            throw ConversionError.pdfRenderFailed(filename: outputURL.lastPathComponent)
        }

        for file in files {
            guard let image = NSImage(contentsOf: file.url) else {
                throw ConversionError.imageDecodeFailed(filename: file.filename)
            }

            guard let rep = image.representations.first else {
                throw ConversionError.imageDecodeFailed(filename: file.filename)
            }

            let imgWidth: CGFloat
            let imgHeight: CGFloat
            if let size = targetSize {
                imgWidth = size.width
                imgHeight = size.height
            } else {
                imgWidth = rep.pixelsWide > 0 ? CGFloat(rep.pixelsWide) : image.size.width
                imgHeight = rep.pixelsHigh > 0 ? CGFloat(rep.pixelsHigh) : image.size.height
            }

            let scaleX = maxContentWidth / imgWidth
            let scaleY = maxContentHeight / imgHeight
            let scale = min(scaleX, scaleY, 1.0)

            let drawWidth = imgWidth * scale
            let drawHeight = imgHeight * scale
            let drawX = (a4Width - drawWidth) / 2
            let drawY = (a4Height - drawHeight) / 2

            pdfContext.beginPDFPage(nil)

            let nsContext = NSGraphicsContext(cgContext: pdfContext, flipped: false)
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = nsContext
            image.draw(in: CGRect(x: drawX, y: drawY, width: drawWidth, height: drawHeight))
            NSGraphicsContext.restoreGraphicsState()

            pdfContext.endPDFPage()
        }

        pdfContext.closePDF()
    }

    private static func uniqueOutputURL(
        directory: URL,
        baseName: String,
        fileExtension: String
    ) -> URL {
        let candidate = directory.appendingPathComponent(baseName)
            .appendingPathExtension(fileExtension)
        if !FileManager.default.fileExists(atPath: candidate.path) {
            return candidate
        }

        let convertedName = "\(baseName)_converted"
        let candidate2 = directory.appendingPathComponent(convertedName)
            .appendingPathExtension(fileExtension)
        if !FileManager.default.fileExists(atPath: candidate2.path) {
            return candidate2
        }

        var counter = 2
        while true {
            let numberedName = "\(convertedName)_\(counter)"
            let numbered = directory.appendingPathComponent(numberedName)
                .appendingPathExtension(fileExtension)
            if !FileManager.default.fileExists(atPath: numbered.path) {
                return numbered
            }
            counter += 1
        }
    }
}
