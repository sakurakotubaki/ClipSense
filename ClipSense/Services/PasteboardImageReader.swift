//
//  PasteboardImageReader.swift
//  ClipSense
//

import AppKit
import Foundation

struct ClipboardImagePayload {
    let image: NSImage
    let pngData: Data
    let displayName: String
    let originalFileName: String?
}

struct PasteboardImageReader {
    nonisolated init() {}

    func imagePayload(from pasteboard: NSPasteboard) -> ClipboardImagePayload? {
        if let filePayload = imageFilePayload(from: pasteboard) {
            return filePayload
        }

        guard let image = NSImage(pasteboard: pasteboard),
              let pngData = image.pngData
        else {
            return nil
        }

        return ClipboardImagePayload(
            image: image,
            pngData: pngData,
            displayName: "Clipboard Image",
            originalFileName: nil
        )
    }

    private func imageFilePayload(from pasteboard: NSPasteboard) -> ClipboardImagePayload? {
        guard let urls = pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL] else {
            return nil
        }

        for url in urls where isSupportedImageFile(url) {
            guard let image = NSImage(contentsOf: url),
                  let pngData = image.pngData
            else {
                continue
            }

            return ClipboardImagePayload(
                image: image,
                pngData: pngData,
                displayName: url.lastPathComponent,
                originalFileName: url.lastPathComponent
            )
        }

        return nil
    }

    private func isSupportedImageFile(_ url: URL) -> Bool {
        ["png", "jpg", "jpeg", "heic", "tiff", "gif", "webp"].contains(url.pathExtension.lowercased())
    }
}

private extension NSImage {
    var pngData: Data? {
        guard let tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffRepresentation)
        else {
            return nil
        }

        return bitmap.representation(using: .png, properties: [:])
    }
}
