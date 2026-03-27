//
//  OutputFormat.swift
//  omni-converter
//

import UniformTypeIdentifiers

enum OutputFormat: String, CaseIterable, Identifiable {
    case png  = "public.png"
    case jpeg = "public.jpeg"
    case gif  = "com.compuserve.gif"
    case tiff = "public.tiff"
    case heic = "public.heic"
    case pdf  = "com.adobe.pdf"
    case bmp  = "com.microsoft.bmp"
    case webp = "org.webmproject.webp"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .png:  return "PNG"
        case .jpeg: return "JPEG"
        case .gif:  return "GIF"
        case .tiff: return "TIFF"
        case .heic: return "HEIC"
        case .pdf:  return "PDF"
        case .bmp:  return "BMP"
        case .webp: return "WEBP"
        }
    }

    var fileExtension: String {
        switch self {
        case .png:  return "png"
        case .jpeg: return "jpg"
        case .gif:  return "gif"
        case .tiff: return "tiff"
        case .heic: return "heic"
        case .pdf:  return "pdf"
        case .bmp:  return "bmp"
        case .webp: return "webp"
        }
    }

    var utType: UTType {
        switch self {
        case .png:  return .png
        case .jpeg: return .jpeg
        case .gif:  return .gif
        case .tiff: return .tiff
        case .heic: return .heic
        case .pdf:  return .pdf
        case .bmp:  return .bmp
        case .webp: return .webP
        }
    }

    var supportsQuality: Bool {
        self == .jpeg || self == .webp
    }
}
