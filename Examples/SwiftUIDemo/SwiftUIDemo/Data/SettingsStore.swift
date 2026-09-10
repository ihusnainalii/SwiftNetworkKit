import Foundation
import Observation

/// Loads/saves ``DemoSettings`` to `UserDefaults`. Edits are held in `draft`; `commit()` persists
/// them and bumps `revision` so the app can rebuild its `NetworkClient`.
@MainActor
@Observable
final class SettingsStore {
    private let key = "demo.settings.v1"
    private let defaults = UserDefaults.standard

    /// The applied settings the current `NetworkClient` was built from.
    private(set) var applied: DemoSettings
    /// Bumped on every `commit()` so views keyed on it re-create with the new container.
    private(set) var revision = 0

    init() {
        if let data = defaults.data(forKey: key),
            let decoded = try? JSONDecoder().decode(DemoSettings.self, from: data) {
            applied = decoded
        } else {
            applied = .default
        }
    }

    func commit(_ new: DemoSettings) {
        applied = new
        revision += 1
        if let data = try? JSONEncoder().encode(new) {
            defaults.set(data, forKey: key)
        }
    }

    func reset() {
        commit(.default)
    }
}
