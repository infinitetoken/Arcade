import Cocoa
import Arcade

Arcade.shared.addAdapter(InMemoryAdapter(), forKey: "Example")

let adapter = ExampleTable.adapter!

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
    Swift.print(toys)
    let sort = Sort(key: "name", order: .ascending)
    return Owner.fetch(query: nil, sorts: [sort], limit: 1, offset: 0)
}).subscribe({ (owners) in
    Swift.print(owners)
}) { (error) in
    Swift.print(error)
}




print("\n")

owner.save().merge(with: pet.save()).subscribe({ (results) in
    print(results.0)
    print(results.1)
}) { (error) in
    print(error)
}

print("\n")



[owner.save(), owner.save(), owner.save()]**.subscribe({ (values) in
    values.forEach { print($0) }
}) { (error) in
    print(error)
}

print("\n")

merge([owner.save(), owner.save(), owner.save()]).subscribe({ (values) in
    values.forEach { print($0) }
}) { (error) in
    print(error)
}

print("\n")

owner.save().merge(with: [owner.save(), owner.save()]).subscribe({ (values) in
    values.forEach { print($0) }
}) { (error) in
    print(error)
}




var owners = [owner.save(), owner.save(), owner.save()]

owners.removeFirst().merge(with: owners).subscribe({ (values) in
    values.forEach { print($0) }
}) { (error) in
    print(error)
}








//let toys: Future<[Toy]> = Children<Owner, Pet>(uuid: nil, foreignKey: "").children("").fetch(query: nil)
//
//Children<Owner, Pet>(uuid: nil, foreignKey: "petToy").children("").fetch(query: nil).subscribe({ (toys: [PetToy]) in
//    print("hi")
//}) { (error) in
//    print(error)
//}

