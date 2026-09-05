import Foundation

enum AutoDisarmDuration: Int, CaseIterable, Sendable {
    case eightHours = 28800
    case twelveHours = 43200
    case untilManual = -1

    var label: String {
        switch self {
        case .eightHours: "8 hours"
        case .twelveHours: "12 hours"
        case .untilManual: "Until I disarm"
        }
    }
}

struct AutoDisarmManager: @unchecked Sendable {
    private let defaults: UserDefaults

    private static let armTimestampKey = "autoDisarm_armTimestamp"
    private static let durationKey = "autoDisarm_duration"
    private static let selectedPresetKey = "autoDisarm_selectedPreset"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var selectedPreset: AutoDisarmDuration {
        get {
            let raw = defaults.integer(forKey: Self.selectedPresetKey)
            return AutoDisarmDuration(rawValue: raw) ?? .eightHours
        }
        nonmutating set {
            defaults.set(newValue.rawValue, forKey: Self.selectedPresetKey)
        }
    }

    func recordArm() {
        defaults.set(Date().timeIntervalSince1970, forKey: Self.armTimestampKey)
        defaults.set(selectedPreset.rawValue, forKey: Self.durationKey)
    }

    func clearArm() {
        defaults.removeObject(forKey: Self.armTimestampKey)
        defaults.removeObject(forKey: Self.durationKey)
    }

    func armTimestamp() -> Date? {
        let value = defaults.double(forKey: Self.armTimestampKey)
        guard value > 0 else { return nil }
        return Date(timeIntervalSince1970: value)
    }

    func isExpired() -> Bool {
        guard let timestamp = armTimestamp() else { return false }
        let duration = defaults.integer(forKey: Self.durationKey)
        if duration == AutoDisarmDuration.untilManual.rawValue { return false }
        guard duration > 0 else { return true }
        return Date().timeIntervalSince(timestamp) >= Double(duration)
    }

    func expiryDate() -> Date? {
        guard let timestamp = armTimestamp() else { return nil }
        let duration = defaults.integer(forKey: Self.durationKey)
        if duration == AutoDisarmDuration.untilManual.rawValue { return nil }
        guard duration > 0 else { return nil }
        return timestamp.addingTimeInterval(Double(duration))
    }

    func remainingSeconds() -> Int? {
        guard let expiry = expiryDate() else { return nil }
        let remaining = expiry.timeIntervalSinceNow
        return remaining > 0 ? Int(remaining) : 0
    }
}
