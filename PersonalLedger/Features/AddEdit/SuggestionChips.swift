import SwiftUI

/// Horizontal quick-pick chips of recently used values (sources, merchants…),
/// derived from existing data — no separate table (RFC §FR-2, improvement #6).
/// Tapping a chip fills the associated field.
struct SuggestionChips: View {
    let values: [String]
    let onSelect: (String) -> Void

    var body: some View {
        if !values.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(values, id: \.self) { value in
                        Button(value) { onSelect(value) }
                            .buttonStyle(.bordered)
                            .font(.caption)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}
