//
//  ClipboardHistoryView.swift
//  ClipSense
//

import SwiftData
import SwiftUI

struct ClipboardHistoryView: View {
    @Query(sort: \ClipboardItem.updatedAt, order: .reverse) private var items: [ClipboardItem]
    @Bindable private var model: ClipboardHistoryModel
    @FocusState private var isSearchFocused: Bool

    init(model: ClipboardHistoryModel) {
        self.model = model
    }

    var body: some View {
        VStack(spacing: 0) {
            searchField
                .padding(12)

            Divider()

            content
                .frame(minHeight: 360)
        }
        .frame(width: 420, height: 520)
        .background(.regularMaterial)
        .onAppear {
            isSearchFocused = true
            model.selectFirstItemIfNeeded(from: items)
        }
        .onChange(of: items.map(\.id)) {
            model.selectFirstItemIfNeeded(from: items)
        }
        .onChange(of: model.searchText) {
            model.selectFirstItemIfNeeded(from: items)
        }
        .onReceive(NotificationCenter.default.publisher(for: .clipSenseHotKeyPressed)) { _ in
            isSearchFocused = true
        }
        .focusable()
        .onMoveCommand { direction in
            switch direction {
            case .up:
                model.moveSelection(direction: .up, items: items)
            case .down:
                model.moveSelection(direction: .down, items: items)
            default:
                break
            }
        }
        .onKeyPress(.return) {
            guard let selectedItem = model.selectedItem(from: items) else {
                return .ignored
            }

            model.copy(selectedItem)
            return .handled
        }
        .onKeyPress(.delete) {
            guard let selectedItem = model.selectedItem(from: items) else {
                return .ignored
            }

            model.delete(selectedItem)
            return .handled
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search history", text: $model.searchText)
                .textFieldStyle(.plain)
                .focused($isSearchFocused)

            if !model.searchText.isEmpty {
                Button {
                    model.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .help("Clear Search")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    @ViewBuilder
    private var content: some View {
        let filteredItems = model.filteredItems(from: items)

        if filteredItems.isEmpty {
            EmptyHistoryView()
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        section(title: "Pinned", items: model.pinnedItems(from: items))
                        section(title: "Recent", items: model.recentItems(from: items))
                    }
                    .padding(12)
                }
                .onChange(of: model.selectedItemID) { _, selectedItemID in
                    guard let selectedItemID else {
                        return
                    }

                    withAnimation(.snappy(duration: 0.18)) {
                        proxy.scrollTo(selectedItemID, anchor: .center)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func section(title: String, items: [ClipboardItem]) -> some View {
        if !items.isEmpty {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, 4)
                .padding(.top, title == "Pinned" ? 0 : 8)

            ForEach(items) { item in
                ClipboardItemRowView(
                    item: item,
                    isSelected: model.selectedItemID == item.id,
                    copyAction: {
                        model.selectedItemID = item.id
                        model.copy(item)
                    },
                    pinAction: {
                        model.selectedItemID = item.id
                        model.togglePinned(item)
                    },
                    deleteAction: {
                        model.delete(item)
                    }
                )
                .id(item.id)
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: ClipboardItem.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let repository = ClipboardRepository(context: container.mainContext)
    let model = ClipboardHistoryModel(repository: repository)

    ClipboardHistoryView(model: model)
        .modelContainer(container)
}
