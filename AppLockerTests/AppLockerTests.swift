import XCTest
@testable import AppLocker

@MainActor
final class AppLockerTests: XCTestCase {

    var lockStore: LockStore!
    var authManager: AuthManager!

    override func setUp() {
        super.setUp()
        lockStore = LockStore.shared
        lockStore.history = []
        lockStore.save()
        authManager = AuthManager.shared
    }

    override func tearDown() {
        lockStore.history = []
        lockStore.save()
        authManager.clearPassword()
        authManager.disableFaceID()
        lockStore = nil
        authManager = nil
        super.tearDown()
    }

    // MARK: - LockSession Model Tests

    func testLockSessionCreation() {
        let session = LockSession(plannedMinutes: 25, appCount: 3)
        XCTAssertEqual(session.plannedMinutes, 25)
        XCTAssertEqual(session.appCount, 3)
        XCTAssertFalse(session.isCompleted)
        XCTAssertFalse(session.wasCompleted)
        XCTAssertFalse(session.wasEarlyUnlocked)
    }

    func testLockSessionActualMinutes() {
        let session = LockSession(
            startedAt: Date().addingTimeInterval(-1800),
            endedAt: Date(),
            plannedMinutes: 30
        )
        XCTAssertGreaterThan(session.actualMinutes, 28)
        XCTAssertLessThan(session.actualMinutes, 32)
    }

    func testLockSessionRemainingSeconds() {
        let session = LockSession(plannedMinutes: 25)
        // 刚创建，剩余时间应该接近 25*60
        let remaining = session.remainingSeconds
        XCTAssertGreaterThan(remaining, 24 * 60)
        XCTAssertLessThanOrEqual(remaining, 25 * 60)
    }

    func testLockSessionIsExpired() {
        let session = LockSession(
            startedAt: Date().addingTimeInterval(-3600), // 1小时前
            plannedMinutes: 25 // 25 分钟的计划
        )
        XCTAssertTrue(session.isExpired)
    }

    func testLockSessionFormattedRemaining() {
        let session = LockSession(plannedMinutes: 25)
        let formatted = session.formattedRemaining
        XCTAssertTrue(formatted.contains(":"))
        XCTAssertEqual(formatted.count, 5) // "MM:SS"
    }

    func testLockSessionCompletionRate() {
        let session = LockSession(
            startedAt: Date().addingTimeInterval(-1800),
            endedAt: Date(),
            plannedMinutes: 30
        )
        XCTAssertGreaterThan(session.completionRate, 0.9)
        XCTAssertLessThanOrEqual(session.completionRate, 1.0)
    }

    // MARK: - LockStore Tests

    func testLockStoreInitialization() {
        let store = LockStore.shared
        XCTAssertNotNil(store)
    }

    func testLockStoreStartLock() {
        lockStore.history = []
        lockStore.startLock(plannedMinutes: 25, appCount: 3)

        XCTAssertTrue(lockStore.isLocking)
        XCTAssertNotNil(lockStore.currentSession)
        XCTAssertEqual(lockStore.currentSession?.plannedMinutes, 25)
        XCTAssertEqual(lockStore.currentSession?.appCount, 3)

        // Cleanup
        lockStore.cancelLock()
    }

    func testLockStoreManualUnlock() {
        lockStore.history = []
        lockStore.startLock(plannedMinutes: 25, appCount: 2)
        XCTAssertTrue(lockStore.isLocking)

        lockStore.unlockManually()
        XCTAssertFalse(lockStore.isLocking)
        XCTAssertNil(lockStore.currentSession)
        XCTAssertEqual(lockStore.history.count, 1)
        XCTAssertTrue(lockStore.history.first!.wasEarlyUnlocked)
    }

    func testLockStoreCancelLock() {
        lockStore.history = []
        lockStore.startLock(plannedMinutes: 25, appCount: 2)
        XCTAssertTrue(lockStore.isLocking)

        lockStore.cancelLock()
        XCTAssertFalse(lockStore.isLocking)
        XCTAssertNil(lockStore.currentSession)
        XCTAssertEqual(lockStore.history.count, 0) // Cancel 不记录历史
    }

