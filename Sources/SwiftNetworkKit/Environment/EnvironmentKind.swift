/// Which deployment an environment represents.
public enum EnvironmentKind: String, Sendable, CaseIterable {
    case development
    case qa
    case staging
    case production
}
