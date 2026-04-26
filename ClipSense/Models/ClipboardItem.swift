//
//  ClipboardItem.swift
//  ClipSense
//

import Foundation
import SwiftData

@Model
final class ClipboardItem {
    @Attribute(.unique) var id: UUID
    var content: String
    var createdAt: Date
    var updatedAt: Date
    var isPinned: Bool
    var sourceAppName: String?
    var contentType: String
    var characterCount: Int

    init(
        id: UUID = UUID(),
        content: String,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        isPinned: Bool = false,
        sourceAppName: String? = nil,
        contentType: String = ClipboardItem.plainTextContentType
    ) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPinned = isPinned
        self.sourceAppName = sourceAppName
        self.contentType = contentType
        self.characterCount = content.count
    }
}

extension ClipboardItem {
    static let plainTextContentType = "public.utf8-plain-text"
}
