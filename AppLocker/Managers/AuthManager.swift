// AuthManager.swift
// 密码 / FaceID 验证管理

import Foundation
import LocalAuthentication
import CommonCrypto

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var isPasswordSet: Bool = false
    /// Face ID 是否启用（同时检查系统层面是否真正可用）
    @Published private(set) var isFaceIDEnabled: Bool = false

    private let passwordHashKey = "AppLockerPasswordHash"
    private let passwordSaltKey = "AppLockerPasswordSalt"
    private let faceIDKey = "FaceIDEnabled"

    // 暴力破解保护
    private let maxAttemptsKey = "AuthFailedAttempts"
    private let lockoutTimeKey = "AuthLockoutUntil"
    private let maxAttempts = 5
    private let lockoutDuration: TimeInterval = 30 // 30 秒锁定

    private init() {
        load()
    }

    // MARK: - 密码管理

    /// 生成随机 Salt
    private func generateSalt() -> Data {
        Data((0..<16).map { _ in UInt8.random(in: 0...255) })
    }

    /// 使用 PBKDF2 计算密码哈希
    private func computeHash(password: String, salt: Data) -> String {
        let passwordData = password.data(using: .utf8)!
        var derivedKey = [UInt8](repeating: 0, count: 32)
        salt.withUnsafeBytes { saltBytes in
            passwordData.withUnsafeBytes { passwordBytes in
                _ = CCKeyDerivationPBKDF(
                    CCPBKDFAlgorithm(kCCPBKDF2),
                    passwordBytes.bindMemory(to: Int8.self).baseAddress,
                    passwordData.count,
                    saltBytes.bindMemory(to: UInt8.self).baseAddress,
                    salt.count,
                    CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                    10000,
                    &derivedKey,
                    32
                )
            }
        }
        return Data(derivedKey).base64EncodedString()
    }

    /// 设置密码（存储 PBKDF2 哈希值 + Salt）
    func setPassword(_ password: String) {
        let salt = generateSalt()
        let hash = computeHash(password: password, salt: salt)
        UserDefaults.standard.set(hash, forKey: passwordHashKey)
        UserDefaults.standard.set(salt.base64EncodedString(), forKey: passwordSaltKey)
        isPasswordSet = true
        resetFailedAttempts()
    }

    /// 验证密码（含暴力破解保护）
    func verifyPassword(_ input: String) -> Bool {
        // 检查是否处于锁定状态
        if isLockedOut() {
            return false
        }

        guard let storedHash = UserDefaults.standard.string(forKey: passwordHashKey),
              let saltString = UserDefaults.standard.string(forKey: passwordSaltKey),
              let saltData = Data(base64Encoded: saltString) else {
            return false
        }
        let inputHash = computeHash(password: input, salt: saltData)
        let success = inputHash == storedHash

        if success {
            resetFailedAttempts()
        } else {
            recordFailedAttempt()
        }
        return success
    }

    /// 清除密码
    func clearPassword() {
        UserDefaults.standard.removeObject(forKey: passwordHashKey)
        UserDefaults.standard.removeObject(forKey: passwordSaltKey)
        isPasswordSet = false
        resetFailedAttempts()
    }

    // MARK: - 暴力破解保护

    /// 是否处于锁定状态
    func isLockedOut() -> Bool {
        guard let lockoutUntil = UserDefaults.standard.object(forKey: lockoutTimeKey) as? Date else {
            return false
        }
        return Date() < lockoutUntil
    }

    /// 剩余锁定秒数
    var lockoutRemainingSeconds: Int {
        guard let lockoutUntil = UserDefaults.standard.object(forKey: lockoutTimeKey) as? Date else {
            return 0
        }
        return max(0, Int(lockoutUntil.timeIntervalSince(Date())))
    }

    /// 已失败尝试次数
    var failedAttempts: Int {
        UserDefaults.standard.integer(forKey: maxAttemptsKey)
    }

    private func recordFailedAttempt() {
        let attempts = failedAttempts + 1
        UserDefaults.standard.set(attempts, forKey: maxAttemptsKey)
        if attempts >= maxAttempts {
            let lockoutUntil = Date().addingTimeInterval(lockoutDuration)
            UserDefaults.standard.set(lockoutUntil, forKey: lockoutTimeKey)
        }
    }

    private func resetFailedAttempts() {
        UserDefaults.standard.removeObject(forKey: maxAttemptsKey)
        UserDefaults.standard.removeObject(forKey: lockoutTimeKey)
    }

    // MARK: - Face ID 管理

    /// Face ID 是否可用（硬件支持）
    var isFaceIDAvailable: Bool {
        let context = LAContext()
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    /// Face ID 是否真正启用（同时检查系统层面是否真正可用）
    func checkFaceIDEnabled() -> Bool {
        guard UserDefaults.standard.bool(forKey: faceIDKey) else { return false }
        return isFaceIDAvailable
    }

    /// 启用 Face ID（需要先验证）
    func enableFaceID() async -> Bool {
        let context = LAContext()
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: NSLocalizedString("auth_faceid_enable_reason", comment: "")
            )
            if success {
                UserDefaults.standard.set(true, forKey: faceIDKey)
                isFaceIDEnabled = true
            }
            return success
        } catch {
            return false
        }
    }

    /// 禁用 Face ID
    func disableFaceID() {
        UserDefaults.standard.set(false, forKey: faceIDKey)
        isFaceIDEnabled = false
    }

    /// 验证 Face ID
    func verifyBiometric(reason: String = NSLocalizedString("auth_faceid_verify_reason", comment: "")) async -> Bool {
        let context = LAContext()
        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
        } catch {
            return false
        }
    }

    /// 验证密码或 Face ID（按优先级）
    func verifyAny() async -> Bool {
        if checkFaceIDEnabled() {
            if await verifyBiometric() {
                return true
            }
            // Face ID 失败，回退到密码
        }
        return false  // 密码验证在 UI 层完成（需要输入）
    }

    // MARK: - 持久化

    private func load() {
        isPasswordSet = UserDefaults.standard.string(forKey: passwordHashKey) != nil
        isFaceIDEnabled = checkFaceIDEnabled()
    }
}
