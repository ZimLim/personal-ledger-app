import SwiftUI

/// Quick-pick chips of recently used sources (RFC §FR-2), derived from existing
/// data — no separate table. Tapping a chip fills the Source field.
struct SourceChips: View {
    let sources: [String]
    let onSelect: (String) -> Void

    var body: some View {
        if !sources.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(sources, id: \.self) { source in
                        Button(source) { onSelect(source) }
                            .buttonStyle(.bordered)
                            .font(.caption)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}
