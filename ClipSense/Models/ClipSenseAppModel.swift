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

    @ObservationIgnored
    private let pasteboardMonitor: PasteboardMonitor
    @ObservationIgnored
    private let statusBarController: StatusBarController
    @ObservationIgnored
    private var hotKeyObserver: NSObjectProtocol?

    init() {
        do {
            modelContainer = try ModelContainer(for: ClipboardItem.self)
        } catch {
            fatalError("Failed to create SwiftData model container: \(error)")
        }

        let repository = ClipboardRepository(context: modelContainer.mainContext)
        history = ClipboardHistoryModel(repository: repository)
        pasteboardMonitor = PasteboardMonitor(repository: repository)
        statusBarController = StatusBarController(modelContainer: modelContainer, history: history)

        pasteboardMonitor.start()
        GlobalHotKeyManager.shared.registerDefaultHotKey()

        let controller = statusBarController
        hotKeyObserver = NotificationCenter.default.addObserver(
            forName: .clipSenseHotKeyPressed,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor [weak controller] in
                controller?.togglePopover()
            }
        }
    }

    deinit {
        if let hotKeyObserver {
            NotificationCenter.default.removeObserver(hotKeyObserver)
        }
    }
}
