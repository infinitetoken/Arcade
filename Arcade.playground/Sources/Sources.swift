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
    
    public var foreignKey: String {
        switch self {
        case .owner:
            return "ownerID"
        case .pet:
            return "petID"
        case .petToy:
            return "petToyID"
        case .toy:
            return "toyID"
        }
    }
}

public struct Owner: Storable {
    public static var table: Table = ExampleTable.owner
    
    public var uuid: String = UUID().uuidString
    public var name: String?
    
    public var pets: Children<Owner, Pet> {
        return Children<Owner, Pet>(uuid: self.uuid)
    }
    
    public init() {}
}

public struct Pet: Storable {
    public static var table: Table = ExampleTable.pet
    
    public var uuid: String = UUID().uuidString
    public var name: String?
    
    public var ownerID: String?
    
    public var owner: Parent<Pet, Owner> {
        return Parent<Pet, Owner>(uuid: self.ownerID)
    }
    
    public var petToys: Children<Pet, PetToy> {
        return Children<Pet, PetToy>(uuid: self.uuid)
    }
    
    public var toys: Siblings<Pet, Toy, PetToy> {
        return Siblings<Pet, Toy, PetToy>(uuid: self.uuid)
    }
    
    public init() {}
}

public struct PetToy: Storable {
    public static var table: Table = ExampleTable.petToy
    
    public var uuid: String = UUID().uuidString
    
    public var petID: String?
    public var toyID: String?
    
    public var pet: Parent<PetToy, Pet> {
        return Parent<PetToy, Pet>(uuid: self.petID)
    }
    
    public var toy: Parent<PetToy, Toy> {
        return Parent<PetToy, Toy>(uuid: self.toyID)
    }
    
    public init() {}
}

public struct Toy: Storable {
    public static var table: Table = ExampleTable.toy
    
    public var uuid: String = UUID().uuidString
    public var name: String?
    
    public var petToys: Children<Toy, PetToy> {
        return Children<Toy, PetToy>(uuid: self.uuid)
    }
    
    public var pets: Siblings<Toy, Pet, PetToy> {
        return Siblings<Toy, Pet, PetToy>(uuid: self.uuid)
    }
    
    public init() {}
}
