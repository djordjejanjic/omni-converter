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
        outputDirectory: URL
    ) async throws -> URL {
        // Compute a unique output path so we never overwrite existing files
        let baseName = file.url.deletingPathExtension().lastPathComponent
        let outputURL = uniqueOutputURL(
            directory: outputDirectory,
            baseName: baseName,
            fileExtension: format.fileExtension
        )

        try writeConversion(file: file, to: format, quality: quality, outputURL: outputURL)
        return outputURL
    }

    static func convertToURL(
        file: ImageFile,
        to format: OutputFormat,
        quality: Double = 0.85,
        outputURL: URL
    ) async throws {
        try writeConversion(file: file, to: format, quality: quality, outputURL: outputURL)
    }

    /// Shared conversion logic — routes to PDF or raster pipeline.
    private static func writeConversion(
        file: ImageFile,
        to format: OutputFormat,
        quality: Double,
        outputURL: URL
    ) throws {
        if format == .pdf {
            try renderToPDF(sourceURL: file.url, outputURL: outputURL, filename: file.filename)
        } else {
            try renderToImage(
                sourceURL: file.url,
                outputURL: outputURL,
                format: format,
                quality: quality,
                filename: file.filename
            )
        }
    }

    static func convertBatch(
        files: [ImageFile],
        to format: OutputFormat,
        quality: Double = 0.85,
        outputDirectory: URL
    ) async -> [ConversionResult] {
        var results: [ConversionResult] = []

        for file in files {
            let result: Result<URL, ConversionError>
            do {
                let url = try await convert(
                    file: file,
                    to: format,
                    quality: quality,
                    outputDirectory: outputDirectory
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
        filename: String
    ) throws {
        guard let imageSource = CGImageSourceCreateWithURL(sourceURL as CFURL, nil) else {
            throw ConversionError.sourceCreationFailed(filename: filename)
        }

        guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw ConversionError.imageDecodeFailed(filename: filename)
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

        CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)

        guard CGImageDestinationFinalize(destination) else {
            throw ConversionError.encodingFailed(filename: filename)
        }
    }

    /// Special path for PDF output.
    private static func renderToPDF(
        sourceURL: URL,
        outputURL: URL,
        filename: String
    ) throws {
        guard let image = NSImage(contentsOf: sourceURL) else {
            throw ConversionError.imageDecodeFailed(filename: filename)
        }

        guard let rep = image.representations.first else {
            throw ConversionError.imageDecodeFailed(filename: filename)
        }
        let width = rep.pixelsWide > 0 ? rep.pixelsWide : Int(image.size.width)
        let height = rep.pixelsHigh > 0 ? rep.pixelsHigh : Int(image.size.height)

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
