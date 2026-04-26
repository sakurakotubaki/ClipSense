//
//  ClipboardRepositoryTests.swift
//  ClipSenseTests
//

import SwiftData
import Testing
@testable import ClipSense

@MainActor
struct ClipboardRepositoryTests {
    @Test func duplicateConsecutiveCopyIsStoredOnce() throws {
        let harness = try RepositoryHarness()

        harness.repository.saveIfAllowed(content: "Hello ClipSense", sourceAppName: "Notes")
        harness.repository.saveIfAllowed(content: "Hello ClipSense", sourceAppName: "Notes")

        #expect(try harness.fetchItems().count == 1)
    }

    @Test func existingContentUpdatesTimestamp() throws {
        let harness = try RepositoryHarness()

        let first = try #require(harness.repository.saveIfAllowed(content: "First", sourceAppName: "Notes"))
        _ = harness.repository.saveIfAllowed(content: "Second", sourceAppName: "Safari")
        let updated = try #require(harness.repository.saveIfAllowed(content: "First", sourceAppName: "Finder"))

        #expect(first.id == updated.id)
        #expect(updated.sourceAppName == "Finder")
        #expect(updated.updatedAt >= first.createdAt)
        #expect(try harness.fetchItems().count == 2)
    }

    @Test func pinAndDeleteMutateStoredItem() throws {
        let harness = try RepositoryHarness()
        let item = try #require(harness.repository.saveIfAllowed(content: "Pinned text", sourceAppName: nil))

        harness.repository.togglePinned(item)
        #expect(item.isPinned)

        harness.repository.delete(item)
        #expect(try harness.fetchItems().isEmpty)
    }
}

@MainActor
private struct RepositoryHarness {
    let container: ModelContainer
    let repository: ClipboardRepository

    init() throws {
        container = try ModelContainer(
            for: ClipboardItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        repository = ClipboardRepository(context: container.mainContext)
    }

    func fetchItems() throws -> [ClipboardItem] {
        try container.mainContext.fetch(FetchDescriptor<ClipboardItem>())
    }
}
