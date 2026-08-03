import SwiftUI
import LedgerCore

/// The Add/Edit transaction sheet (RFC §FR-2, §FR-7). Same form for both; the
/// primary button reads Add or Save and is disabled until valid/changed.
struct TransactionSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var model: TransactionFormModel
    @State private var confirmingDelete = false
    @FocusState private var amountFocused: Bool

    private let recentSources: [String]

    init(mode: TransactionFormModel.Mode, repository: TransactionRepository, recentSources: [String]) {
        _model = State(initialValue: TransactionFormModel(mode: mode, repository: repository))
        self.recentSources = recentSources
    }

    var body: some View {
        NavigationStack {
            Form {
                amountSection
                categorySection
                sourceSection
                detailsSection
                if model.isEditing { deleteSection }
            }
            .navigationTitle(model.isEditing ? "Edit Transaction" : "Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(model.isEditing ? "Save" : "Add") { save() }
                        .disabled(!model.canSave)
                        .fontWeight(.semibold)
                }
            }
            .onAppear { amountFocused = true }
        }
    }

    // MARK: Sections

    private var amountSection: some View {
        Section {
            HStack {
                Text("RM").foregroundStyle(.secondary)
                TextField("0.00", text: $model.draft.amountText)
                    .keyboardType(.decimalPad)
                    .font(.title2)
                    .monospacedDigit()
                    .focused($amountFocused)
            }
            Picker("Kind", selection: $model.draft.kind) {
                Text("Expense").tag(TransactionKind.expense)
                Text("Refund").tag(TransactionKind.refund)
            }
            .pickerStyle(.segmented)
            if let preview = effectivePreview {
                Text("Recorded as \(preview)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var categorySection: some View {
        Section {
            Picker("Category", selection: $model.draft.category) {
                ForEach(SpendingCategory.allCases, id: \.self) { category in
                    Text(category.displayName).tag(category.rawValue)
                }
            }
        }
    }

    private var sourceSection: some View {
        Section("Source") {
            TextField("e.g. Maybank debit, Cash", text: $model.draft.source)
            SourceChips(sources: recentSources) { model.draft.source = $0 }
        }
    }

    private var detailsSection: some View {
        Section {
            DatePicker("Date", selection: $model.draft.date, displayedComponents: .date)
            TextField("Merchant (optional)", text: $model.draft.merchant)
        }
    }

    private var deleteSection: some View {
        Section {
            Button("Delete Transaction", role: .destructive) { confirmingDelete = true }
                .frame(maxWidth: .infinity)
                .confirmationDialog("Delete this transaction?", isPresented: $confirmingDelete, titleVisibility: .visible) {
                    Button("Delete", role: .destructive) { deleteAndDismiss() }
                    Button("Cancel", role: .cancel) {}
                }
        }
    }

    // MARK: Helpers

    /// Live preview of the signed effective amount, so a refund visibly flips
    /// negative (RFC §FR-2).
    private var effectivePreview: String? {
        guard let amount = Money.parse(userInput: model.draft.amountText) else { return nil }
        return MoneyFormatter.displayEffective(Money.effective(amount: amount, kind: model.draft.kind))
    }

    private func save() {
        do {
            try model.save()
            dismiss()
        } catch {
            // Persistence failure is unexpected for a local store; keep the sheet
            // open so the entry isn't lost.
        }
    }

    private func deleteAndDismiss() {
        try? model.deleteIfEditing()
        dismiss()
    }
}
