import SwiftUI
import SwiftData
import LedgerCore

/// Landing screen (RFC §FR-1): the selected month's ledger with a pinned running
/// total, reverse-chronological list, a always-visible Add button, a history
/// drawer, and two-step delete.
struct LedgerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]

    @State private var selectedMonth = YearMonth(date: Date())
    @State private var showingSidebar = false
    @State private var showingAddSheet = false
    @State private var editingTransaction: Transaction?
    @State private var pendingDelete: Transaction?

    private var repository: SwiftDataTransactionRepository {
        SwiftDataTransactionRepository(context: modelContext)
    }

    private var monthTransactions: [Transaction] {
        transactions.filter { YearMonth(date: $0.date) == selectedMonth }
    }

    private var total: Decimal {
        LedgerTotals.total(of: monthTransactions.map(\.data))
    }

    /// Distinct sources, most-recent first, for the Add form's quick chips.
    private var recentSources: [String] {
        var seen = Set<String>()
        var result: [String] = []
        for transaction in transactions where seen.insert(transaction.source).inserted {
            result.append(transaction.source)
            if result.count == 6 { break }
        }
        return result
    }

    var body: some View {
        ZStack(alignment: .leading) {
            navigation
            drawer
        }
        .tint(.primary)
        .animation(.snappy, value: showingSidebar)
    }

    // MARK: Main content

    private var navigation: some View {
        NavigationStack {
            VStack(spacing: 0) {
                RunningTotalHeader(month: selectedMonth, total: total)
                Divider()
                if monthTransactions.isEmpty {
                    EmptyStateView()
                } else {
                    transactionList
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showingSidebar = true } label: {
                        Image(systemName: "line.3.horizontal")
                    }
                    .accessibilityLabel("Ledger history")
                }
            }
            .safeAreaInset(edge: .bottom) { addButton }
        }
        .sheet(isPresented: $showingAddSheet) {
            TransactionSheetView(
                mode: .add(defaultDate: Date()),
                repository: repository,
                recentSources: recentSources
            )
        }
        .sheet(isPresented: editingBinding) {
            if let editingTransaction {
                TransactionSheetView(
                    mode: .edit(editingTransaction),
                    repository: repository,
                    recentSources: recentSources
                )
            }
        }
        .confirmationDialog(
            "Delete this transaction?",
            isPresented: deleteBinding,
            titleVisibility: .visible,
            presenting: pendingDelete
        ) { transaction in
            Button("Delete", role: .destructive) { delete(transaction) }
            Button("Cancel", role: .cancel) {}
        } message: { transaction in
            Text("\(MoneyFormatter.display(transaction.data.amount)) · \(transaction.data.merchant ?? "—")")
        }
    }

    private var transactionList: some View {
        List {
            ForEach(monthTransactions, id: \.persistentModelID) { transaction in
                Button { editingTransaction = transaction } label: {
                    LedgerRowView(transaction: transaction)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) { pendingDelete = transaction } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    private var addButton: some View {
        Button("Add Transaction") { showingAddSheet = true }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.bar)
    }

    // MARK: History drawer

    @ViewBuilder private var drawer: some View {
        if showingSidebar {
            Color.black.opacity(0.25)
                .ignoresSafeArea()
                .onTapGesture { showingSidebar = false }
                .transition(.opacity)
            LedgerSidebarView(transactions: transactions, selectedMonth: selectedMonth) { month in
                selectedMonth = month
                showingSidebar = false
            }
            .frame(width: 300)
            .transition(.move(edge: .leading))
        }
    }

    // MARK: Actions

    private func delete(_ transaction: Transaction) {
        try? repository.delete(transaction)
        pendingDelete = nil
    }

    private var editingBinding: Binding<Bool> {
        Binding(get: { editingTransaction != nil }, set: { if !$0 { editingTransaction = nil } })
    }

    private var deleteBinding: Binding<Bool> {
        Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } })
    }
}
