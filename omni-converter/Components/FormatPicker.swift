//
//  FormatPicker.swift
//  omni-converter
//

import SwiftUI

struct FormatPicker: View {
    @Binding var selectedFormat: OutputFormat
    @Binding var quality: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Convert to:")
                Picker("Format", selection: $selectedFormat) {
                    ForEach(OutputFormat.allCases) { format in
                        Text(format.displayName).tag(format)
                    }
                }
                .labelsHidden()
                .frame(width: 120)
            }

            if selectedFormat.supportsQuality {
                HStack {
                    Text("Quality:")
                    Slider(value: $quality, in: 0...1, step: 0.01)
                    Text("\(Int(quality * 100))%")
                        .frame(width: 40, alignment: .trailing)
                        .monospacedDigit()
                }
            }
        }
    }
}
