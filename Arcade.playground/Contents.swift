import Cocoa
import Arcade

let adapter = InMemoryAdapter()

var owner = Owner()
owner.name = "Aaron"
owner.uuid

var pet = Pet()
pet.name = "Sheldon"
pet.ownerID = owner.uuid

var toy = Toy()
toy.name = "Ball"

var petToy = PetToy()
petToy.petID = pet.uuid
petToy.toyID = toy.uuid
    
owner.save(adapter: adapter).then({ (success) -> Future<Bool> in
    return pet.save(adapter: adapter)
}).then({ (success) -> Future<Bool> in
    return toy.save(adapter: adapter)
}).then({ (success) -> Future<Bool> in
    return petToy.save(adapter: adapter)
}).then({ (success) -> Future<[Toy]> in
    return pet.toys.fetch(query: Query.expression(.equal("name", "Ball")), adapter: adapter)
}).then({ (toys) -> Future<[Owner]> in
    print(toys)
    let sort = Sort(key: "name", order: .ascending)
    let query = Query.expression(.equal("name", "Aaron"))
    return Owner.fetch(query: query, sorts: [sort], limit: 1, offset: 0, adapter: adapter)
}).subscribe({ (owners) in
    print(owners)
}) { (error) in
    print(error)
}

