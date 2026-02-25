import SwiftUI

public struct SearchableSheetPicker<Item: Identifiable & Hashable>: View {
    @Binding private var selection: Item?

    private let title: LocalizedStringKey
    private let placeholder: LocalizedStringKey
    private let items: [Item]
    private let itemTitle: (Item) -> String
    private let disabled: Bool
    private let isLoading: Bool
    private let emptyMessage: LocalizedStringKey?

    @SwiftUI.State private var isPresenting = false
    @SwiftUI.State private var searchText = ""

    public init(
        title: LocalizedStringKey,
        placeholder: LocalizedStringKey,
        items: [Item],
        selection: Binding<Item?>,
        disabled: Bool = false,
        isLoading: Bool = false,
        emptyMessage: LocalizedStringKey? = nil,
        itemTitle: @escaping (Item) -> String
    ) {
        self.title = title
        self.placeholder = placeholder
        self.items = items
        self._selection = selection
        self.disabled = disabled
        self.isLoading = isLoading
        self.emptyMessage = emptyMessage
        self.itemTitle = itemTitle
    }

    public var body: some View {
        Button {
            isPresenting = true
        } label: {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Group {
                        if let selection {
                            Text(itemTitle(selection))
                                .foregroundStyle(.primary)
                        } else {
                            Text(placeholder)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .lineLimit(1)
                }
                Spacer()
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .sheet(isPresented: $isPresenting) {
            NavigationStack {
                List {
                    if filteredItems.isEmpty {
                        if #available(iOS 17.0, *) {
                            ContentUnavailableView {
                                Text(emptyMessage ?? "No results")
                            }
                        } else {
                            Text(emptyMessage ?? "No results")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding()
                        }
                    } else {
                        ForEach(filteredItems, id: \.self) { item in
                            Button {
                                selection = item
                                isPresenting = false
                            } label: {
                                HStack {
                                    Text(itemTitle(item))
                                    Spacer()
                                    if item == selection {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.tint)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .searchable(text: $searchText)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") { isPresenting = false }
                    }
                    if selection != nil {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Clear") {
                                selection = nil
                                isPresenting = false
                            }
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var filteredItems: [Item] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return items }
        return items.filter { itemTitle($0).localizedCaseInsensitiveContains(trimmed) }
    }
}
