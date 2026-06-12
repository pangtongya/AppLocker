// AuthManager.swift
// 密码 / FaceID 验证管理

import Foundation
import LocalAuthentication
import CryptoKit

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var isPasswordSet: Bool = false
    @Published var isFaceIDEnabled: Bool = false

    private let passwordHashKey = "AppLockerPasswordHash"
    private let passwordSaltKey = "AppLockerPasswordSalt"
    private let faceIDKey = "FaceIDEnabled"

    private init() {
        load()
    }

    // MARK: - 密码管理

    /// 生成随机 Salt
    private func generateSalt() -> String {
        let saltData = Data((0..<16).map { _ in UInt8.random(in: 0...255) })
        return saltData.base64EncodedString()
    }

    /// 计算密码哈希 (SHA256(password + salt))
    private func computeHash(password: String, salt: String) -> String {
        let combined = password + salt
        let data = Data(combined.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }

    /// 设置密码（存储 SHA256 哈希值 + Salt）
    func setPassword(_ password: String) {
        let salt = generateSalt()
        let hash = computeHash(password: password, salt: salt)
        UserDefaults.standard.set(hash, forKey: passwordHashKey)
        UserDefaults.standard.set(salt, forKey: passwordSaltKey)
        isPasswordSet = true
    }

    /// 验证密码
    func verifyPassword(_ input: String) -> Bool {
        guard let storedHash = UserDefaults.standard.string(forKey: passwordHashKey),
              let salt = UserDefaults.standard.string(forKey: passwordSaltKey) else {
            return false
        }
        let inputHash = computeHash(password: input, salt: salt)
        return inputHash == storedHash
    }

    /// 清除密码
    func clearPassword() {
        UserDefaults.standard.removeObject(forKey: passwordHashKey)
        UserDefaults.standard.removeObject(forKey: passwordSaltKey)
        isPasswordSet = false
    }

    // MARK: - Face ID 管理

    /// Face ID 是否可用（硬件支持）
    var isFaceIDAvailable: Bool {
        let context = LAContext()
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    /// 启用 Face ID（需要先验证）
    func enableFaceID() async -> Bool {
        let context = LAContext()
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "启用 Face ID 保护"
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
    func verifyBiometric(reason: String = "验证身份以解锁") async -> Bool {
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
        if isFaceIDEnabled {
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
        isFaceIDEnabled = UserDefaults.standard.bool(forKey: faceIDKey)
    }
}
