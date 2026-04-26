//
//  PasteboardMonitor.swift
//  ClipSense
//

import AppKit
import Foundation

@MainActor
final class PasteboardMonitor {
    private let pasteboard: NSPasteboard
    private let repository: ClipboardRepository
    private let sourceApplicationResolver: SourceApplicationResolver
    private var monitoringTask: Task<Void, Never>?
    private var lastChangeCount: Int

    init(
        pasteboard: NSPasteboard = .general,
        repository: ClipboardRepository,
        sourceApplicationResolver: SourceApplicationResolver = SourceApplicationResolver()
    ) {
        self.pasteboard = pasteboard
        self.repository = repository
        self.sourceApplicationResolver = sourceApplicationResolver
        self.lastChangeCount = pasteboard.changeCount
    }

    func start() {
        guard monitoringTask == nil else {
            return
        }

        monitoringTask = Task { [weak self] in
            await self?.monitorChanges()
        }
    }

    func stop() {
        monitoringTask?.cancel()
        monitoringTask = nil
    }

    private func monitorChanges() async {
        while !Task.isCancelled {
            pollPasteboard()
            try? await Task.sleep(for: .milliseconds(500))
        }
    }

    private func pollPasteboard() {
        let currentChangeCount = pasteboard.changeCount
        guard currentChangeCount != lastChangeCount else {
            return
        }

        lastChangeCount = currentChangeCount

        guard let content = pasteboard.string(forType: .string) else {
            return
        }

        repository.saveIfAllowed(
            content: content,
            sourceAppName: sourceApplicationResolver.frontmostApplicationName()
        )
    }

    deinit {
        monitoringTask?.cancel()
    }
}
