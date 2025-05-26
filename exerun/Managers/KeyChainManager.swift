//
//  KeychainManager.swift
//  exerun
//
//  Created by Nazar Odemchuk on 16/4/2025.
//

import Security
import Foundation

struct KeychainManager {
    static let shared = KeychainManager()
    private init() {}

    // MARK: – Config
    private let tokenKey = "exerun.authToken"
    private let lifetime: TimeInterval = 60 * 60 * 24 * 365 * 3 - 1   // 3 years

    // Internal wrapper that we actually store
    private struct Stored: Codable {
        let token: String
        let exp: TimeInterval      // UNIX epoch seconds
    }

    // MARK: – Public API
    func saveToken(_ token: String) {
        let expires = Date().addingTimeInterval(lifetime).timeIntervalSince1970
        guard
            let data = try? JSONEncoder().encode(Stored(token: token, exp: expires))
        else { return }

        // Remove any existing entry first
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: tokenKey
        ] as CFDictionary
        SecItemDelete(query)

        let attributes = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: tokenKey,
            kSecValueData: data
        ] as CFDictionary

        SecItemAdd(attributes, nil)
    }

    /// Returns the token if still valid; otherwise removes it and returns `nil`.
    func loadToken() -> String? {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: tokenKey,
            kSecReturnData: true,
            kSecMatchLimit: kSecMatchLimitOne
        ] as CFDictionary

        var dataRef: AnyObject?
        let status = SecItemCopyMatching(query, &dataRef)
        guard
            status == errSecSuccess,
            let data = dataRef as? Data,
            let stored = try? JSONDecoder().decode(Stored.self, from: data)
        else { return nil }

        // Expired?
        if Date().timeIntervalSince1970 > stored.exp {
            deleteToken()
            return nil
        }
        return stored.token
    }

    func deleteToken() {
        let query = [
            kSecClass: kSecClassGenericPassword,
            kSecAttrAccount: tokenKey
        ] as CFDictionary
        SecItemDelete(query)
    }
}
