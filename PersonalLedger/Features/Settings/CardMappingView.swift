import SwiftUI
import SwiftData
import LedgerCore

/// Card → source mapping (RFC §5.3): which `source` label an Apple Pay card is
/// logged under. Cards the automation has already logged without a mapping are
/// offered as one-tap starting points, so the exact name never has to be typed.
struct CardMappingView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @State private var mapping: [String: String]
    @State private var editing: CardMappingDraft?

    private let store: CardMappingStore

    init(store: CardMappingStore = CardMappingStore()) {
        self.store = store
        _mapping = State(initialValue: store.mapping)
    }

    private var cards: [String] {
        mapping.keys.sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    private var unmappedCards: [String] {
        CardSourceResolver.unmappedCards(in: transactions.map(\.data), mapping: mapping)
    }

    /// Sources already in the ledger, minus fallback labels — those are what a
    /// mapping replaces, so suggesting them would be a no-op.
    private var knownSources: [String] {
        LedgerQuery.distinctSources(in: transactions.map(\.data))
            .filter { !$0.hasPrefix(CardSourceResolver.fallbackPrefix) }
    }

    var body: some View {
        List {
            Section {
                ForEach(cards, id: \.self) { card in
                    mappingRow(card: card, source: mapping[card] ?? "")
                }
                Button("Add Card") { editing = CardMappingDraft(card: "", source: "", isNew: true) }
            } footer: {
                Text("A card not listed here is logged as “\(CardSourceResolver.fallbackPrefix)card name”. Changes apply to new entries only.")
            }
            if !unmappedCards.isEmpty {
                Section("Seen in your ledger") {
                    ForEach(unmappedCards, id: \.self) { card in
                        Button(card) { editing = CardMappingDraft(card: card, source: "", isNew: true) }
                    }
                }
            }
        }
        .navigationTitle("Card names")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editing) { draft in
            CardMappingFormView(draft: draft, knownSources: knownSources) { saved in
                store.setSource(saved.source, forCard: saved.card)
                mapping = store.mapping
            }
        }
    }

    private func mappingRow(card: String, source: String) -> some View {
        Button {
            editing = CardMappingDraft(card: card, source: source, isNew: false)
        } label: {
            LabeledContent(card, value: source)
                .contentShape(Rectangle())
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                store.removeCard(card)
                mapping = store.mapping
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.destructiveSwipe)
        }
    }
}

#Preview {
    NavigationStack { CardMappingView() }
        .modelContainer(for: Transaction.self, inMemory: true)
}
