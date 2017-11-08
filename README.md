# Arcade

[![Carthage](https://img.shields.io/badge/Carthage-compatible-brightgreen.svg?style=flat)](https://github.com/Carthage/Carthage)

Arcade is a lightweight persistence layer for Swift structures!

- [Installation](#installation)
- [Usage](#usage)
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

struct Widget: Storable {

    var uuid: UUID
    var name: String?

}
```

### Table

The `Table` protocol defines the names of the tables in which to store your models.

```swift
import Arcade

enum AppTable: String, Table {
    case widget = "Widget"

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

arcade.connect().subscribe(onNext: { (success) in
    guard success else {
        // Connection Failed...
    }

    // Connected!
}) { (error) in
    // Error
}
```

### Inserting

```swift
import Arcade

let widget = Widget(uuid: UUID(), name: "Foo")

arcade.insert(table: AppTable.widget, storable: widget).subscribe(onNext: { (success) in
    guard success else {
        // Something went wrong...
    }

    // Inserted!
}) { (error) in
    // Error
}
```

### Updating

```swift
import Arcade

widget.name = "Bar"

arcade.update(table: AppTable.widget, storable: widget).subscribe(onNext: { (success) in
    guard success else {
        // Something went wrong...
    }

    // Updated!
}) { (error) in
    // Error
}
```

### Deleting

```swift
import Arcade

arcade.delete(table: AppTable.widget, storable: widget).subscribe(onNext: { (success) in
    guard success else {
        // Something went wrong...
    }

    // Deleted!
}) { (error) in
    // Error
}
```

### Fetching

To find a specific item by UUID:

```swift
import Arcade

let future: Future<Widget> = arcade.find(table: AppTable.widget, uuid: widget.uuid)

future.subscribe(onNext: { (widget) in
    guard let widget = widget else {
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
let future Future<Widget> = arcade.fetch(table: AppTable.widget, query: query)

future.subscribe(onNext: { (widgets) in
    // Do something with widgets...
}) { (error) in
    // Error
}
```

## License

Arcade is released under the MIT license. [See LICENSE](https://github.com/infinitetoken/Arcade/blob/master/LICENSE) for details.
