# PersistenceKit


## tl;dr
You love Swift's Codable protocol and use it everywhere, who doesn't!
Here is an easy and very light way to store and retrieve `Codable` objects to various persistence layers, in a couple lines of code!

## Persistence Layers

PersistenceKit offers 3 layers of persistence:

### 1. UserDefaults
Stores data using [`UserDefaults`](https://developer.apple.com/documentation/foundation/userdefaults) - suitable for storing a reasonable number of objects.

### 2. Files
Stores data directly to directories in the app's documents directory using [`FileManager`](https://developer.apple.com/documentation/foundation/filemanager) - suitable for storing large number of objects.

### 3. Keychain
Stores data to OS's keychain using the [`Security Framework`](https://developer.apple.com/documentation/security) - suitable for storing sensitive data, like access tokens.


## Installation

<details>
<summary>CocoaPods (Recommended)</summary>
</br>
<p>To integrate PersistenceKit into your Xcode project using <a href="http://cocoapods.org">CocoaPods</a>, specify it in your <code>Podfile</code>:</p>
<pre><code class="ruby language-ruby">pod 'PersistenceKit'</code></pre>
</details>

<details>
<summary>Carthage</summary>
</br>
<p>To integrate PersistenceKit into your Xcode project using <a href="https://github.com/Carthage/Carthage">Carthage</a>, specify it in your <code>Cartfile</code>:</p>

<pre><code class="ogdl language-ogdl">github "Teknasyon-Teknoloji/PersistenceKit" ~&gt; 0.1
</code></pre>
</details>

<details>
<summary>Swift Package Manager</summary>
</br>
<p>The <a href="https://swift.org/package-manager/">Swift Package Manager</a> is a tool for automating the distribution of Swift code and is integrated into the swift compiler. It is in early development, but PersistenceKit does support its use on supported platforms.</p>
<p>Once you have your Swift package set up, adding PersistenceKit as a dependency is as easy as adding it to the dependencies value of your Package.swift.</p>

<pre><code class="swift language-swift">import PackageDescription
dependencies: [
.package(url: "https://github.com/Teknasyon-Teknoloji/PersistenceKit.git", from: "0.1")
]
</code></pre>
</details>

<details>
<summary>Manually</summary>
</br>
<p>Add the <a href="https://github.com/Teknasyon-Teknoloji/PersistenceKit/tree/master/Sources">Sources</a> folder to your Xcode project.</p>
</details>


## Usage

Let's say you have 2 structs; `User` and `Laptop` defined as bellow:

```swift
struct User: Codable {
	var id: Int
	var firstName: String
	var lastName: String
	var laptop: Laptop?
}
```

```swift
struct Laptop: Codable {
	var model: String
	var name: String
}
```

### 1. Conform to the `Identifiable` protocol and set the `idKey` property

The `Identifiable` protocol lets PersistenceKit knows what is the unique id for each object.

```swift
struct User: Codable, Identifiable {
	static let idKey = \User.id
	...
}
```

```swift
struct Laptop: Codable, Identifiable {
	static let idKey = \Laptop.model
	...
}
```

> Notice how `User` uses `Int` for its id, while `Laptop` uses `String`, in fact the id can be any type. PersistenceKit uses Swift keypaths to refer to properties without actually invoking them. Swift rocks 🤘

### 2 Create Stores

```swift
// To save objects to UserDefaults, create UserDefaultsStore:
let usersStore = UserDefaultsStore<User>(uniqueIdentifier: "users")!
let laptopsStore = UserDefaultsStore<Laptop>(uniqueIdentifier: "laptops")!

// To save a single object to UserDefaults, create UserDefaultsStore:
let userStore = SingleUserDefaultsStore<User>(uniqueIdentifier: "user")!

// To save objects to the file system, create FilesStore:
let usersStore = FilesStore<User>(uniqueIdentifier: "users")
let laptopsStore = FilesStore<Laptop>(uniqueIdentifier: "laptops")

// To save a single object to the file system, create SingleFilesStore:
let userStore = SingleFilesStore<User>(uniqueIdentifier: "user")

// To save a single object to the system's keychain, create SingleKeychainStore:
let userStore = SingleKeychainStore<User>(uniqueIdentifier: "user")
```


### 3. Voilà, you're all set!

```swift
let macbook = Laptop(model: "A1278", name: "MacBook Pro")
let john = User(userId: 1, firstName: "John", lastName: "Appleseed", laptop: macbook)

// Save an object to a store
try! usersStore.save(john)

// Save an array of objects to a store
try! usersStore.save([jane, steve, jessica])

// Get an object from store
let user = store.object(withId: 1)
let laptop = store.object(withId: "A1278")

// Get all objects in a store
let laptops = laptopsStore.allObjects()

// Check if store has an object
print(usersStore.hasObject(withId: 10)) // false

// Iterate over all objects in a store
laptopsStore.forEach { laptop in
	print(laptop.name)
}

// Delete an object from a store
usersStore.delete(withId: 1)

// Delete all objects in a store
laptops.deleteAll()

// Know how many objects are stored in a store
let usersCount = usersStore.objectsCount
```

## Requirements

- iOS 8.0+ / macOS 10.10+ / tvOS 9.0+ / watchOS 2.0+
- Xcode 10.0+
- Swift 4.2+


## Thanks

Special thanks to:
- [Paul Hudson](https://twitter.com/twostraws) for his [article](https://www.hackingwithswift.com/articles/57/how-swift-keypaths-let-us-write-more-natural-code) on how to use Swift keypaths to write more natural code.


## License

PersistenceKit is released under the MIT license. See [LICENSE](https://github.com/Teknasyon-Teknoloji/PersistenceKit/blob/master/LICENSE) for more information.
