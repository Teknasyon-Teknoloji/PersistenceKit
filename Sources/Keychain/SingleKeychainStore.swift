//
//  PersistenceKit
//
//  Copyright (c) 2018-Present Teknasyon Teknoloji.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation
import Security

/// `SingleKeychainStore` offers a convenient way to store a single `Codable` object securely in the OS Keychain.
///
/// **Warning**: Keep in mind that values stored in in the OS keychain is not removed when the app is deleted.
open class SingleKeychainStore<T: Codable> {

	/// serviceName is used for the kSecAttrService property to uniquely identify this keychain accessor.
	public let serviceName: String

	/// Store's unique identifier.
	///
	/// **Warning**: Never use the same identifier for two -or more- different stores.
	public let uniqueIdentifier: String

	/// JSON encoder. _default is JSONEncoder()_
	open var encoder = JSONEncoder()

	/// JSON decoder. _default is JSONDecoder()_
	open var decoder = JSONDecoder()

	/// Initialize store.
	///
	/// **Warning**: Never use the same identifier for two -or more- different stores.
	///
	/// - Parameters:
	///   - serviceName: service name. _default is bundle identifier or "PersistenceKit"_
	///   - uniqueIdentifier: uniqueIdentifier: store's unique identifier.
	required public init(serviceName: String = Bundle.main.bundleIdentifier ?? "PersistenceKit", uniqueIdentifier: String) {
		self.serviceName = serviceName
		self.uniqueIdentifier = uniqueIdentifier
	}

	/// Save object to store.
	///
	/// - Parameters:
	///   - object: object to save.
	///   - option: `KeychainAccessibilityOption`. _default is .whenUnlocked_
	/// - Throws: JSON encoding error.
	open func save(_ object: T, withAccessibilityOption option: KeychainAccessibilityOption = .whenUnlocked) throws {
		let data = try encoder.encode(generateDict(for: object))
		var query = generateQuery(accessibilityOption: option)
		query[Keys.valueData] = data

		let status = SecItemAdd(query as CFDictionary, nil)

		switch status {
		case errSecSuccess:
			return
		case errSecDuplicateItem:
			try update(object, withAccessibilityOption: option)
		default:
			throw KeychainError.saveFailure
		}
	}

	/// Update object in store.
	///
	/// - Parameters:
	///   - object: object to save.
	///   - option: `KeychainAccessibilityOption`. _default is KeychainAccessibilityOption.whenUnlocked_
	/// - Throws: JSON encoding error.
	open func update(_ object: T, withAccessibilityOption option: KeychainAccessibilityOption = .whenUnlocked) throws {
		let data = try encoder.encode(generateDict(for: object))
		var query = generateQuery(accessibilityOption: option)
		query[Keys.valueData] = data

		let updateQuery = [Keys.valueData: data]
		let status = SecItemUpdate(query as CFDictionary, updateQuery as CFDictionary)

		switch status {
		case errSecSuccess:
			return
		default:
			throw KeychainError.saveFailure
		}
	}

	/// Get object from store.
	///
	/// - Parameter option: `KeychainAccessibilityOption`. _default is KeychainAccessibilityOption.whenUnlocked_
	/// - Returns: optional object.
	open func object(accessibilityOption option: KeychainAccessibilityOption = .whenUnlocked) -> T? {
		var query = generateQuery(accessibilityOption: option)
		query[Keys.matchLimit] = kSecMatchLimitOne
		query[Keys.returnData] = kCFBooleanTrue

		var result: AnyObject?
		SecItemCopyMatching(query as CFDictionary, &result)

		guard let data = result as? Data else { return nil }
		guard let dict = try? decoder.decode([String: T].self, from: data) else { return nil }
		return extractObject(from: dict)
	}

	/// Delete object from store.
	///
	/// - Parameter option: KeychainAccessibilityOption. _default is KeychainAccessibilityOption.whenUnlocked_
	open func delete(accessibilityOption option: KeychainAccessibilityOption = .whenUnlocked) {
		let query = generateQuery(accessibilityOption: option)
		SecItemDelete(query as CFDictionary)
	}

}

// MARK: - Helpers
private extension SingleKeychainStore {

	/// Store key for object.
	var key: String {
		return "\(uniqueIdentifier)-single-object"
	}

	/// generate a dictionary from a `Codable` object.
	///
	/// - Parameter object: `Codable` object.
	/// - Returns: save dictionary.
	func generateDict(for object: T) -> [String: T] {
		return [key: object]
	}

	/// Get `Codable` object from a dictionary.
	///
	/// - Parameter dict: dictionary.
	/// - Returns: optional Codable object
	func extractObject(from dict: [String: T]) -> T? {
		return dict[key]
	}

	/// Creata a query dictionary from an option.
	///
	/// - Parameter option: `KeychainAccessibilityOption`
	/// - Returns: query dictionary.
	func generateQuery(accessibilityOption option: KeychainAccessibilityOption) -> [String: Any] {
		var query: [String: Any] = [Keys.class: kSecClassGenericPassword]
		query[Keys.attrService] = serviceName
		query[Keys.attrAccessible] = option.attribute

		let encodedIdentifier = uniqueIdentifier.data(using: .utf8)
		query[Keys.attrGeneric] = encodedIdentifier
		query[Keys.attrAccount] = encodedIdentifier

		return query
	}

}

// MARK: - Keys
private extension SingleKeychainStore {

	/// Keys
	struct Keys {

		static var matchLimit: String {
			return kSecMatchLimit as String
		}

		static var returnData: String {
			return kSecReturnData as String
		}

		static var valueData: String {
			return kSecValueData as String
		}

		static var attrAccessible: String {
			return kSecAttrAccessible as String
		}

		static var `class`: String {
			return kSecClass as String
		}

		static var attrService: String {
			return kSecAttrService as String
		}

		static var attrGeneric: String {
			return kSecAttrGeneric as String
		}

		static var attrAccount: String {
			return kSecAttrAccount as String
		}

	}

}