    func testLockStoreCompleteLock() {
        lockStore.history = []
        // 创建一个已经到期的锁定
        lockStore.startLock(plannedMinutes: 25, appCount: 2)
        // 模拟时间已过：修改 currentSession
        if var session = lockStore.currentSession {
            session = LockSession(
                startedAt: Date().addingTimeInterval(-3600),
                plannedMinutes: 25,
                appCount: 2
            )
            lockStore.currentSession = session
        }

        lockStore.completeLock()

        XCTAssertFalse(lockStore.isLocking)
        XCTAssertNil(lockStore.currentSession)
        XCTAssertEqual(lockStore.history.count, 1)
        XCTAssertTrue(lockStore.history.first!.wasCompleted)
    }

    // MARK: - Statistics Tests

    func testLockStoreWeekTotalMinutes() {
        lockStore.history = []

        // 添加本周的测试数据
        let today = Date()
        let session1 = LockSession(
            startedAt: today.addingTimeInterval(-3600),
            endedAt: today.addingTimeInterval(-1800),
            plannedMinutes: 30,
            appCount: 2
        )
        let session2 = LockSession(
            startedAt: today.addingTimeInterval(-1800),
            endedAt: today,
            plannedMinutes: 30,
            appCount: 3
        )

        lockStore.history = [session1, session2]
        let weekMinutes = lockStore.weekTotalMinutes
        XCTAssertGreaterThan(weekMinutes, 0)
    }

    func testLockStoreCurrentStreak() {
        let calendar = Calendar.current
        let today = Date()

        // 创建连续3天的数据
        let session1 = LockSession(
            startedAt: today,
            endedAt: today.addingTimeInterval(1800),
            plannedMinutes: 30,
            appCount: 2
        )

        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let session2 = LockSession(
            startedAt: yesterday,
            endedAt: yesterday.addingTimeInterval(1800),
            plannedMinutes: 30,
            appCount: 2
        )

        let dayBeforeYesterday = calendar.date(byAdding: .day, value: -2, to: today)!
        let session3 = LockSession(
            startedAt: dayBeforeYesterday,
            endedAt: dayBeforeYesterday.addingTimeInterval(1800),
            plannedMinutes: 30,
            appCount: 2
        )

        lockStore.history = [session1, session2, session3]
        XCTAssertEqual(lockStore.currentStreak, 3)
    }

    // MARK: - AuthManager Tests

    func testAuthManagerInitialState() {
        XCTAssertFalse(authManager.isPasswordSet)
        XCTAssertFalse(authManager.isFaceIDEnabled)
    }

    func testAuthManagerSetAndVerifyPassword() {
        authManager.setPassword("1234")
        XCTAssertTrue(authManager.isPasswordSet)
        XCTAssertTrue(authManager.verifyPassword("1234"))
        XCTAssertFalse(authManager.verifyPassword("wrong"))
    }

    func testAuthManagerClearPassword() {
        authManager.setPassword("1234")
        XCTAssertTrue(authManager.isPasswordSet)

        authManager.clearPassword()
        XCTAssertFalse(authManager.isPasswordSet)
        XCTAssertFalse(authManager.verifyPassword("1234"))
    }

    func testAuthManagerFaceIDState() {
        XCTAssertFalse(authManager.isFaceIDEnabled)
        authManager.disableFaceID()
        XCTAssertFalse(authManager.isFaceIDEnabled)
    }

    // MARK: - Codable Tests

    func testLockSessionCodable() throws {
        let session = LockSession(plannedMinutes: 25, appCount: 2)
        let data = try JSONEncoder().encode(session)
        let decoded = try JSONDecoder().decode(LockSession.self, from: data)

        XCTAssertEqual(decoded.id, session.id)
        XCTAssertEqual(decoded.plannedMinutes, session.plannedMinutes)
        XCTAssertEqual(decoded.appCount, session.appCount)
    }

    // MARK: - Performance Tests

    func testPerformanceStatsCalculation() {
        var sessions: [LockSession] = []
        for i in 0..<100 {
            let session = LockSession(
                startedAt: Date().addingTimeInterval(-Double(i) * 86400),
                endedAt: Date().addingTimeInterval(-Double(i) * 86400 + 1800),
                plannedMinutes: 30,
                appCount: 2
            )
            sessions.append(session)
        }
        lockStore.history = sessions

        self.measure {
            _ = lockStore.todayTotalMinutes
            _ = lockStore.weekTotalMinutes
            _ = lockStore.currentStreak
            _ = lockStore.longestStreak
        }
    }
}
