# Arcade

[![Carthage](https://img.shields.io/badge/Carthage-compatible-brightgreen.svg?style=flat)](https://github.com/Carthage/Carthage)

Arcade is a lightweight persistence layer for Swift structures or objects!

- [Installation](#installation)
- [Usage](#usage)
- [Relationships](#relationships)
- [CoreData](#coredata)
- [License](#license)

## Installation with Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate Arcade into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "infinitetoken/Arcade" ~> 1.0
```

Run `carthage update` to build the framework and drag the built `Arcade.framework` into your Xcode project.

## Usage

### Models

Models (structures) in your project must conform to `Storable`.

```swift
import Arcade

struct Owner: Storable {

    static var table: Table = AppTable.owner

    var uuid: UUID
    var name: String?
    
    var dictionary: [String : Any]  {
        return [
            "uuid": self.uuid,
            "name": self.name ?? NSNull()
        ]
    }

}
```

### Table

The `Table` protocol defines the names of the tables in which to store your models.

```swift
import Arcade

enum AppTable: String, Table {
    case owner = "Owner"

    var name: String {
        return self.rawValue
    }
}
```

### Configure Adapter

```swift
import Arcade

let arcade = Arcade(adapter: InMemoryAdapter())
```

### Connect to Database

```swift
import Arcade

arcade.connect().subscribe({ (success) in
    // Connected!
}) { (error) in
    // Error
}
```

### Inserting

```swift
import Arcade

let owner = Owner(uuid: UUID(), name: "Foo")

arcade.insert(storable: owner).subscribe({ (success) in
    // Inserted!
}) { (error) in
    // Error
}
```

### Updating

```swift
import Arcade

owner.name = "Fred"

arcade.update(storable: owner).subscribe({ (success) in
    // Updated!
}) { (error) in
    // Error
}
```

### Deleting

```swift
import Arcade

let uuid = owner.uuid

arcade.delete(uuid: uuid, type: Owner.self).subscribe({ (success) in
    // Deleted!
}) { (error) in
    // Error
}
```

### Fetching

To find a specific item by UUID:

```swift
import Arcade

let future: Future<Owner> = arcade.find(uuid: owner.uuid)

future.subscribe({ (owner) in
    guard let owner = owner else {
        // Not found
    }

    // Found it!
}) { (error) in
    // Error
}
```

To query a set of items:

```swift
import Arcade

let expression = Expression.equal("name", "Foo")
let query = Query.expression(expression)
let future: Future<Owner> = arcade.fetch(query: query)

future.subscribe({ (owners) in
    // Do something with owners...
}) { (error) in
    // Error
}
```

## CoreData

To use Arcade with the CoreData adapter some additional protocol conformance must be setup. Your
CoreData entites should conform to `CoreDataStorable`:

```swift

@objc(OwnerEntity)
class OwnerEntity: NSManagedObject {

    @NSManaged var uuid: UUID
    @NSManaged var name: String?

    override func awakeFromInsert() {
        super.awakeFromInsert()

        self.uuid = UUID()
    }

}

extension OwnerEntity: CoreDataStorable {

    public var storable: Storable {
        return Owner(uuid: self.uuid, name: self.name)
    }

    public func update(withStorable dictionary: [String : Any]) -> Bool {
        if let uuid = dictionary["uuid"] as? UUID {
            self.uuid = uuid
        }
    
        if let name = dictionary["name"] as? String {
            self.name = name
        } else if dictionary["name"] is NSNull {
            self.name = nil
        }

        return true
    }

}
```

That's it! Now you can save your objects using the `CoreDataAdapter` just like any other object!

## License

Arcade is released under the MIT license. [See LICENSE](https://github.com/infinitetoken/Arcade/blob/master/LICENSE) for details.
