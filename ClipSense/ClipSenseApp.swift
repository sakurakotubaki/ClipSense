//
//  ClipSenseApp.swift
//  ClipSense
//

import SwiftUI
import SwiftData

@main
struct ClipSenseApp: App {
    @State private var appModel = ClipSenseAppModel()

    var body: some Scene {
        MenuBarExtra("ClipSense", systemImage: "doc.on.clipboard") {
            ClipboardHistoryView(model: appModel.history)
                .modelContainer(appModel.modelContainer)
        }
        .menuBarExtraStyle(.window)
    }
}
