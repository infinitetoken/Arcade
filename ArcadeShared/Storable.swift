//
//  Storable.swift
//  Arcade
//
//  Created by A.C. Wright Design on 10/30/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import Foundation

public protocol Storable: Codable {
    
    static var table: Table { get set }
    static var adapter: Adapter? { get set }
    static var idKey: String { get }
    static var foreignKey: String { get }
    
    var uuid: UUID { get set }
    
    var dictionary: [String: Any] { get }

}

extension Storable {
    
    public static var idKey: String { return "uuid" }
    public static var foreignKey: String { return self.table.name.lowercased() }
    
    public var table: Table { return Self.table }
    public var adapter: Adapter? { return Self.adapter }
    public var idKey: String { return Self.idKey }
    public var foreignKey: String { return Self.foreignKey }
    
}
