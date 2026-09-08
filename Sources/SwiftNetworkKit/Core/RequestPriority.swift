/// Relative scheduling hint for the request queue (M9). Best-effort — running requests aren't preempted.
public enum RequestPriority: Sendable, Comparable {
    case low
    case normal
    case high
}
