//
//  ClipboardRepository.swift
//  ClipSense
//

import AppKit
import Foundation
import os
import SwiftData

@MainActor
final class ClipboardRepository {
    private static let log = Logger(subsystem: "com.junichihashimoto.ClipSense", category: "ClipboardRepository")

    private let context: ModelContext
    private let filter: ClipboardSecurityFilter
    private let soundPlayer: ClipboardSoundPlayer
    private let imageStore: ClipboardImageStore

    init(context: ModelContext) {
        self.context = context
        self.filter = ClipboardSecurityFilter()
        self.soundPlayer = ClipboardSoundPlayer()
        self.imageStore = ClipboardImageStore()
    }

    init(
        context: ModelContext,
        filter: ClipboardSecurityFilter,
        soundPlayer: ClipboardSoundPlayer,
        imageStore: ClipboardImageStore
    ) {
        self.context = context
        self.filter = filter
        self.soundPlayer = soundPlayer
        self.imageStore = imageStore
    }

    @discardableResult
    func saveIfAllowed(content: String, sourceAppName: String?) -> ClipboardItem? {
        let normalizedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)

        guard filter.shouldStore(normalizedContent) else {
            return nil
        }

        if let latest = latestItem(), latest.content == normalizedContent {
            return nil
        }

        if let existing = item(matching: normalizedContent) {
            existing.updatedAt = .now
            existing.sourceAppName = sourceAppName
            existing.characterCount = normalizedContent.count
            saveContext()
            soundPlayer.playCopySound()
            return existing
        }

        let item = ClipboardItem(
            content: normalizedContent,
            sourceAppName: sourceAppName,
            contentType: ClipboardItem.plainTextContentType
        )
        context.insert(item)
        saveContext()
        soundPlayer.playCopySound()
        return item
    }

    @discardableResult
    func saveImageIfAllowed(_ payload: ClipboardImagePayload, sourceAppName: String?) -> ClipboardItem? {
        guard let storedImage = try? imageStore.storePNGData(payload.pngData, image: payload.image) else {
            return nil
        }

        if let latest = latestItem(), latest.imageHash == storedImage.hash {
            imageStore.removeImage(fileName: storedImage.fileName)
            return nil
        }

        if let existing = item(matchingImageHash: storedImage.hash) {
            imageStore.removeImage(fileName: storedImage.fileName)
            existing.updatedAt = .now
            existing.sourceAppName = sourceAppName
            saveContext()
            soundPlayer.playCopySound()
            return existing
        }

        let item = ClipboardItem(
            content: payload.displayName,
            sourceAppName: sourceAppName,
            contentType: ClipboardItem.pngContentType,
            imageFileName: storedImage.fileName,
            imageWidth: storedImage.width,
            imageHeight: storedImage.height,
            imageByteSize: storedImage.byteSize,
            imageHash: storedImage.hash,
            originalFileName: payload.originalFileName
        )
        context.insert(item)
        saveContext()
        soundPlayer.playCopySound()
        return item
    }

    func copyToPasteboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        if item.isImage {
            guard let pngData = imageStore.pngData(for: item),
                  let image = imageStore.image(for: item)
            else {
                Self.log.error("Stored image missing for clipboard item id=\(item.id.uuidString, privacy: .public)")
                return
            }

            do {
                let fileURL = try imageStore.exportPNGFileForPasteboard(for: item)
                pasteboard.writeObjects([fileURL as NSURL])
                pasteboard.setPropertyList([fileURL.path], forType: .fileNames)
            } catch {
                Self.log.error(
                    "Failed to export image file for pasteboard item id=\(item.id.uuidString, privacy: .public): \(error.localizedDescription)"
                )
            }

            pasteboard.setData(pngData, forType: .png)

            if let tiffData = image.tiffRepresentation {
                pasteboard.setData(tiffData, forType: .tiff)
            }
        } else {
            pasteboard.setString(item.content, forType: .string)
        }

        item.updatedAt = .now
        saveContext()
        soundPlayer.playCopySound()
    }

    func togglePinned(_ item: ClipboardItem) {
        item.isPinned.toggle()
        item.updatedAt = .now
        saveContext()
    }

    func delete(_ item: ClipboardItem) {
        imageStore.removeImage(for: item)
        context.delete(item)
        saveContext()
    }

    func deleteAllUnpinned(olderThan date: Date) {
        let descriptor = FetchDescriptor<ClipboardItem>(
            predicate: #Predicate { item in
                item.isPinned == false && item.updatedAt < date
            }
        )

        guard let items = try? context.fetch(descriptor) else {
            return
        }

        for item in items {
            imageStore.removeImage(for: item)
            context.delete(item)
        }

        saveContext()
    }

    private func latestItem() -> ClipboardItem? {
        var descriptor = FetchDescriptor<ClipboardItem>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }

    private func item(matching content: String) -> ClipboardItem? {
        let descriptor = FetchDescriptor<ClipboardItem>(
            predicate: #Predicate { item in
                item.content == content
            }
        )
        return try? context.fetch(descriptor)
            .first { $0.contentType == ClipboardItem.plainTextContentType }
    }

    private func item(matchingImageHash imageHash: String) -> ClipboardItem? {
        let descriptor = FetchDescriptor<ClipboardItem>(
            predicate: #Predicate { item in
                item.imageHash == imageHash
            }
        )
        return try? context.fetch(descriptor).first
    }

    private func saveContext() {
        do {
            try context.save()
        } catch {
            assertionFailure("Failed to save clipboard history: \(error)")
        }
    }
}

extension NSPasteboard.PasteboardType {
    static let fileNames = NSPasteboard.PasteboardType("NSFilenamesPboardType")
}
