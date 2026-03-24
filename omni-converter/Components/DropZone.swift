//
//  DropZone.swift
//  omni-converter
//

import SwiftUI
import UniformTypeIdentifiers

struct DropZone: View {
    var onFilesAdded: ([URL]) -> Void

    @State private var isTargeted: Bool = false

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.down.doc")
                .font(.system(size: 36))
                .foregroundColor(isTargeted ? .accentColor : .secondary)

            Text("Drop images here")
                .font(.headline)

            Text("or click to browse")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 160)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isTargeted ? Color.accentColor.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isTargeted ? Color.accentColor : Color.gray.opacity(0.4),
                    style: StrokeStyle(lineWidth: 2, dash: [8])
                )
        )
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers: providers)
        }
        .onTapGesture {
            openFilePicker()
        }
        .animation(.easeInOut(duration: 0.2), value: isTargeted)
    }

    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [.image]
        panel.message = "Select images to convert"

        if panel.runModal() == .OK {
            onFilesAdded(panel.urls)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        Task {
            var urls: [URL] = []

            for provider in providers {
                if let data = try? await provider.loadItem(
                    forTypeIdentifier: UTType.fileURL.identifier
                ) {
                    if let urlData = data as? Data,
                       let path = String(data: urlData, encoding: .utf8),
                       let url = URL(string: path) {
                        // Only accept image files
                        if let type = UTType(filenameExtension: url.pathExtension),
                           type.conforms(to: .image) {
                            urls.append(url)
                        }
                    }
                }
            }

            if !urls.isEmpty {
                await MainActor.run {
                    onFilesAdded(urls)
                }
            }
        }

        return true
    }
}
