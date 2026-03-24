//
//  ContentView.swift
//  omni-converter
//

import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var files: [ImageFile] = []
    @State private var selectedFormat: OutputFormat = .png
    @State private var quality: Double = 0.85

    @State private var resizeWidth: String = ""
    @State private var resizeHeight: String = ""
    @State private var lockAspectRatio: Bool = true
    @State private var applyResizeToAll: Bool = false
    @State private var mergeAllToPDF: Bool = false

    @State private var isConverting: Bool = false
    @State private var conversionResults: [ConversionResult] = []
    @State private var showResults: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            DropZone(onFilesAdded: addFiles)
                .disabled(isConverting)

            FileList(files: $files)
                .disabled(isConverting)

            FormatPicker(
                selectedFormat: $selectedFormat,
                quality: $quality
            )
            .disabled(isConverting)

            if !files.isEmpty {
                ConversionOptions(
                    width: $resizeWidth,
                    height: $resizeHeight,
                    lockAspectRatio: $lockAspectRatio,
                    applyResizeToAll: $applyResizeToAll,
                    mergeAllToPDF: $mergeAllToPDF,
                    originalWidth: files.first?.pixelWidth ?? 0,
                    originalHeight: files.first?.pixelHeight ?? 0,
                    isBatch: files.count > 1,
                    showMergePDF: files.count > 1 && selectedFormat == .pdf
                )
                .disabled(isConverting)
            }

            Divider()
                .padding(.bottom, 4)

            if isConverting {
                HStack(spacing: 12) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Converting...")
                        .foregroundColor(.secondary)
                }
            } else {
                Button("Convert") {
                    startConversion()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(files.isEmpty)
            }
        }
        .padding(24)
        .frame(minWidth: 480, minHeight: 400)
        .alert("Conversion Complete", isPresented: $showResults) {
            Button("OK") {
                conversionResults.removeAll()
                files.removeAll()
                resizeWidth = ""
                resizeHeight = ""
                applyResizeToAll = false
                mergeAllToPDF = false
            }
        } message: {
            Text(resultsSummary)
        }
    }

    private func addFiles(urls: [URL]) {
        let newFiles = urls
            .filter { url in !files.contains(where: { $0.url == url }) }
            .map { ImageFile(url: $0) }
        files.append(contentsOf: newFiles)

        // Populate resize fields with first file's dimensions
        if let first = files.first, resizeWidth.isEmpty {
            resizeWidth = String(first.pixelWidth)
            resizeHeight = String(first.pixelHeight)
        }
    }

    private var targetSize: CGSize? {
        if files.count > 1 && !applyResizeToAll {
            return nil
        }
        guard let w = Int(resizeWidth), let h = Int(resizeHeight), w > 0, h > 0 else {
            return nil
        }
        if let first = files.first, files.count == 1,
           w == first.pixelWidth && h == first.pixelHeight {
            return nil
        }
        return CGSize(width: w, height: h)
    }

    private func startConversion() {
        if files.count == 1 {
            convertSingleFile()
        } else {
            convertBatchFiles()
        }
    }

    private func convertSingleFile() {
        let file = files[0]

        let panel = NSSavePanel()
        let baseName = file.url.deletingPathExtension().lastPathComponent
        // Suggest a filename with the new extension
        panel.nameFieldStringValue = "\(baseName).\(selectedFormat.fileExtension)"
        panel.allowedContentTypes = [selectedFormat.utType]
        panel.title = "Save Converted Image"

        guard panel.runModal() == .OK, let saveURL = panel.url else { return }

        Task {
            isConverting = true

            let result: Result<URL, ConversionError>
            do {
                try await ImageConverter.convertToURL(
                    file: file,
                    to: selectedFormat,
                    quality: quality,
                    outputURL: saveURL,
                    targetSize: targetSize
                )
                result = .success(saveURL)
            } catch let error as ConversionError {
                result = .failure(error)
            } catch {
                result = .failure(.encodingFailed(filename: file.filename))
            }

            conversionResults = [ConversionResult(
                id: file.id,
                sourceFile: file,
                result: result
            )]

            isConverting = false
            showResults = true
        }
    }

    private func convertBatchFiles() {
        if selectedFormat == .pdf && mergeAllToPDF {
            convertMergedPDF()
            return
        }

        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.title = "Choose Output Folder"
        panel.message = "Converted images will be saved here"
        panel.prompt = "Choose"

        guard panel.runModal() == .OK, let directory = panel.url else { return }

        Task {
            isConverting = true

            conversionResults = await ImageConverter.convertBatch(
                files: files,
                to: selectedFormat,
                quality: quality,
                outputDirectory: directory,
                targetSize: targetSize
            )

            isConverting = false
            showResults = true
        }
    }

    private func convertMergedPDF() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "merged.pdf"
        panel.allowedContentTypes = [.pdf]
        panel.title = "Save Merged PDF"

        guard panel.runModal() == .OK, let saveURL = panel.url else { return }

        Task {
            isConverting = true

            let result: Result<URL, ConversionError>
            do {
                try await ImageConverter.renderMultipleToPDF(
                    files: files,
                    outputURL: saveURL,
                    targetSize: targetSize
                )
                result = .success(saveURL)
            } catch let error as ConversionError {
                result = .failure(error)
            } catch {
                result = .failure(.pdfRenderFailed(filename: "merged.pdf"))
            }

            conversionResults = [ConversionResult(
                id: files.first!.id,
                sourceFile: files.first!,
                result: result
            )]

            isConverting = false
            showResults = true
        }
    }

    private var resultsSummary: String {
        let successes = conversionResults.filter {
            if case .success = $0.result { return true }
            return false
        }
        let failures = conversionResults.filter {
            if case .failure = $0.result { return true }
            return false
        }

        var message = "\(successes.count) of \(conversionResults.count) files converted successfully."

        if !failures.isEmpty {
            message += "\n\nFailed:"
            for failure in failures {
                if case .failure(let error) = failure.result {
                    message += "\n• \(failure.sourceFile.filename): \(error.localizedDescription)"
                }
            }
        }

        return message
    }
}

#Preview {
    ContentView()
}
