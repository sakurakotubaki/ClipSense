//
//  ClipboardRepositoryTests.swift
//  ClipSenseTests
//

import AppKit
import SwiftData
import Testing
@testable import ClipSense

@MainActor
@Suite(.serialized)
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

    @Test func imageClipboardPayloadStoresMetadataAndFile() throws {
        let harness = try RepositoryHarness()
        let payload = try ClipboardImagePayload.testPayload(fileName: "sample.png")

        let item = try #require(harness.repository.saveImageIfAllowed(payload, sourceAppName: "Preview"))

        #expect(item.isImage)
        #expect(item.content == "sample.png")
        #expect(item.contentType == ClipboardItem.pngContentType)
        #expect(item.imageByteSize == payload.pngData.count)
        #expect(item.imageWidth == 16)
        #expect(item.imageHeight == 16)
        #expect(item.originalFileName == "sample.png")
        #expect(harness.imageStore.image(for: item) != nil)
    }

    @Test func duplicateConsecutiveImageIsStoredOnce() throws {
        let harness = try RepositoryHarness()
        let payload = try ClipboardImagePayload.testPayload(fileName: "sample.png")

        harness.repository.saveImageIfAllowed(payload, sourceAppName: "Preview")
        harness.repository.saveImageIfAllowed(payload, sourceAppName: "Preview")

        #expect(try harness.fetchItems().count == 1)
    }

    @Test func deletingImageItemRemovesStoredFile() throws {
        let harness = try RepositoryHarness()
        let payload = try ClipboardImagePayload.testPayload(fileName: "sample.png")
        let item = try #require(harness.repository.saveImageIfAllowed(payload, sourceAppName: "Preview"))

        #expect(harness.imageStore.image(for: item) != nil)

        harness.repository.delete(item)

        #expect(harness.imageStore.image(for: item) == nil)
        #expect(try harness.fetchItems().isEmpty)
    }

    @Test func copyingImageItemWritesPNGAndTIFFPasteboardData() throws {
        let harness = try RepositoryHarness()
        let payload = try ClipboardImagePayload.testPayload(fileName: "sample.png")
        let item = try #require(harness.repository.saveImageIfAllowed(payload, sourceAppName: "Preview"))
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        defer { pasteboard.clearContents() }

        harness.repository.copyToPasteboard(item)

        #expect(pasteboard.data(forType: .png) == payload.pngData)
        #expect(pasteboard.data(forType: .tiff) != nil)
        #expect(pasteboard.string(forType: .string) == nil)
    }

    @Test func copyingImageItemWritesFileURLForFinderPaste() throws {
        let harness = try RepositoryHarness()
        let payload = try ClipboardImagePayload.testPayload(fileName: "sample.png")
        let item = try #require(harness.repository.saveImageIfAllowed(payload, sourceAppName: "Preview"))
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        defer { pasteboard.clearContents() }

        harness.repository.copyToPasteboard(item)

        let urls = try #require(pasteboard.readObjects(forClasses: [NSURL.self]) as? [URL])
        let fileURL = try #require(urls.first)
        let exportedData = try Data(contentsOf: fileURL)
        let fileNames = try #require(pasteboard.propertyList(forType: .fileNames) as? [String])

        #expect(fileURL.pathExtension == "png")
        #expect(fileURL.lastPathComponent.contains(item.id.uuidString))
        #expect(exportedData == payload.pngData)
        #expect(fileNames == [fileURL.path])
    }

    @Test func copyingTextItemWritesStringPasteboardData() throws {
        let harness = try RepositoryHarness()
        let item = try #require(harness.repository.saveIfAllowed(content: "Paste me", sourceAppName: "Notes"))
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        defer { pasteboard.clearContents() }

        harness.repository.copyToPasteboard(item)

        #expect(pasteboard.string(forType: .string) == "Paste me")
        #expect(pasteboard.data(forType: .png) == nil)
    }
}

@MainActor
private struct RepositoryHarness {
    let container: ModelContainer
    let repository: ClipboardRepository
    let imageStore: ClipboardImageStore

    init() throws {
        container = try ModelContainer(
            for: ClipboardItem.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )

        let imageDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ClipSenseTests-\(UUID().uuidString)", isDirectory: true)
        imageStore = ClipboardImageStore(directoryURL: imageDirectory)
        repository = ClipboardRepository(
            context: container.mainContext,
            filter: ClipboardSecurityFilter(),
            soundPlayer: ClipboardSoundPlayer(),
            imageStore: imageStore
        )
    }

    func fetchItems() throws -> [ClipboardItem] {
        try container.mainContext.fetch(FetchDescriptor<ClipboardItem>())
    }
}

private extension ClipboardImagePayload {
    static func testPayload(fileName: String) throws -> ClipboardImagePayload {
        let bitmap = try #require(NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: 16,
            pixelsHigh: 16,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ))
        bitmap.size = NSSize(width: 16, height: 16)

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        NSColor.systemBlue.setFill()
        NSRect(x: 0, y: 0, width: 16, height: 16).fill()
        NSGraphicsContext.restoreGraphicsState()

        let image = NSImage(size: NSSize(width: 16, height: 16))
        image.addRepresentation(bitmap)
        let pngData = try #require(bitmap.representation(using: .png, properties: [:]))
        return ClipboardImagePayload(
            image: image,
            pngData: pngData,
            displayName: fileName,
            originalFileName: fileName
        )
    }
}
