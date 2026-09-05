import XCTest
@testable import WakeCapture

final class AutoDisarmManagerTests: XCTestCase {
    private var defaults: UserDefaults!
    private var sut: AutoDisarmManager!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "AutoDisarmManagerTests")!
        defaults.removePersistentDomain(forName: "AutoDisarmManagerTests")
        sut = AutoDisarmManager(defaults: defaults)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "AutoDisarmManagerTests")
        super.tearDown()
    }

    func test_selectedPreset_defaultsToEightHours() {
        XCTAssertEqual(sut.selectedPreset, .eightHours)
    }

    func test_selectedPreset_persists() {
        sut.selectedPreset = .twelveHours
        let fresh = AutoDisarmManager(defaults: defaults)
        XCTAssertEqual(fresh.selectedPreset, .twelveHours)
    }

    func test_recordArm_writesTimestamp() {
        XCTAssertNil(sut.armTimestamp())
        sut.recordArm()
        XCTAssertNotNil(sut.armTimestamp())
    }

    func test_clearArm_removesTimestamp() {
        sut.recordArm()
        sut.clearArm()
        XCTAssertNil(sut.armTimestamp())
    }

    func test_isExpired_returnsFalseWhenNotArmed() {
        XCTAssertFalse(sut.isExpired())
    }

    func test_isExpired_returnsFalseBeforeDuration() {
        sut.selectedPreset = .eightHours
        sut.recordArm()
        XCTAssertFalse(sut.isExpired())
    }

    func test_isExpired_returnsTrueAfterDuration() {
        sut.selectedPreset = .eightHours
        let pastTimestamp = Date().addingTimeInterval(-28801).timeIntervalSince1970
        defaults.set(pastTimestamp, forKey: "autoDisarm_armTimestamp")
        defaults.set(AutoDisarmDuration.eightHours.rawValue, forKey: "autoDisarm_duration")
        XCTAssertTrue(sut.isExpired())
    }

    func test_isExpired_untilManual_neverExpires() {
        sut.selectedPreset = .untilManual
        let pastTimestamp = Date().addingTimeInterval(-100000).timeIntervalSince1970
        defaults.set(pastTimestamp, forKey: "autoDisarm_armTimestamp")
        defaults.set(AutoDisarmDuration.untilManual.rawValue, forKey: "autoDisarm_duration")
        XCTAssertFalse(sut.isExpired())
    }

    func test_remainingSeconds_returnsNilWhenUntilManual() {
        sut.selectedPreset = .untilManual
        sut.recordArm()
        XCTAssertNil(sut.remainingSeconds())
    }

    func test_remainingSeconds_calculatesCorrectly() {
        sut.selectedPreset = .eightHours
        let oneHourAgo = Date().addingTimeInterval(-3600).timeIntervalSince1970
        defaults.set(oneHourAgo, forKey: "autoDisarm_armTimestamp")
        defaults.set(AutoDisarmDuration.eightHours.rawValue, forKey: "autoDisarm_duration")

        let remaining = sut.remainingSeconds()!
        XCTAssertTrue(remaining > 25100 && remaining < 25300)
    }

    func test_remainingSeconds_returnsZeroWhenExpired() {
        sut.selectedPreset = .eightHours
        let pastTimestamp = Date().addingTimeInterval(-28801).timeIntervalSince1970
        defaults.set(pastTimestamp, forKey: "autoDisarm_armTimestamp")
        defaults.set(AutoDisarmDuration.eightHours.rawValue, forKey: "autoDisarm_duration")
        XCTAssertEqual(sut.remainingSeconds(), 0)
    }

    func test_expiryDate_returnsNilForUntilManual() {
        sut.selectedPreset = .untilManual
        sut.recordArm()
        XCTAssertNil(sut.expiryDate())
    }

    func test_expiryDate_returnsCorrectDate() {
        sut.selectedPreset = .eightHours
        sut.recordArm()
        let expiry = sut.expiryDate()!
        let expected = Date().addingTimeInterval(28800)
        XCTAssertTrue(abs(expiry.timeIntervalSince(expected)) < 2)
    }
}
