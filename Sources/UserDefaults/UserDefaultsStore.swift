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

/// `UserDefaultsStore` offers a convenient way to store a collection of `Codable` objects in `UserDefaults`.
open class UserDefaultsStore<T: Codable & Identifiable> {

	/// Store's unique identifier.
	///
	/// **Warning**: Never use the same identifier for two -or more- different stores.
	public let uniqueIdentifier: String

	/// JSON encoder. _default is JSONEncoder()_
	open var encoder = JSONEncoder()

	/// JSON decoder. _default is JSONDecoder()_
	open var decoder = JSONDecoder()

	/// UserDefaults store.
	private var store: UserDefaults

	/// Whether keys should be hashed before storing or not.
	private var useHashing: Bool

	/// Initialize store with given identifier.
	///
	/// **Warning**: Never use the same identifier for two -or more- different stores.
	///
	/// - Parameters:
	///   - uniqueIdentifier: uniqueIdentifier: store's unique identifier.
	///   - useHashing: Whether keys should be hashed before storing or not. _default is false_
	required public init?(uniqueIdentifier: String, useHashing: Bool = false) {
		guard let store = UserDefaults(suiteName: uniqueIdentifier) else { return nil }
		self.uniqueIdentifier = uniqueIdentifier
		self.store = store
		self.useHashing = useHashing
	}

	/// Save object to store.
	///
	/// - Parameter object: object to save.
	/// - Throws: JSON encoding error.
	public func save(_ object: T) throws {
		let data = try encoder.encode(object)
		let isObjectAlreadyAdded = hasObject(withId: object[keyPath: T.idKey])
		store.set(data, forKey: key(for: object))
		if !isObjectAlreadyAdded {
			increaseCounter()
		}
	}

	/// Save optional object (if not nil) to store.
	///
	/// - Parameter optionalObject: optional object to save.
	/// - Throws: JSON encoding error.
	public func save(_ optionalObject: T?) throws {
		guard let object = optionalObject else { return }
		try save(object)
	}

	/// Save array of objects to store.
	///
	/// - Parameter objects: object to save.
	/// - Throws: JSON encoding error.
	public func save(_ objects: [T]) throws {
		for object in objects {
			try save(object)
		}
	}

	/// Get object from store by its id.
	///
	/// - Parameter id: object id.
	/// - Returns: optional object.
	public func object(withId id: T.ID) -> T? {
		guard let data = store.data(forKey: key(for: id)) else { return nil }
		return try? decoder.decode(T.self, from: data)
	}

	/// Get array of objects from store for a given array of id values.
	///
	/// - Parameter ids: array of ids.
	/// - Returns: array of objects with the given ids.
	public func objects(withIds ids: [T.ID]) -> [T] {
		return ids.compactMap { object(withId: $0) }
	}

	/// Get all objects from store.
	///
	/// - Returns: array of all objects in store.
	public func allObjects() -> [T] {
		guard objectsCount > 0 else { return [] }
		let keys = store.dictionaryRepresentation().keys
		return keys.compactMap { key -> T? in
			guard isObjectKey(key) else { return nil }
			guard let data = store.data(forKey: key) else { return nil }
			return try? decoder.decode(T.self, from: data)
		}
	}

	/// Delete object by its id from store.
	///
	/// - Parameter id: object id.
	public func delete(withId id: T.ID) {
		guard let object = object(withId: id) else { return }
		store.removeObject(forKey: key(for: object))
		decreaseCounter()
	}

	/// Delete objects with ids from given ids array.
	///
	/// - Parameter ids: array of ids.
	public func delete(withIds ids: [T.ID]) {
		ids.forEach { delete(withId: $0) }
	}

	/// Delete all objects in store.
	public func deleteAll() {
		store.removePersistentDomain(forName: uniqueIdentifier)
	}

	/// Count of all objects in store.
	public var objectsCount: Int {
		return store.integer(forKey: counterKey)
	}

	/// Check if store has object with given id.
	///
	/// - Parameter id: object id to check for.
	/// - Returns: true if the store has an object with the given id.
	public func hasObject(withId id: T.ID) -> Bool {
		return object(withId: id) != nil
	}

	/// Iterate over all objects in store.
	///
	/// - Parameter object: iteration block.
	public func forEach(_ object: (T) -> Void) {
		allObjects().forEach { object($0) }
	}

}

// MARK: - Helpers
private extension UserDefaultsStore {

	/// Increase objects count counter.
	func increaseCounter() {
		let int = store.integer(forKey: counterKey)
		store.set(int + 1, forKey: counterKey)
	}

	/// Decrease objects count counter.
	func decreaseCounter() {
		let int = store.integer(forKey: counterKey)
		guard int > 0 else { return }
		store.set(int - 1, forKey: counterKey)
	}

}

// MARK: - Keys
private extension UserDefaultsStore {

	/// counter key.
	var counterKey: String {
		return "\(uniqueIdentifier)-count"
	}

	/// store key for object.
	///
	/// - Parameter object: object.
	/// - Returns: UserDefaults key for given object.
	func key(for object: T) -> String {
		return key(for: object[keyPath: T.idKey])
	}

	/// store key for object by its id.
	///
	/// - Parameter id: object id.
	/// - Returns: UserDefaults key for given id.
	func key(for id: T.ID) -> String {
		return useHashing ? "\(uniqueIdentifier)-\(id.hashValue)" : "\(uniqueIdentifier)-\(id)"
	}

	/// Check if a UserDefaults key is an object key.
	///
	/// - Parameter key: UserDefaults key
	/// - Returns: true if the key represents an object key.
	func isObjectKey(_ key: String) -> Bool {
		return key.starts(with: "\(uniqueIdentifier)-")
	}

}
