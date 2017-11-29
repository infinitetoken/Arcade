import Cocoa
import Arcade

enum PlaygroundTable: String, Table {
    case widget = "Widget"
    
    var name: String {
        return self.rawValue
    }
}

struct Widget: Storable {
    
    var uuid: UUID
    var name: String
    
}

let widget = Widget(uuid: UUID(), name: "Hello")
let adapter = InMemoryAdapter()
let arcade = Arcade.shared
arcade.addAdapter(adapter, forKey: "InMemory")

adapter.insert(table: PlaygroundTable.widget, storable: widget).then({ (arcade) -> Future<[Widget]> in
    return adapter.fetch(table: PlaygroundTable.widget, query: nil)
}).subscribe({ (widgets) in
    print(widgets)
}) { (error) in
    print(error)
}

let expression = Expression.comparison("name", Comparison.contains, "Bob", [.caseInsensitive, .diacriticInsensitive])
print(expression.description)
