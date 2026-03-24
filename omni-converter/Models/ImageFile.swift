//
//  ImageFile.swift
//  omni-converter
//

import AppKit
import Foundation

struct ImageFile: Identifiable {
    let id: UUID
    let url: URL
    let filename: String
    let fileSize: Int64
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

        self.thumbnail = nil
    }

    init(id: UUID = UUID(), url: URL, filename: String, fileSize: Int64, thumbnail: NSImage? = nil) {
        self.id = id
        self.url = url
        self.filename = filename
        self.fileSize = fileSize
        self.thumbnail = thumbnail
    }
}
