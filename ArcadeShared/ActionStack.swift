//
//  ActionStack.swift
//  Arcade
//
//  Created by Paul Foster on 1/10/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import Foundation



struct ActionStack {
    
    enum Operation {
        case insert
        case update
        case delete
    }
    
    private var storables: [[Storable]] = []
    private var operations: [Operation] = []
    private var tables: [Table] = []
    
    mutating func push(storables: [Storable], operation: Operation, table: Table) {
        self.storables.append(storables)
        self.operations.append(operation)
        self.tables.append(table)
    }
    
    mutating func pop<I: Storable>() -> (storables: [I], operation: Operation) {
        guard let storables = self.storables.popLast() as? [I],
            let operation = self.operations.popLast()
            else { fatalError() }
        return (storables, operation)
    }
    
    mutating func popOperation() -> Operation? { return self.operations.popLast() }
    mutating func popStorables() -> [Storable] {
        guard let storables = self.storables.last else { fatalError() }
        self.storables.removeLast()
        return storables
    }
    mutating func popTable() -> Table? { return self.tables.popLast() }
    
    func peek() -> (storables: [Storable], operation: Operation) {
        guard let storables = self.storables.last,
            let operation = self.operations.last
            else { fatalError() }
        return (storables, operation)
    }
}
