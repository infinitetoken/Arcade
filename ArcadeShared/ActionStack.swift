//
//  ActionStack.swift
//  Arcade
//
//  Created by Paul Foster on 12/17/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import Foundation


public struct ActionStack {
    
    public enum Operation {
        case insert
        case update
        case delete
    }
    
    private var storables: [[Storable]] = []
    private var operations: [Operation] = []
    private var tables: [Table] = []
    
    public mutating func push(storables: [Storable], operation: Operation, table: Table) {
        self.storables.append(storables)
        self.operations.append(operation)
        self.tables.append(table)
    }
    
    public mutating func pop<I: Storable>() -> (storables: [I], operation: Operation) {
        guard let storables = self.storables.popLast() as? [I],
            let operation = self.operations.popLast()
            else { fatalError() }
        return (storables, operation)
    }
    
    public mutating func popOperation() -> Operation? { return self.operations.popLast() }
    public mutating func popStorables() -> [Storable] {
        guard let storables = self.storables.last else { fatalError() }
        self.storables.removeLast()
        return storables
    }
    public mutating func popTable() -> Table? { return self.tables.popLast() }
    
    public func peek() -> (storables: [Storable], operation: Operation) {
        guard let storables = self.storables.last,
            let operation = self.operations.last
            else { fatalError() }
        return (storables, operation)
    }
}
