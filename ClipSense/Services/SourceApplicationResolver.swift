//
//  SourceApplicationResolver.swift
//  ClipSense
//

import AppKit
import Foundation

struct SourceApplicationResolver {
    nonisolated init() {}

    func frontmostApplicationName() -> String? {
        NSWorkspace.shared.frontmostApplication?.localizedName
    }
}
