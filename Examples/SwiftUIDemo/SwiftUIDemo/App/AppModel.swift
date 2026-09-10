import Observation

/// Owns the settings store and the `NetworkClient`-backed container, rebuilding the container
/// whenever settings are applied.
@MainActor
@Observable
final class AppModel {
    let settings = SettingsStore()
    private(set) var container: AppContainer

    init() {
        container = AppContainer.make(from: settings.applied)
    }

    /// Persist `new` and rebuild the container so every screen picks up the change.
    func apply(_ new: DemoSettings) {
        settings.commit(new)
        container = AppContainer.make(from: settings.applied)
    }

    func resetToDefaults() {
        settings.reset()
        container = AppContainer.make(from: settings.applied)
    }
}
