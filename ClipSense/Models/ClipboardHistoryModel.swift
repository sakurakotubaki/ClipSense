//
//  ClipboardHistoryModel.swift
//  ClipSense
//

import Foundation
import Observation

@MainActor
@Observable
final class ClipboardHistoryModel {
    var searchText = ""
    var selectedItemID: UUID?

    private let repository: ClipboardRepository

    init(repository: ClipboardRepository) {
        self.repository = repository
    }

    func filteredItems(from items: [ClipboardItem]) -> [ClipboardItem] {
        let sortedItems = items.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned
            }

            return lhs.updatedAt > rhs.updatedAt
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return sortedItems
        }

        return sortedItems.filter { item in
            item.content.localizedCaseInsensitiveContains(query)
            || item.sourceAppName?.localizedCaseInsensitiveContains(query) == true
            || item.originalFileName?.localizedCaseInsensitiveContains(query) == true
            || (item.isImage && "image".localizedCaseInsensitiveContains(query))
        }
    }

    func pinnedItems(from items: [ClipboardItem]) -> [ClipboardItem] {
        filteredItems(from: items).filter(\.isPinned)
    }

    func recentItems(from items: [ClipboardItem]) -> [ClipboardItem] {
        filteredItems(from: items).filter { !$0.isPinned }
    }

    func copy(_ item: ClipboardItem) {
        repository.copyToPasteboard(item)
    }

    func togglePinned(_ item: ClipboardItem) {
        repository.togglePinned(item)
    }

    func delete(_ item: ClipboardItem) {
        if selectedItemID == item.id {
            selectedItemID = nil
        }

        repository.delete(item)
    }

    func selectFirstItemIfNeeded(from items: [ClipboardItem]) {
        let filteredItems = filteredItems(from: items)
        guard selectedItemID == nil || filteredItems.contains(where: { $0.id == selectedItemID }) == false else {
            return
        }

        selectedItemID = filteredItems.first?.id
    }

    func moveSelection(direction: SelectionDirection, items: [ClipboardItem]) {
        let filteredItems = filteredItems(from: items)
        guard !filteredItems.isEmpty else {
            selectedItemID = nil
            return
        }

        guard
            let selectedItemID,
            let currentIndex = filteredItems.firstIndex(where: { $0.id == selectedItemID })
        else {
            self.selectedItemID = filteredItems.first?.id
            return
        }

        let nextIndex: Int
        switch direction {
        case .up:
            nextIndex = max(filteredItems.startIndex, currentIndex - 1)
        case .down:
            nextIndex = min(filteredItems.index(before: filteredItems.endIndex), currentIndex + 1)
        }

        self.selectedItemID = filteredItems[nextIndex].id
    }

    func selectedItem(from items: [ClipboardItem]) -> ClipboardItem? {
        guard let selectedItemID else {
            return nil
        }

        return filteredItems(from: items).first { $0.id == selectedItemID }
    }
}

enum SelectionDirection {
    case up
    case down
}
