//
//  ClipSenseAppModel.swift
//  ClipSense
//

import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class ClipSenseAppModel {
    let modelContainer: ModelContainer
    let history: ClipboardHistoryModel

    private let pasteboardMonitor: PasteboardMonitor

    init() {
        do {
            modelContainer = try ModelContainer(for: ClipboardItem.self)
        } catch {
            fatalError("Failed to create SwiftData model container: \(error)")
        }

        let repository = ClipboardRepository(context: modelContainer.mainContext)
        history = ClipboardHistoryModel(repository: repository)
        pasteboardMonitor = PasteboardMonitor(repository: repository)

        pasteboardMonitor.start()
        GlobalHotKeyManager.shared.registerDefaultHotKey()
    }
}
