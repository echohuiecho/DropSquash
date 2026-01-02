//
//  DropState.swift
//  DropSquash
//
//  Created by 0 on 2/1/2026.
//

import SwiftUI
import AppKit
import UniformTypeIdentifiers

class DropState: ObservableObject {
    @Published var isHovering = false
    @Published var isProcessing = false
    @Published var showSuccess = false
    @Published var statusText = "Drop files"

    private var totalFiles = 0
    private var processedFiles = 0
    private var successfulFiles = 0
    private var failedFiles = 0

    enum ImageFormat {
        case jpeg
        case png

        var fileExtension: String {
            switch self {
            case .jpeg: return "jpg"
            case .png: return "png"
            }
        }
    }

    func handleDrop(providers: [NSItemProvider]) {
        guard !providers.isEmpty else { return }

        totalFiles = providers.count
        processedFiles = 0
        successfulFiles = 0
        failedFiles = 0

        if totalFiles == 1 {
            // Single file - use existing flow
            processSingleFile(provider: providers[0])
        } else {
            // Multiple files - process sequentially
            processMultipleFiles(providers: providers)
        }
    }

    private func processSingleFile(provider: NSItemProvider) {
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { [weak self] (urlData, error) in
            DispatchQueue.main.async {
                guard let data = urlData as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }

                self?.processFile(url: url)
            }
        }
    }

    private func processMultipleFiles(providers: [NSItemProvider]) {
        isProcessing = true
        statusText = "Loading \(totalFiles) files..."

        // Load all file URLs first
        // Use a serial queue with user-initiated QoS to avoid thread safety issues and priority inversion
        let urlsQueue = DispatchQueue(label: "com.dropsquash.urls", qos: .userInitiated)
        var urls: [URL] = []
        let group = DispatchGroup()

        for provider in providers {
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (urlData, error) in
                // Immediately dispatch to user-initiated queue to avoid priority inversion
                // This ensures the callback work happens at user-initiated QoS level
                urlsQueue.async {
                    if let data = urlData as? Data,
                       let url = URL(dataRepresentation: data, relativeTo: nil) {
                        urls.append(url)
                    }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }

            // Get final urls array safely
            var finalUrls: [URL] = []
            urlsQueue.sync {
                finalUrls = urls
            }

            if finalUrls.isEmpty {
                self.statusText = "No files loaded"
                self.isProcessing = false
                return
            }

            self.totalFiles = finalUrls.count
            self.statusText = "Processing \(self.totalFiles) files..."

            // Process files sequentially to avoid overwhelming the system
            self.processURLsSequentially(urls: finalUrls, index: 0)
        }
    }

    private func processURLsSequentially(urls: [URL], index: Int) {
        guard index < urls.count else {
            // All files processed
            finishBatchProcessing()
            return
        }

        let url = urls[index]
        let fileExtension = url.pathExtension.lowercased()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            var success = false

            switch fileExtension {
            case "jpg", "jpeg", "png", "heic", "heif", "webp", "tiff", "tif", "bmp", "gif":
                (success, _) = self.processImage(url: url, fileExtension: fileExtension)

            case "pdf":
                (success, _) = self.compressPDF(url: url)

            case "mov", "mp4":
                (success, _) = self.compressVideo(url: url)

            default:
                (success, _) = self.copyToClipboard(url: url)
            }

            DispatchQueue.main.async {
                self.processedFiles += 1
                if success {
                    self.successfulFiles += 1
                } else {
                    self.failedFiles += 1
                }

                self.updateBatchStatus()

                // Process next file
                self.processURLsSequentially(urls: urls, index: index + 1)
            }
        }
    }

    private func updateBatchStatus() {
        if processedFiles < totalFiles {
            statusText = "\(processedFiles)/\(totalFiles) files"
        }
    }

    private func finishBatchProcessing() {
        isProcessing = false

        if successfulFiles == totalFiles {
            showSuccess = true
            statusText = "✓ \(successfulFiles) files done"
            // Play success sound
            NSSound.beep()
        } else if successfulFiles > 0 {
            showSuccess = true
            statusText = "✓ \(successfulFiles)/\(totalFiles) done"
            // Play success sound
            NSSound.beep()
        } else {
            showSuccess = false
            statusText = "All failed"
        }

        // Reset after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showSuccess = false
            self.statusText = "Drop files"
            self.totalFiles = 0
            self.processedFiles = 0
            self.successfulFiles = 0
            self.failedFiles = 0
        }
    }

    func processFile(url: URL) {
        isProcessing = true
        statusText = "Processing..."

        // Determine file type and process
        let fileExtension = url.pathExtension.lowercased()

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var success = false
            var message = ""

            switch fileExtension {
            case "jpg", "jpeg", "png", "heic", "heif", "webp", "tiff", "tif", "bmp", "gif":
                // Check if conversion is needed or just compress
                (success, message) = self?.processImage(url: url, fileExtension: fileExtension) ?? (false, "Failed")

            case "pdf":
                (success, message) = self?.compressPDF(url: url) ?? (false, "Failed")

            case "mov", "mp4":
                (success, message) = self?.compressVideo(url: url) ?? (false, "Failed")

            default:
                (success, message) = self?.copyToClipboard(url: url) ?? (false, "Failed")
            }

            DispatchQueue.main.async {
                self?.showResult(success: success, message: message)
            }
        }
    }

    func processImage(url: URL, fileExtension: String) -> (Bool, String) {
        // Determine target format based on source
        let targetFormat: ImageFormat
        switch fileExtension {
        case "heic", "heif":
            targetFormat = .jpeg  // Convert HEIC to JPEG
        case "png":
            targetFormat = .jpeg  // Convert PNG to JPEG (smaller)
        case "webp":
            targetFormat = .jpeg  // Convert WebP to JPEG
        case "tiff", "tif":
            targetFormat = .jpeg  // Convert TIFF to JPEG
        case "bmp":
            targetFormat = .png   // Convert BMP to PNG
        case "gif":
            targetFormat = .png   // Convert GIF to PNG (first frame)
        case "jpg", "jpeg":
            // Already JPEG, just compress
            return compressImage(url: url, targetFormat: .jpeg)
        default:
            targetFormat = .jpeg
        }

        return convertImage(url: url, targetFormat: targetFormat)
    }

    func convertImage(url: URL, targetFormat: ImageFormat) -> (Bool, String) {
        guard let image = NSImage(contentsOf: url) else {
            return (false, "Invalid image")
        }

        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return (false, "Image processing failed")
        }

        let originalSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0
        var imageData: Data?
        var newSize = 0

        switch targetFormat {
        case .jpeg:
            // Convert to JPEG with 85% quality (good balance)
            imageData = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.85])
        case .png:
            // Convert to PNG
            imageData = bitmap.representation(using: .png, properties: [:])
        }

        guard let data = imageData else {
            return (false, "Conversion failed")
        }

        newSize = data.count

        // Save next to original file
        let filename = url.deletingPathExtension().lastPathComponent + "_converted." + targetFormat.fileExtension
        let outputURL = url.deletingLastPathComponent().appendingPathComponent(filename)

        do {
            try data.write(to: outputURL)
            let location = url.deletingLastPathComponent().lastPathComponent
            let sizeChange = originalSize > 0 ? ((newSize - originalSize) * 100 / originalSize) : 0
            let sizeText = sizeChange > 0 ? "+\(sizeChange)%" : "\(sizeChange)%"
            return (true, "Converted \(sizeText)\n→ \(location)")
        } catch {
            return saveToDesktop(compressed: data, filename: filename, originalSize: originalSize, newSize: newSize, isConversion: true)
        }
    }

    func compressImage(url: URL, targetFormat: ImageFormat = .jpeg) -> (Bool, String) {
        guard let image = NSImage(contentsOf: url),
              let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else {
            return (false, "Invalid image")
        }

        let originalSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int) ?? 0
        var compressed: Data?
        var newSize = 0

        switch targetFormat {
        case .jpeg:
            // Compress to JPEG at 50% quality
            compressed = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.5])
        case .png:
            // PNG compression
            compressed = bitmap.representation(using: .png, properties: [:])
        }

        guard let data = compressed else {
            return (false, "Compression failed")
        }

        newSize = data.count

        // Save next to original file (works better with App Sandbox)
        let filename = url.deletingPathExtension().lastPathComponent + "_compressed." + targetFormat.fileExtension
        let outputURL = url.deletingLastPathComponent().appendingPathComponent(filename)

        do {
            try data.write(to: outputURL)
            let savings = originalSize > 0 ? ((originalSize - newSize) * 100 / originalSize) : 0
            let location = url.deletingLastPathComponent().lastPathComponent
            return (true, "Saved \(savings)%\n→ \(location)")
        } catch {
            // If saving next to original fails, try Desktop with explicit permission
            return saveToDesktop(compressed: data, filename: filename, originalSize: originalSize, newSize: newSize)
        }
    }

    private func saveToDesktop(compressed: Data, filename: String, originalSize: Int, newSize: Int, isConversion: Bool = false) -> (Bool, String) {
        // Try to get Desktop URL and request access
        guard let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first else {
            return (false, "Desktop access denied")
        }

        let outputURL = desktop.appendingPathComponent(filename)

        do {
            // Start accessing security-scoped resource if needed
            _ = outputURL.startAccessingSecurityScopedResource()
            defer { outputURL.stopAccessingSecurityScopedResource() }

            try compressed.write(to: outputURL)
            if isConversion {
                let sizeChange = originalSize > 0 ? ((newSize - originalSize) * 100 / originalSize) : 0
                let sizeText = sizeChange > 0 ? "+\(sizeChange)%" : "\(sizeChange)%"
                return (true, "Converted \(sizeText)\n→ Desktop")
            } else {
                let savings = originalSize > 0 ? ((originalSize - newSize) * 100 / originalSize) : 0
                return (true, "Saved \(savings)%\n→ Desktop")
            }
        } catch {
            return (false, "Save failed: \(error.localizedDescription)")
        }
    }

    func compressPDF(url: URL) -> (Bool, String) {
        // Use Quartz filter to compress
        // Save next to original file (works better with App Sandbox)
        let filename = url.deletingPathExtension().lastPathComponent + "_compressed.pdf"
        let outputURL = url.deletingLastPathComponent().appendingPathComponent(filename)

        // Escape paths for Python script
        let inputPath = url.path.replacingOccurrences(of: "'", with: "\\'")
        let outputPath = outputURL.path.replacingOccurrences(of: "'", with: "\\'")

        let task = Process()
        task.launchPath = "/usr/bin/python3"
        task.arguments = ["-c", """
            import Quartz
            import sys

            input_path = '\(inputPath)'
            output_path = '\(outputPath)'

            pdf_in = Quartz.PDFDocument(url=Quartz.NSURL.fileURLWithPath_(input_path))
            pdf_out = Quartz.PDFDocument.alloc().init()

            for i in range(pdf_in.pageCount()):
                page = pdf_in.pageAtIndex_(i)
                pdf_out.insertPage_atIndex_(page, i)

            options = {
                Quartz.kCGPDFContextImageCompression: 0.5
            }
            pdf_out.writeToFile_withOptions_(output_path, options)
        """]

        task.launch()
        task.waitUntilExit()

        if task.terminationStatus == 0 {
            let location = url.deletingLastPathComponent().lastPathComponent
            return (true, "Compressed\n→ \(location)")
        } else {
            return (false, "PDF compression failed")
        }
    }

    func compressVideo(url: URL) -> (Bool, String) {
        // Simple message - actual video compression is complex
        return (true, "Video detected\n(Feature coming)")
    }

    func copyToClipboard(url: URL) -> (Bool, String) {
        // Copy file path to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(url.path, forType: .string)

        return (true, "Path copied\nto clipboard")
    }

    func showResult(success: Bool, message: String) {
        isProcessing = false
        showSuccess = success
        statusText = message

        // Play sound
        if success {
            NSSound.beep()
        }

        // Reset after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.showSuccess = false
            self.statusText = "Drop files"
        }
    }
}

