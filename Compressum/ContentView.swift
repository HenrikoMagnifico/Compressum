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
                Button(action: {
                    inputFilePath = selectFile()
                }) {
                    Text("Select Input File")
                        .padding()
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }

                TextField("Input File Path", text: $inputFilePath)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            HStack {
                Button(action: {
                    outputDirectoryPath = selectDirectory()
                }) {
                    Text("Select Output Directory")
                        .padding()
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }

                TextField("Output Directory Path", text: $outputDirectoryPath)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            Picker(selection: $selectedFormatIndex, label: Text("Export Format")) {
                ForEach(Array(0 ..< exportFormats.count), id: \.self) { index in
                    Text(self.exportFormats[index])
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            Toggle(isOn: $isFastCompressionEnabled, label: {
                Text("Fast Compression")
            })
            .padding()

            Button(action: {
                compressFile()
            }) {
                Text("Compress")
                    .padding()
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1)) // Add background color to the stack
        .onDrop(of: [.fileURL], delegate: FileDropDelegate(droppedFileURL: $droppedFileURL, outputDirectoryPath: $outputDirectoryPath))
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

    func compressFile() {
        print("Input file path:", inputFilePath)
        print("Dropped file URL:", droppedFileURL?.path ?? "None")
        print("Output directory path:", outputDirectoryPath)
        
        guard !inputFilePath.isEmpty else {
            print("Input file path must be specified.")
            return
        }

        let selectedFormat = exportFormats[selectedFormatIndex].lowercased()
        let selectedSpeed = isFastCompressionEnabled ? "veryfast" : "veryslow" // Use veryfast if fast compression is enabled, otherwise veryslow
        let ffmpegPath = Bundle.main.path(forResource: "ffmpeg", ofType: nil) ?? "/usr/local/bin/ffmpeg"
        
        let inputURL = droppedFileURL != nil ? droppedFileURL! : URL(fileURLWithPath: inputFilePath)
        let inputDirectoryURL = inputURL.deletingLastPathComponent()
        
        var outputDirectoryURL = inputDirectoryURL
        if !outputDirectoryPath.isEmpty {
            outputDirectoryURL = URL(fileURLWithPath: outputDirectoryPath)
        }
        print("Output directory path (before constructing output file path):", outputDirectoryURL.path)
        
        let inputFileName = inputURL.lastPathComponent
        let outputFileName = (inputFileName as NSString).deletingPathExtension + "_compressed." + selectedFormat
        let outputFilePath = outputDirectoryURL.appendingPathComponent(outputFileName).path
        print("Output file path:", outputFilePath)
        
        let command = "\(ffmpegPath) -i \"\(inputURL.path)\" -preset \(selectedSpeed) \"\(outputFilePath)\""
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
    @Binding var outputDirectoryPath: String

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
