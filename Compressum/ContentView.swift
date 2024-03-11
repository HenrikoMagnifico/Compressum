//
//  ContentView.swift
//  Compressum
//
//  Created by Henrik Öberg on 2024-03-11.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var inputFilePath: String = ""
    @State private var outputDirectoryPath: String = ""
    @State private var selectedFormatIndex = 0
    @State private var isFastCompressionEnabled = false
    @State private var droppedFileURL: URL?

    let exportFormats = ["MP4", "MOV", "AVI", "MKV", "FLV", "WEBM", "MPEG", "WMV"] // Add more export formats if needed

    var body: some View {
        VStack {
            HStack {
                Button("Select Input File") {
                    inputFilePath = selectFile()
                }
                .padding()

                TextField("Input File Path", text: $inputFilePath)
                    .padding()
            }

            HStack {
                Button("Select Output Directory") {
                    outputDirectoryPath = selectDirectory()
                }
                .padding()

                TextField("Output Directory Path", text: $outputDirectoryPath)
                    .padding()
            }

            Picker(selection: $selectedFormatIndex, label: Text("Export Format")) {
                ForEach(Array(0 ..< exportFormats.count), id: \.self) { index in
                    Text(self.exportFormats[index])
                }
            }
            .padding()

            Toggle(isOn: $isFastCompressionEnabled, label: {
                Text("Fast Compression")
            })
            .padding()

            Button("Compress") {
                compressVideo()
            }
            .padding()
        }
        .padding()
        .background(Color.gray.opacity(0.1)) // Add background color to the stack
        .onDrop(of: [.fileURL], delegate: FileDropDelegate(droppedFileURL: $droppedFileURL))
        .onChange(of: droppedFileURL) { newValue in
            if let droppedURL = newValue {
                inputFilePath = droppedURL.path
            }
        }
    }

    func selectFile() -> String {
        let dialog = NSOpenPanel()
        dialog.title = "Choose a file"
        dialog.showsResizeIndicator = true
        dialog.showsHiddenFiles = false
        dialog.canChooseDirectories = false
        dialog.allowedContentTypes = [UTType.movie, UTType.mpeg4Movie]

        if dialog.runModal() == NSApplication.ModalResponse.OK {
            if let result = dialog.url {
                return result.path
            }
        }
        return ""
    }

    func selectDirectory() -> String {
        let dialog = NSOpenPanel()
        dialog.title = "Choose a directory"
        dialog.showsResizeIndicator = true
        dialog.showsHiddenFiles = false
        dialog.canChooseDirectories = true
        dialog.canChooseFiles = false
        dialog.canCreateDirectories = true

        if dialog.runModal() == NSApplication.ModalResponse.OK {
            if let result = dialog.url {
                return result.path
            }
        }
        return ""
    }

    func compressVideo() {
        guard !inputFilePath.isEmpty && !outputDirectoryPath.isEmpty else {
            print("Input file path and output directory path must be specified.")
            return
        }

        let selectedFormat = exportFormats[selectedFormatIndex].lowercased()
        let selectedSpeed = isFastCompressionEnabled ? "veryfast" : "veryslow" // Use veryfast if fast compression is enabled, otherwise veryslow
        let ffmpegPath = Bundle.main.path(forResource: "ffmpeg", ofType: nil) ?? "/usr/local/bin/ffmpeg"
        let outputFilePath = "\(outputDirectoryPath)/output.\(selectedFormat)"
        let command = "\(ffmpegPath) -i \"\(inputFilePath)\" -preset \(selectedSpeed) \"\(outputFilePath)\""
        executeCommand(command)
    }

    func executeCommand(_ command: String) {
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", command]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        task.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            print(output)
        }

        task.waitUntilExit()

        if task.terminationStatus == 0 {
            print("Compression successful")
        } else {
            print("Compression failed")
        }
    }
}

struct FileDropDelegate: DropDelegate {
    @Binding var droppedFileURL: URL?

    func performDrop(info: DropInfo) -> Bool {
        guard let item = info.itemProviders(for: [.fileURL]).first else { return false }
        item.loadDataRepresentation(forTypeIdentifier: UTType.fileURL.identifier) { data, error in
            if let data = data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                DispatchQueue.main.async {
                    self.droppedFileURL = url
                }
            } else {
                print("Failed to load URL:", error?.localizedDescription ?? "Unknown error")
            }
        }
        return true
    }
}
