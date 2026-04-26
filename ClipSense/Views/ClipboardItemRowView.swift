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
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.content)
                        .font(.system(.body, design: .default))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: 8) {
                        if let sourceAppName = item.sourceAppName, !sourceAppName.isEmpty {
                            Label(sourceAppName, systemImage: "app")
                                .labelStyle(.titleAndIcon)
                        }

                        Text(item.updatedAt, style: .relative)

                        Text("\(item.characterCount) chars")
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
}
