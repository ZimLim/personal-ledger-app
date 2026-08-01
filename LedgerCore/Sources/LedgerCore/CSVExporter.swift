import Foundation

/// Generates CSV per RFC §FR-5. Columns:
/// `date,amount,currency,type,category,source,merchant,entry_method`
///  - `amount` is the **effective (signed)** value so spreadsheet sums are correct
///  - dates are ISO-8601 `YYYY-MM-DD` in the given calendar's timezone
///  - free-text fields (source, merchant) use RFC 4180 quoting/escaping
public enum CSVExporter {

    public static let header = "date,amount,currency,type,category,source,merchant,entry_method"

    /// Build the full CSV document. Rows are emitted in the order given; callers
    /// pass pre-sorted transactions (export-all sorts ascending — see `sortedForExport`).
    public static func export(
        _ transactions: [TransactionData],
        calendar: Calendar = .current
    ) -> String {
        // Build one timezone-configured formatter for the whole document rather
        // than sharing mutable state across calls (Swift 6 concurrency-safe).
        let iso = makeISOFormatter(timeZone: calendar.timeZone)
        return ([header] + transactions.map { row(for: $0, iso: iso) })
            .joined(separator: "\n")
    }

    /// Ascending by date, then by creation time for stable ordering within a day
    /// (RFC §FR-5 export-all is "sorted by date ascending").
    public static func sortedForExport(_ transactions: [TransactionData]) -> [TransactionData] {
        transactions.sorted {
            $0.date != $1.date ? $0.date < $1.date : $0.createdAt < $1.createdAt
        }
    }

    // MARK: Filenames

    /// `spending-YYYY-MM.csv` for a single month (RFC §FR-5).
    public static func monthFilename(for month: YearMonth) -> String {
        String(format: "spending-%04d-%02d.csv", month.year, month.month)
    }

    /// `spending-all-YYYYMMDD.csv` for the export-all action (RFC §FR-5).
    public static func allFilename(on date: Date = Date(), calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "spending-all-%04d%02d%02d.csv", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    // MARK: Row building

    private static func row(for t: TransactionData, iso: DateFormatter) -> String {
        [
            iso.string(from: t.date),
            Money.csvString(t.effectiveAmount),
            t.currencyCode,
            t.kind.rawValue,
            t.category,
            escape(t.source),
            escape(t.merchant ?? ""),
            t.entryMethod.rawValue,
        ].joined(separator: ",")
    }

    /// RFC 4180: quote a field if it contains a comma, double-quote, CR, or LF;
    /// escape embedded double-quotes by doubling them.
    static func escape(_ field: String) -> String {
        guard field.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" || $0 == "\r" }) else {
            return field
        }
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    private static func makeISOFormatter(timeZone: TimeZone) -> DateFormatter {
        let f = DateFormatter()
        f.locale = Money.posix
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = timeZone
        return f
    }
}
