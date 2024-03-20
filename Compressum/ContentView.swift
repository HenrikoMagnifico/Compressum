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
    @Environment(\.colorScheme) var colorScheme
    @State private var inputFilePath: String = ""
    @State private var outputDirectoryPath: String = ""
    @State private var selectedFormatIndex = 0
    @State private var isFastCompressionEnabled = false
    @State private var droppedFileURL: URL?
    @State private var isCompressing = false // Track compression state
    @State private var compressionProgress: Double = 0.0 // Track compression progress

    let exportFormats = ["MP4", "MOV", "AVI", "MKV", "FLV", "WEBM", "MPEG", "WMV"] // Add more export formats if needed

    var body: some View {
        ZStack {
            BlurView(material: colorScheme == .dark ? .dark : .light)
                .edgesIgnoringSafeArea(.all)

            VStack {
                HStack {
                    Button(LocalizedStringKey("select_input_file")) {
                        withAnimation {
                            inputFilePath = selectFile()
                        }
                    }
                    .padding()


                    TextField(LocalizedStringKey("input_file_path"), text: $inputFilePath)
                        .textFieldStyle(RoundedBorderTextFieldStyle()) // Add rounded border style for text field
                        .padding()
                }

                HStack {
                    Button(LocalizedStringKey("select_output_directory")) {
                        withAnimation {
                            outputDirectoryPath = selectDirectory()
                        }
                    }
                    .padding()

                    TextField(LocalizedStringKey("output_file_path"), text: $outputDirectoryPath)
                        .textFieldStyle(RoundedBorderTextFieldStyle()) // Add rounded border style for text field
                        .padding()
                }

                Picker(selection: $selectedFormatIndex, label: Text(LocalizedStringKey("export_format"))) {
                    ForEach(Array(0 ..< exportFormats.count), id: \.self) { index in
                        Text(self.exportFormats[index])
                    }
                }
                .pickerStyle(SegmentedPickerStyle()) // Use segmented picker style for better appearance
                .padding()

                Toggle(isOn: $isFastCompressionEnabled, label: {
                    Text(LocalizedStringKey("fast_compression"))
                })
                .padding()

                Button(action: {
                    compressFile()
                }) {
                    if isCompressing {
                        ProgressView(value: compressionProgress, total: 1.0) // Show progress bar during compression
                            .padding()
                    } else {
                        Text(LocalizedStringKey("compress_video"))
                            .padding()
                    }
                }
                .disabled(isCompressing) // Disable button during compression
                .buttonStyle(DefaultButtonStyle()) // Use default button style

            }
            .padding()
        }
        .onDrop(of: [.fileURL], delegate: FileDropDelegate(droppedFileURL: $droppedFileURL, outputDirectoryPath: $outputDirectoryPath))
        .onChange(of: droppedFileURL) { newValue in
            if let droppedURL = newValue {
                withAnimation {
                    inputFilePath = droppedURL.path
                }
            }
        }
        .preferredColorScheme(colorScheme) // Set preferred color scheme based on system setting
        .navigationTitle("Compressum")
    }

    func selectFile() -> String {
        let dialog = NSOpenPanel()
        dialog.title = "Choose a video file"
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
        let selectedSpeed = isFastCompressionEnabled ? "ultrafast" : "fast" // Use veryfast if fast compression is enabled, otherwise veryslow
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
        
        // Construct the ffmpeg command with progress and nostats options
        let command = "\(ffmpegPath) -i \"\(inputURL.path)\" -preset \(selectedSpeed) \"\(outputFilePath)\""

        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", command]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        let outputHandle = pipe.fileHandleForReading

        outputHandle.readabilityHandler = { pipe in
            if let line = String(data: pipe.availableData, encoding: .utf8) {
                DispatchQueue.main.async {
                    // Parse the output to extract progress information
                    if line.contains("Duration:") {
                        // Extract the duration from the line
                        if let durationRange = line.range(of: "Duration: (\\d{2}):(\\d{2}):(\\d{2})\\.(\\d+)") {
                            let durationString = line[durationRange]
                            // Convert duration to seconds or use it as needed
                            print("Duration:", durationString)
                        }
                    } else if line.contains("time=") {
                        // Extract the progress from the line
                        if let progressRange = line.range(of: "time=(\\d{2}):(\\d{2}):(\\d{2})\\.(\\d+)") {
                            let progressString = line[progressRange]
                            // Convert progress to seconds or use it as needed
                            print("Progress:", progressString)
                        }
                    } else {
                        // Handle other output as needed
                        print("Other Output:", line)
                    }
                }
            }
        }

        task.launch()
        task.waitUntilExit()

        if task.terminationStatus == 0 {
            print("Compression successful")
        } else {
            print("Compression failed")
        }
    }


    func executeCommand(_ command: String) {
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", command]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        let outputHandle = pipe.fileHandleForReading

        outputHandle.readabilityHandler = { pipe in
            if let line = String(data: pipe.availableData, encoding: .utf8) {
                DispatchQueue.main.async {
                    // Parse the output to extract progress information
                    if line.contains("Duration:") {
                        // Extract the duration from the line
                        if let durationRange = line.range(of: "Duration: (\\d{2}):(\\d{2}):(\\d{2})\\.(\\d+)") {
                            let durationString = line[durationRange]
                            // Convert duration to seconds or use it as needed
                            print("Duration:", durationString)
                        }
                    } else if line.contains("time=") {
                        // Extract the progress from the line
                        if let progressRange = line.range(of: "time=(\\d{2}):(\\d{2}):(\\d{2})\\.(\\d+)") {
                            let progressString = line[progressRange]
                            // Convert progress to seconds or use it as needed
                            print("Progress:", progressString)
                        }
                    } else {
                        // Handle other output as needed
                        print("Other Output:", line)
                    }
                }
            }
        }

        task.launch()
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
