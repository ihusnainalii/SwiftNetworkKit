import SwiftUI

struct UserRow: View {
    let user: User

    var body: some View {
        HStack(spacing: 12) {
            Text(initials)
                .font(.headline)
                .frame(width: 40, height: 40)
                .background(.tint.opacity(0.15), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(user.name).font(.headline)
                Text("@\(user.username) · \(user.company.name)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }

    private var initials: String {
        user.name.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined()
    }
}
