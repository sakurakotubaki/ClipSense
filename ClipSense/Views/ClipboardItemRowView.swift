//
//  ClipboardItemRowView.swift
//  ClipSense
//

import SwiftUI

struct ClipboardItemRowView: View {
    let item: ClipboardItem
    let isSelected: Bool
    let copyAction: () -> Void
    let pinAction: () -> Void
    let deleteAction: () -> Void

    var body: some View {
        Button(action: copyAction) {
            HStack(alignment: .top, spacing: 10) {
                if item.isImage {
                    thumbnail
                }

                VStack(alignment: .leading, spacing: 6) {
                    if item.isImage {
                        Label(item.content, systemImage: "photo")
                            .font(.system(.body, design: .default))
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        Text(item.content)
                            .font(.system(.body, design: .default))
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    HStack(spacing: 8) {
                        if let sourceAppName = item.sourceAppName, !sourceAppName.isEmpty {
                            Label(sourceAppName, systemImage: "app")
                                .labelStyle(.titleAndIcon)
                        }

                        Text(item.updatedAt, style: .relative)

                        if item.isImage {
                            Text(imageMetadataText)
                        } else {
                            Text("\(item.characterCount) chars")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }

                HStack(spacing: 4) {
                    Button(action: copyAction) {
                        Image(systemName: "doc.on.doc")
                    }
                    .buttonStyle(.borderless)
                    .help("Copy")

                    Button(action: pinAction) {
                        Image(systemName: item.isPinned ? "pin.fill" : "pin")
                    }
                    .buttonStyle(.borderless)
                    .help(item.isPinned ? "Unpin" : "Pin")

                    Button(role: .destructive, action: deleteAction) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    .help("Delete")
                }
                .font(.system(size: 13, weight: .medium))
                .frame(minWidth: 72, alignment: .trailing)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .contentShape(Rectangle())
            .background {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.16) : Color.clear)
            }
        }
        .buttonStyle(.plain)
    }

    private var thumbnail: some View {
        Group {
            if let image = ClipboardImageStore().image(for: item) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 52, height: 52)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(.separator.opacity(0.5), lineWidth: 1)
        }
    }

    private var imageMetadataText: String {
        var components: [String] = []

        if let imageWidth = item.imageWidth, let imageHeight = item.imageHeight {
            components.append("\(Int(imageWidth))x\(Int(imageHeight))")
        }

        if let imageByteSize = item.imageByteSize {
            components.append(ByteCountFormatter.string(fromByteCount: Int64(imageByteSize), countStyle: .file))
        }

        return components.isEmpty ? "Image" : components.joined(separator: " · ")
    }
}
