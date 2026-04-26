//
//  ClipboardRepository.swift
//  ClipSense
//

import AppKit
import Foundation
import SwiftData

@MainActor
final class ClipboardRepository {
    private let context: ModelContext
    private let filter: ClipboardSecurityFilter
    private let soundPlayer: ClipboardSoundPlayer

    init(context: ModelContext) {
        self.context = context
        self.filter = ClipboardSecurityFilter()
        self.soundPlayer = ClipboardSoundPlayer()
    }

    init(
        context: ModelContext,
        filter: ClipboardSecurityFilter,
        soundPlayer: ClipboardSoundPlayer
    ) {
        self.context = context
        self.filter = filter
        self.soundPlayer = soundPlayer
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

    func copyToPasteboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(item.content, forType: .string)
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
