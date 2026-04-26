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
    var imageFileName: String?
    var imageWidth: Double?
    var imageHeight: Double?
    var imageByteSize: Int?
    var imageHash: String?
    var originalFileName: String?

    init(
        id: UUID = UUID(),
        content: String,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        isPinned: Bool = false,
        sourceAppName: String? = nil,
        contentType: String = ClipboardItem.plainTextContentType,
        imageFileName: String? = nil,
        imageWidth: Double? = nil,
        imageHeight: Double? = nil,
        imageByteSize: Int? = nil,
        imageHash: String? = nil,
        originalFileName: String? = nil
    ) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPinned = isPinned
        self.sourceAppName = sourceAppName
        self.contentType = contentType
        self.characterCount = content.count
        self.imageFileName = imageFileName
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        self.imageByteSize = imageByteSize
        self.imageHash = imageHash
        self.originalFileName = originalFileName
    }
}

extension ClipboardItem {
    static let plainTextContentType = "public.utf8-plain-text"
    static let pngContentType = "public.png"

    var isImage: Bool {
        contentType == Self.pngContentType && imageFileName != nil
    }
}
