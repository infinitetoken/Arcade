# Arcade

[![Carthage](https://img.shields.io/badge/Carthage-compatible-brightgreen.svg?style=flat)](https://github.com/Carthage/Carthage)

Arcade is a lightweight persistence layer for Swift structures or objects!

- [Installation](#installation)
- [Usage](#usage)
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

    var id: String
    var name: String?

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

arcade.connect() { (result) in
    // Connected! (or Error)
}
```

### Inserting

```swift
import Arcade

let owner = Owner(id: id(), name: "Foo")

arcade.insert(storable: owner) { (result) in
    // Inserted! (or Error)
}
```

### Updating

```swift
import Arcade

owner.name = "Fred"

arcade.update(storable: owner) { (result) in
    // Updated! (or Error)
}
```

### Deleting

```swift
import Arcade

let id = owner.id

arcade.delete(id: id, type: Owner.self) { (result) in
    // Deleted! (or Error)
}
```

### Fetching

To find a specific item by id:

```swift
import Arcade

let future: Future<Owner> = arcade.find(id: owner.id)

arcade.find(id: owner.id) { (result) in
    // Found it! (or Error)
}
```

To query a set of items:

```swift
import Arcade

let expression = Expression.equal("name", "Foo")
let query = Query.expression(expression)

arcade.fetch(query: query) { (result) in
    // Do something with result... (or Error)
}
```

## CoreData

To use Arcade with the CoreData adapter some additional protocol conformance must be setup. Your
CoreData entites should conform to `CoreDataStorable`:

```swift

@objc(OwnerEntity)
class OwnerEntity: NSManagedObject {

    @NSManaged var id: id
    @NSManaged var name: String?

    override func awakeFromInsert() {
        super.awakeFromInsert()

        self.id = id()
    }

}

extension OwnerEntity: CoreDataStorable {

    public var viewable: Viewable {
        return Owner(id: self.id, name: self.name)
    }

    public var storable: Storable {
        return Owner(id: self.id, name: self.name)
    }

    public func update(withStorable dictionary: [String : Any]) -> Bool {
        if let id = dictionary["id"] as? id {
            self.id = id
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
