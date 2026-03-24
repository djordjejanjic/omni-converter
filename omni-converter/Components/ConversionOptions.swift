//
//  ConversionOptions.swift
//  omni-converter
//

import SwiftUI

struct ConversionOptions: View {
    @Binding var width: String
    @Binding var height: String
    @Binding var lockAspectRatio: Bool
    @Binding var applyResizeToAll: Bool
    @Binding var mergeAllToPDF: Bool

    let originalWidth: Int
    let originalHeight: Int
    let isBatch: Bool
    let showMergePDF: Bool

    @FocusState private var focusedField: Field?

    private enum Field {
        case width, height
    }

    private var aspectRatio: Double {
        guard originalWidth > 0 && originalHeight > 0 else { return 1.0 }
        return Double(originalWidth) / Double(originalHeight)
    }

    private var fieldsDisabled: Bool {
        isBatch && !applyResizeToAll
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Resize")
                    .fontWeight(.medium)

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Text("W:")
                        TextField("Width", text: $width)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                            .monospacedDigit()
                            .focused($focusedField, equals: .width)
                            .onSubmit { applyAspectRatio(changedField: .width) }
                    }

                    HStack(spacing: 4) {
                        Text("H:")
                        TextField("Height", text: $height)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                            .monospacedDigit()
                            .focused($focusedField, equals: .height)
                            .onSubmit { applyAspectRatio(changedField: .height) }
                    }

                    Text("px")
                        .foregroundColor(.secondary)
                }
                .disabled(fieldsDisabled)
                .opacity(fieldsDisabled ? 0.5 : 1.0)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                if isBatch {
                    Toggle("Apply resize to all", isOn: $applyResizeToAll)
                        .toggleStyle(.checkbox)
                }

                Toggle("Lock aspect ratio", isOn: $lockAspectRatio)
                    .toggleStyle(.checkbox)
                    .disabled(fieldsDisabled)
                    .opacity(fieldsDisabled ? 0.5 : 1.0)

                if showMergePDF {
                    Toggle("Merge images to PDF", isOn: $mergeAllToPDF)
                        .toggleStyle(.checkbox)
                }
            }
        }
        .onChange(of: focusedField) { oldValue, _ in
            if let old = oldValue {
                applyAspectRatio(changedField: old)
            }
        }
    }

    private func applyAspectRatio(changedField: Field) {
        guard lockAspectRatio else { return }

        switch changedField {
        case .width:
            if let w = Int(width), w > 0 {
                let newHeight = Int(round(Double(w) / aspectRatio))
                height = String(newHeight)
            }
        case .height:
            if let h = Int(height), h > 0 {
                let newWidth = Int(round(Double(h) * aspectRatio))
                width = String(newWidth)
            }
        }
    }
}
