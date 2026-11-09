import Foundation
import Security
import LocalAuthentication

public enum KeychainError: Error, Sendable {
    case itemNotFound
    case duplicateItem
    case unexpectedData
    case unhandledError(status: OSStatus)
}

public final class KeychainManager: @unchecked Sendable {
    public static let shared = KeychainManager()
    private let serviceName = "com.pipsey.companion"
    private let lock = NSLock()
    private var memoryCache: [String: String] = [:]
    private var hasQueried: Set<String> = []

    public init() {}

    public func saveSecret(account: String, secret: String) throws {
        lock.lock()
        memoryCache[account] = secret
        hasQueried.insert(account)
        lock.unlock()

        guard let data = secret.data(using: .utf8) else { return }

        // Try deleting existing item first to avoid duplicates
        _ = deleteSecretFromSystem(account: account)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }

    public func readSecret(account: String) -> String? {
        lock.lock()
        if hasQueried.contains(account) {
            let cached = memoryCache[account]
            lock.unlock()
            return cached
        }
        lock.unlock()

        let authContext = LAContext()
        authContext.interactionNotAllowed = true

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecUseAuthenticationContext as String: authContext
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        lock.lock()
        hasQueried.insert(account)
        if status == errSecSuccess, let data = item as? Data, let str = String(data: data, encoding: .utf8) {
            memoryCache[account] = str
            lock.unlock()
            return str
        } else {
            memoryCache.removeValue(forKey: account)
            lock.unlock()
            return nil
        }
    }

    @discardableResult
    public func deleteSecret(account: String) -> Bool {
        lock.lock()
        memoryCache.removeValue(forKey: account)
        hasQueried.insert(account)
        lock.unlock()

        return deleteSecretFromSystem(account: account)
    }

    private func deleteSecretFromSystem(account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess
    }

    public func clearCache() {
        lock.lock()
        memoryCache.removeAll()
        hasQueried.removeAll()
        lock.unlock()
    }
}
