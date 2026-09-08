import SwiftUI

/// A list section whose header shows a count once loaded; a spinner while loading; the error inline.
struct CountedSection<Element: Sendable, Rows: View>: View {
    let title: String
    let phase: LoadPhase<[Element]>
    @ViewBuilder let rows: ([Element]) -> Rows

    init(_ title: String, phase: LoadPhase<[Element]>, @ViewBuilder rows: @escaping ([Element]) -> Rows) {
        self.title = title
        self.phase = phase
        self.rows = rows
    }

    var body: some View {
        Section {
            switch phase {
            case .idle, .loading:
                ProgressView()
            case .loaded(let list):
                rows(list)
            case .failed(let error):
                Text(error.localizedDescription).font(.callout).foregroundStyle(.red)
            }
        } header: {
            HStack {
                Text(title)
                if case .loaded(let list) = phase {
                    Text("\(list.count)").foregroundStyle(.secondary)
                }
            }
        }
    }
}
