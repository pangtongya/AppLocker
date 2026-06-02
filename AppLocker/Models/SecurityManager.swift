import Foundation
import LocalAuthentication

@MainActor
@Observable
final class SecurityManager {
    static let shared = SecurityManager()
    
    var isFaceIDEnabled = false
    
    var isPasswordSet: Bool {
        UserDefaults.standard.string(forKey: "AppLockerPassword") != nil
    }
    
    private init() {
        isFaceIDEnabled = UserDefaults.standard.bool(forKey: "FaceIDEnabled")
    }
    
    func setPassword(_ password: String) {
        UserDefaults.standard.set(password, forKey: "AppLockerPassword")
    }
    
    func verifyPassword(_ password: String) -> Bool {
        UserDefaults.standard.string(forKey: "AppLockerPassword") == password
    }
    
    func enableFaceID() async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            print("Face ID not available: \(error?.localizedDescription ?? "unknown error")")
            return false
        }
        
        do {
            let result = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "使用Face ID保护应用锁"
            )
            if result {
                UserDefaults.standard.set(true, forKey: "FaceIDEnabled")
                isFaceIDEnabled = true
            }
            return result
        } catch {
            print("Face ID authentication failed: \(error)")
            return false
        }
    }
    
    func disableFaceID() {
        UserDefaults.standard.set(false, forKey: "FaceIDEnabled")
        isFaceIDEnabled = false
    }
    
    func authenticateWithFaceID() async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            print("Face ID not available: \(error?.localizedDescription ?? "unknown error")")
            return false
        }
        
        do {
            let result = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "使用Face ID解锁应用"
            )
            return result
        } catch {
            print("Face ID authentication failed: \(error)")
            return false
        }
    }
    
    func isSecuritySetUp() -> Bool {
        isPasswordSet || isFaceIDEnabled
    }
}
