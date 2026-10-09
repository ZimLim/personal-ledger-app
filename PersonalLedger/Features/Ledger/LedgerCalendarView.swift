import SwiftUI
import LedgerCore

/// Month calendar (plan Phase 6): every day of the viewed month with that day's
/// total of effective amounts. A day with nothing logged shows "RM 0.00".
struct LedgerCalendarView: View {
    let monthCalendar: MonthCalendar

    private static let cellSpacing: CGFloat = 4
    private static let cellCornerRadius: CGFloat = 8
    private static let cellMinHeight: CGFloat = 52
    private static let columns = Array(
        repeating: GridItem(.flexible(), spacing: cellSpacing),
        count: 7
    )

    /// Today's day number when the viewed month is the current one.
    private var today: Int? {
        let now = Date()
        guard YearMonth(date: now) == monthCalendar.month else { return nil }
        return Calendar.current.component(.day, from: now)
    }

    var body: some View {
        let today = today
        let blanks = monthCalendar.leadingBlanks
        let days = monthCalendar.days
        ScrollView {
            VStack(spacing: 12) {
                LazyVGrid(columns: Self.columns) {
                    ForEach(Array(MonthCalendar.weekdaySymbols().enumerated()), id: \.offset) { _, symbol in
                        Text(symbol)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                    }
                }
                // One ForEach over grid slots (blanks, then days): a lazy grid
                // drops cells when sibling ForEach blocks reuse the same IDs.
                LazyVGrid(columns: Self.columns, spacing: Self.cellSpacing) {
                    ForEach(0..<(blanks + days.count), id: \.self) { slot in
                        if slot < blanks {
                            Color.clear
                        } else {
                            dayCell(days[slot - blanks], isToday: days[slot - blanks].day == today)
                        }
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
        }
    }

    private func dayCell(_ day: DayTotal, isToday: Bool) -> some View {
        let amount = MoneyFormatter.displayEffective(day.total)
        let shape = RoundedRectangle(cornerRadius: Self.cellCornerRadius)
        return VStack(spacing: 4) {
            Text("\(day.day)")
                .font(.footnote)
                .fontWeight(isToday ? .bold : .regular)
            Text(amount)
                .font(.caption2)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .foregroundStyle(day.total == .zero ? .secondary : .primary)
        }
        .padding(.horizontal, 2)
        .frame(maxWidth: .infinity, minHeight: Self.cellMinHeight)
        .background(Color(.secondarySystemBackground), in: shape)
        .overlay {
            if isToday {
                shape.strokeBorder(Color.primary, lineWidth: 1.5)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(day.day) \(monthCalendar.month.monthName()), \(amount)\(isToday ? ", today" : "")")
    }
}
