import SwiftUI

/// Editable state for one card → source mapping. The card name is the key, so it
/// is only editable while the mapping is new.
struct CardMappingDraft: Identifiable {
    let id = UUID()
    var card: String
    var source: String
    let isNew: Bool

    var isComplete: Bool {
        !card.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

/// Add/edit sheet for a single card mapping.
struct CardMappingFormView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: CardMappingDraft

    private let knownSources: [String]
    private let onSave: (CardMappingDraft) -> Void

    init(draft: CardMappingDraft, knownSources: [String], onSave: @escaping (CardMappingDraft) -> Void) {
        _draft = State(initialValue: draft)
        self.knownSources = knownSources
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    if draft.isNew {
                        TextField("e.g. BigPay Visa", text: $draft.card)
                            .autocorrectionDisabled()
                    } else {
                        Text(draft.card)
                    }
                } header: {
                    Text("Card name")
                } footer: {
                    Text("Use the name exactly as it appears after “Apple Pay – ” in your ledger.")
                }
                Section("Log it as") {
                    TextField("e.g. BigPay", text: $draft.source)
                    SuggestionChips(values: knownSources) { draft.source = $0 }
                }
            }
            .navigationTitle(draft.isNew ? "Add Card" : "Edit Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(draft)
                        dismiss()
                    }
                    .disabled(!draft.isComplete)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
