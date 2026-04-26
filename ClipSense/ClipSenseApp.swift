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
        Settings {
            EmptyView()
        }
    }
}
