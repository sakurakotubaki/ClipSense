//
//  ClipboardImageStore.swift
//  ClipSense
//

import AppKit
import CryptoKit
import Foundation

struct StoredClipboardImage {
    let fileName: String
    let byteSize: Int
    let width: Double
    let height: Double
    let hash: String
}

@MainActor
final class ClipboardImageStore {
    private let directoryURL: URL
    private let pasteboardExportDirectoryURL: URL
    private let fileManager: FileManager

    init(
        directoryURL: URL? = nil,
        pasteboardExportDirectoryURL: URL? = nil,
        fileManager: FileManager = .default
    ) {
        self.fileManager = fileManager

        if let directoryURL {
            self.directoryURL = directoryURL
        } else {
            let appSupportURL = try? fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            self.directoryURL = (appSupportURL ?? fileManager.temporaryDirectory)
                .appendingPathComponent("ClipSense", isDirectory: true)
                .appendingPathComponent("ClipboardImages", isDirectory: true)
        }

        self.pasteboardExportDirectoryURL = pasteboardExportDirectoryURL
            ?? fileManager.temporaryDirectory
                .appendingPathComponent("ClipSense", isDirectory: true)
                .appendingPathComponent("PasteboardExports", isDirectory: true)
    }

    func storePNGData(_ data: Data, image: NSImage) throws -> StoredClipboardImage {
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let hash = SHA256.hash(data: data)
            .map { String(format: "%02x", $0) }
            .joined()
        let fileName = "\(UUID().uuidString).png"
        try data.write(to: url(for: fileName), options: [.atomic])

        let size = image.pixelSize ?? image.size
        return StoredClipboardImage(
            fileName: fileName,
            byteSize: data.count,
            width: size.width,
            height: size.height,
            hash: hash
        )
    }

    func image(for item: ClipboardItem) -> NSImage? {
        guard let imageFileName = item.imageFileName else {
            return nil
        }

        return NSImage(contentsOf: url(for: imageFileName))
    }

    func pngData(for item: ClipboardItem) -> Data? {
        guard let imageFileName = item.imageFileName else {
            return nil
        }

        return try? Data(contentsOf: url(for: imageFileName))
    }

    func exportPNGFileForPasteboard(for item: ClipboardItem) throws -> URL {
        guard let data = pngData(for: item) else {
            throw ClipboardImageStoreError.missingImageData
        }

        try fileManager.createDirectory(at: pasteboardExportDirectoryURL, withIntermediateDirectories: true)

        let fileName = pasteboardExportFileName(for: item)
        let exportURL = pasteboardExportDirectoryURL.appendingPathComponent(fileName)
        try? fileManager.removeItem(at: exportURL)
        try data.write(to: exportURL, options: [.atomic])
        return exportURL
    }

    func removeImage(for item: ClipboardItem) {
        guard let imageFileName = item.imageFileName else {
            return
        }

        removeImage(fileName: imageFileName)
    }

    func removeImage(fileName: String) {
        try? fileManager.removeItem(at: url(for: fileName))
    }

    private func url(for fileName: String) -> URL {
        directoryURL.appendingPathComponent(fileName)
    }

    private func pasteboardExportFileName(for item: ClipboardItem) -> String {
        let candidate = item.originalFileName ?? item.content
        let sanitizedName = candidate
            .components(separatedBy: CharacterSet(charactersIn: "/:"))
            .joined(separator: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let baseName = sanitizedName.isEmpty ? "Clipboard Image" : sanitizedName
        let nameWithoutExtension = (baseName as NSString).deletingPathExtension

        return "\(nameWithoutExtension)-\(item.id.uuidString).png"
    }
}

enum ClipboardImageStoreError: Error {
    case missingImageData
}

private extension NSImage {
    var pixelSize: NSSize? {
        representations
            .compactMap { representation -> NSSize? in
                guard representation.pixelsWide > 0, representation.pixelsHigh > 0 else {
                    return nil
                }

                return NSSize(width: representation.pixelsWide, height: representation.pixelsHigh)
            }
            .first
    }
}
