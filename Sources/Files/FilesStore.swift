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

/// `FilesStore` offers a convenient way to store a collection of `Codable` objects in the files system.
open class FilesStore<T: Codable & Identifiable> {

	/// Store's unique identifier.
	///
	/// **Warning**: Never use the same identifier for two -or more- different stores.
	public let uniqueIdentifier: String

	/// Store `Expiration` option. _default is .never_
	public let expiration: Expiration

	/// JSON encoder. _default is JSONEncoder()_
	open var encoder = JSONEncoder()

	/// JSON decoder. _default is JSONDecoder()_
	open var decoder = JSONDecoder()

	/// FileManager. _default is FileManager.default_
	private var manager = FileManager.default

	/// Whether keys should be hashed before storing or not.
	private var useHashing: Bool

	/// Initialize store with given identifiera and an optional expiry duration.
	///
	/// **Warning**: Never use the same identifier for two -or more- different stores.
	///
	/// - Parameters:
	///   - uniqueIdentifier: store's unique identifier.
	///   - useHashing: Whether keys should be hashed before storing or not. _default is false_
	///   - expiryDuration: optional store's expiry duration _default is .never_.
	required public init(uniqueIdentifier: String, useHashing: Bool = false, expiration: Expiration = .never) {
		self.uniqueIdentifier = uniqueIdentifier
		self.useHashing = useHashing
		self.expiration = expiration
	}

	/// Save object to store.
	///
	/// - Parameter object: object to save.
	/// - Throws: FileManager or JSON encoding error.
	public func save(_ object: T) throws {
		let url = try storeURL()
		let data = try encoder.encode(object)
		try manager.createDirectory(atPath: url.path, withIntermediateDirectories: true, attributes: nil)

		let path = try fileURL(object: object).path
		manager.createFile(atPath: path, contents: data, attributes: nil)

		let attributes: [FileAttributeKey: Any] = [
			.creationDate: Date(),
			.modificationDate: expiration.date
		]

		try manager.setAttributes(attributes, ofItemAtPath: path)
	}

	/// Save optional object (if not nil) to store.
	///
	/// - Parameter optionalObject: optional object to save.
	/// - Throws: FileManager or JSON encoding error.
	public func save(_ optionalObject: T?) throws {
		guard let object = optionalObject else { return }
		try save(object)
	}

	/// Save array of objects to store.
	///
	/// - Parameter objects: object to save.
	/// - Throws: FileManager or JSON encoding error.
	public func save(_ objects: [T]) throws {
		try objects.forEach { try save($0) }
	}

	/// Get object from store by its id.
	///
	/// - Parameter id: object id.
	/// - Returns: optional object.
	public func object(withId id: T.ID) -> T? {
		return object(withIdString: "\(id)")
	}

	/// Get array of objects from store for array of id values.
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
		guard let url = try? storeURL() else { return [] }
		guard let ids = try? manager.contentsOfDirectory(atPath: url.path) else { return [] }
		return ids.compactMap { object(withIdString: $0) }
	}

	/// Delete object by its id from store.
	///
	/// - Parameter id: object id.
	public func delete(withId id: T.ID) throws {
		guard let url = try? fileURL(id: id) else { return }
		guard manager.fileExists(atPath: url.path) else { return }
		try? manager.removeItem(at: url)
	}

	/// Delete objects with ids from given ids array.
	///
	/// - Parameter ids: array of ids.
	public func delete(withIds ids: [T.ID]) throws {
		try ids.forEach { try delete(withId: $0) }
	}

	/// Delete all objects in store.
	public func deleteAll() {
		guard let url = try? storeURL() else { return }
		guard manager.fileExists(atPath: url.path) else { return }
		try? manager.removeItem(at: url)
	}

	/// Count of all objects in store.
	public var objectsCount: Int {
		guard let url = try? storeURL() else { return 0 }
		guard let items = try? manager.contentsOfDirectory(atPath: url.path) else { return 0 }
		return items.count
	}

	/// Check if store has object with given id.
	///
	/// - Parameter id: object id to check for.
	/// - Returns: true if the store has an object with the given id.
	public func hasObject(withId id: T.ID) -> Bool {
		guard let url = try? fileURL(id: id) else { return false }
		return manager.fileExists(atPath: url.path)
	}

	/// Iterate over all objects in store.
	///
	/// - Parameter object: iteration block.
	public func forEach(_ object: (T) -> Void) {
		allObjects().forEach { object($0) }
	}

}

// MARK: - Helpers
private extension FilesStore {

	/// Get object from store by its id string.
	///
	/// - Parameter id: object id.
	/// - Returns: optional object.
	func object(withIdString idString: String) -> T? {
		guard let path = try? fileURL(idString: idString).path else { return nil }
		guard let attributes = try? manager.attributesOfItem(atPath: path) else { return nil }
		guard let modificationDate = attributes[.modificationDate] as? Date else { return nil }
		guard modificationDate >= Date() else {
			if let url = try? fileURL(idString: idString), manager.fileExists(atPath: url.path) {
				try? manager.removeItem(at: url)
			}
			return nil
		}
		guard let data = manager.contents(atPath: path) else { return nil }
		return try? decoder.decode(T.self, from: data)
	}

	/// Documents or Caches URL.
	///
	/// - Returns: Documents or Caches URL.
	/// - Throws: `FileManager` error
	func documentsURL() throws -> URL {
		let directory: FileManager.SearchPathDirectory
		switch expiration {
		case .never:
			directory = .documentDirectory
		default:
			directory = .cachesDirectory
		}

		return try manager.url(for: directory, in: .userDomainMask, appropriateFor: nil, create: true)
	}

	/// FilesStore URL.
	///
	/// - Returns: FilesStore URL.
	/// - Throws: `FileManager` error
	func filesStoreURL() throws -> URL {
		return try documentsURL().appendingPathComponent("FilesStore")
	}

	/// Store URL.
	///
	/// - Returns: Store URL.
	/// - Throws: `FileManager` error
	func storeURL() throws -> URL {
		return try filesStoreURL().appendingPathComponent(uniqueIdentifier, isDirectory: true)
	}

	/// URL for file with a given id.
	///
	/// - Parameter id: Object id.
	/// - Returns: file URL.
	/// - Throws: `FileManager` error
	func fileURL(id: T.ID) throws -> URL {
		return try useHashing ? fileURL(idString: "\(id.hashValue)") : fileURL(idString: "\(id)")
	}

	/// URL for file with a given string id.
	///
	/// - Parameter idString: Object id string.
	/// - Returns: file URL.
	/// - Throws: `FileManager` error
	func fileURL(idString: String) throws -> URL {
		return try storeURL().appendingPathComponent(idString)
	}

	/// URL for file for a given object.
	///
	/// - Parameter object: object.
	/// - Returns: file URL.
	/// - Throws: `FileManager` error
	func fileURL(object: T) throws -> URL {
		return try fileURL(id: object[keyPath: T.idKey])
	}

}
