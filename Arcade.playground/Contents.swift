import Cocoa
import Arcade

let adapter = InMemoryAdapter()

Owner.adapter = adapter
Pet.adapter = adapter
PetToy.adapter = adapter
Toy.adapter = adapter

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

adapter.insert(storable: owner).then({ (success) -> Future<Bool> in
    return adapter.insert(storable: pet)
}).then({ (success) -> Future<Bool> in
    return adapter.insert(storable: toy)
}).then({ (success) -> Future<Bool> in
    return adapter.insert(storable: petToy)
}).then({ (success) -> Future<[Toy]> in
    return pet.toys.query(query: Query.expression(.equal("name", "Ball")))
}).subscribe({ (toys) in
    Swift.print(toys)
}) { (error) in
    Swift.print(error)
}
