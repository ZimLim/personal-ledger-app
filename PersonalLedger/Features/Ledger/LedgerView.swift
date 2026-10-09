import SwiftUI
import SwiftData
import LedgerCore

/// Landing screen (RFC §FR-1): the selected month's ledger with a pinned running
/// total, reverse-chronological list, a always-visible Add button, a history
/// drawer, and two-step delete. A toolbar toggle swaps the list for a calendar
/// of daily totals (plan Phase 6).
struct LedgerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]

    @State private var selectedMonth = YearMonth(date: Date())
    @State private var showingSidebar = false
    @State private var showingAddSheet = false
    @State private var showingSettings = false
    @State private var showingCalendar = false
    @State private var editingTransaction: Transaction?
    @State private var pendingDelete: Transaction?
    @State private var selectedSource: String?
    @State private var sort: LedgerSort = .default

    private var repository: SwiftDataTransactionRepository {
        SwiftDataTransactionRepository(context: modelContext)
    }

    private var monthTransactions: [Transaction] {
        transactions.filter { YearMonth(date: $0.date) == selectedMonth }
    }

    /// Month transactions after the payment-method filter + chosen sort (#1).
    private var visibleTransactions: [Transaction] {
        let models = monthTransactions
        let byID = Dictionary(models.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return LedgerQuery.visible(models.map(\.data), source: selectedSource, sort: sort)
            .compactMap { byID[$0.id] }
    }

    private var monthSources: [String] {
        LedgerQuery.distinctSources(in: monthTransactions.map(\.data))
    }

    private var isFiltering: Bool { selectedSource != nil || sort != .default }

    /// Running total reflects the current filter (equals the month total when unfiltered).
    private var total: Decimal {
        LedgerTotals.total(of: visibleTransactions.map(\.data))
    }

    /// Daily totals for the calendar. Honours the payment-method filter so the
    /// days add up to the running total (plan Phase 6).
    private var monthCalendar: MonthCalendar {
        MonthCalendar(
            month: selectedMonth,
            transactions: LedgerQuery.filter(source: selectedSource, in: monthTransactions.map(\.data))
        )
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

    /// Recently used merchants, most-recent first, for the Add form's chips (#6).
    private var recentMerchants: [String] {
        var seen = Set<String>()
        var result: [String] = []
        for transaction in transactions {
            guard let merchant = transaction.merchant, !merchant.isEmpty,
                  seen.insert(merchant).inserted else { continue }
            result.append(merchant)
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
                if showingCalendar {
                    LedgerCalendarView(monthCalendar: monthCalendar)
                } else if monthTransactions.isEmpty {
                    EmptyStateView()
                } else if visibleTransactions.isEmpty {
                    EmptyStateView(message: "No transactions match this filter")
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
                ToolbarItem(placement: .topBarTrailing) {
                    filterSortMenu
                }
                ToolbarItem(placement: .topBarTrailing) {
                    calendarToggle
                }
            }
            .safeAreaInset(edge: .bottom) { addButton }
        }
        .sheet(isPresented: $showingAddSheet) {
            TransactionSheetView(
                mode: .add(defaultDate: Date()),
                repository: repository,
                recentSources: recentSources,
                recentMerchants: recentMerchants
            )
        }
        .sheet(isPresented: editingBinding) {
            if let editingTransaction {
                TransactionSheetView(
                    mode: .edit(editingTransaction),
                    repository: repository,
                    recentSources: recentSources,
                    recentMerchants: recentMerchants
                )
            }
        }
        .sheet(isPresented: $showingSettings) { SettingsView() }
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

    private var filterSortMenu: some View {
        Menu {
            Picker("Sort", selection: $sort) {
                ForEach(LedgerSort.allCases, id: \.self) { option in
                    Text(option.label).tag(option)
                }
            }
            Picker("Payment method", selection: $selectedSource) {
                Text("All methods").tag(String?.none)
                ForEach(monthSources, id: \.self) { source in
                    Text(source).tag(String?.some(source))
                }
            }
        } label: {
            Image(systemName: isFiltering
                  ? "line.3.horizontal.decrease.circle.fill"
                  : "line.3.horizontal.decrease.circle")
        }
        .accessibilityLabel("Filter and sort")
    }

    private var calendarToggle: some View {
        Button { showingCalendar.toggle() } label: {
            Image(systemName: showingCalendar ? "list.bullet" : "calendar")
        }
        .accessibilityLabel(showingCalendar ? "Show list" : "Show calendar")
    }

    private var transactionList: some View {
        List {
            ForEach(visibleTransactions, id: \.persistentModelID) { transaction in
                LedgerRowView(transaction: transaction)
                    .contentShape(Rectangle())
                    .onTapGesture { editingTransaction = transaction }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) { pendingDelete = transaction } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        .tint(.destructiveSwipe)
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
            LedgerSidebarView(
                transactions: transactions,
                selectedMonth: selectedMonth,
                onSelect: { month in
                    selectedMonth = month
                    showingSidebar = false
                },
                onOpenSettings: {
                    showingSidebar = false
                    showingSettings = true
                }
            )
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
