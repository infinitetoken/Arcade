import Foundation
import Arcade

public enum ExampleTable: String, Table {
    case owner = "Owner"
    case pet = "Pet"
    case petToy = "PetToy"
    case toy = "Toy"
    
    public var name: String {
        return self.rawValue
    }
    
    public static var adapter: Adapter? {
        return Arcade.shared.adapter(forKey: "Example")
    }
}

public struct Owner: Storable {
    public static var table: Table = ExampleTable.owner
    public static var adapter: Adapter? = ExampleTable.adapter
    public static var foreignKey: String = "ownerID"
    
    public var uuid: UUID = UUID()
    public var name: String?
    
    public var pets: Children<Owner, Pet> {
        return Children<Owner, Pet>(self.uuid)
    }
    
    public var dictionary: [String: Any] {
        return [
            "uuid": self.uuid,
            "name": self.name ?? NSNull()
        ]
    }
    
    public init() {}
}

public struct Pet: Storable {
    public static var table: Table = ExampleTable.pet
    public static var adapter: Adapter? = ExampleTable.adapter
    public static var foreignKey: String = "petID"
    
    public var uuid: UUID = UUID()
    public var name: String?
    
    public var ownerID: UUID?
    
    public var owner: Parent<Pet, Owner> {
        return Parent<Pet, Owner>(self.ownerID)
    }
    
    public var petToys: Children<Pet, PetToy> {
        return Children<Pet, PetToy>(self.uuid)
    }
    
    public var toys: Siblings<Pet, Toy, PetToy> {
        return Siblings<Pet, Toy, PetToy>(self.uuid)
    }
    
    public var dictionary: [String: Any] {
        return [
            "uuid": self.uuid,
            "name": self.name ?? NSNull(),
            "ownerID": self.ownerID ?? NSNull()
        ]
    }
    
    public init() {}
}

public struct PetToy: Storable {
    public static var table: Table = ExampleTable.petToy
    public static var adapter: Adapter? = ExampleTable.adapter
    public static var foreignKey: String = "petToyID"
    
    public var uuid: UUID = UUID()
    
    public var petID: UUID?
    public var toyID: UUID?
    
    public var pet: Parent<PetToy, Pet> {
        return Parent<PetToy, Pet>(self.petID)
    }
    
    public var toy: Parent<PetToy, Toy> {
        return Parent<PetToy, Toy>(self.toyID)
    }
    
    public var dictionary: [String: Any] {
        return [
            "uuid": self.uuid,
            "petID": self.petID ?? NSNull(),
            "toyID": self.toyID ?? NSNull()
        ]
    }
    
    public init() {}
}

public struct Toy: Storable {
    public static var table: Table = ExampleTable.toy
    public static var adapter: Adapter? = ExampleTable.adapter
    public static var foreignKey: String = "toyID"
    
    public var uuid: UUID = UUID()
    public var name: String?
    
    public var petToys: Children<Toy, PetToy> {
        return Children<Toy, PetToy>(self.uuid)
    }
    
    public var pets: Siblings<Toy, Pet, PetToy> {
        return Siblings<Toy, Pet, PetToy>(self.uuid)
    }
    
    public var dictionary: [String: Any] {
        return [
            "uuid": self.uuid,
            "name": self.name ?? NSNull()
        ]
    }
    
    public init() {}
}
