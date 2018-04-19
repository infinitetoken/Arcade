import Cocoa
import Arcade

Arcade.shared.addAdapter(InMemoryAdapter(), forKey: "Example")

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
    
owner.save().then({ (success) -> Future<Bool> in
    return pet.save()
}).then({ (success) -> Future<Bool> in
    return toy.save()
}).then({ (success) -> Future<Bool> in
    return petToy.save()
}).then({ (success) -> Future<[Toy]> in
    return pet.toys.fetch(query: Query.expression(.equal("name", "Ball")))
}).then({ (toys) -> Future<[Owner]> in
    print(toys)
    let sort = Sort(key: "name", order: .ascending)
    let query = Query.expression(.equal("name", "Aaron"))
    return Owner.fetch(query: query, sorts: [sort], limit: 1, offset: 0)
}).subscribe({ (owners) in
    print(owners)
}) { (error) in
    print(error)
}

