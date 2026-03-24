//
//  FileList.swift
//  omni-converter
//

import SwiftUI

struct FileList: View {
    @Binding var files: [ImageFile]

    var body: some View {
        if !files.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Files")
                        .font(.headline)
                    Spacer()
                    Button("Clear all") {
                        files.removeAll()
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .font(.caption)
                }
                .padding(.bottom, 8)

                Divider()

                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(files) { file in
                            FileRow(file: file) {
                                files.removeAll { $0.id == file.id }
                            }
                            Divider()
                        }
                    }
                }
                .frame(maxHeight: 160)
            }
        }
    }
}

struct FileRow: View {
    let file: ImageFile
    var onRemove: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "doc")
                .foregroundColor(.secondary)

            Text(file.filename)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            Text(file.formattedFileSize)
                .foregroundColor(.secondary)
                .font(.caption)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
    }
}
