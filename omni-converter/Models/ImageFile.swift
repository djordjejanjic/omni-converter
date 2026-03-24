//
//  ImageFile.swift
//  omni-converter
//

import AppKit
import CoreGraphics
import Foundation
import ImageIO

struct ImageFile: Identifiable {
    let id: UUID
    let url: URL
    let filename: String
    let fileSize: Int64
    let pixelWidth: Int
    let pixelHeight: Int
    var thumbnail: NSImage?

    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }

    init(url: URL) {
        self.id = UUID()
        self.url = url
        self.filename = url.lastPathComponent

        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        self.fileSize = attributes?[.size] as? Int64 ?? 0

        // Read pixel dimensions from image source
        if let source = CGImageSourceCreateWithURL(url as CFURL, nil),
           let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
           let w = properties[kCGImagePropertyPixelWidth] as? Int,
           let h = properties[kCGImagePropertyPixelHeight] as? Int {
            self.pixelWidth = w
            self.pixelHeight = h
        } else {
            self.pixelWidth = 0
            self.pixelHeight = 0
        }

        self.thumbnail = nil
    }

    init(id: UUID = UUID(), url: URL, filename: String, fileSize: Int64, pixelWidth: Int = 0, pixelHeight: Int = 0, thumbnail: NSImage? = nil) {
        self.id = id
        self.url = url
        self.filename = filename
        self.fileSize = fileSize
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
        self.thumbnail = thumbnail
    }
}
