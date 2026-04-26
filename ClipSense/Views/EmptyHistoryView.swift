//
//  EmptyHistoryView.swift
//  ClipSense
//

import SwiftUI

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(.secondary)

            Text("No Clipboard History")
                .font(.headline)

            Text("Copied text will appear here.")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(28)
    }
}
