//
//  Stack.swift
//  Arcade
//
//  Created by Paul Foster on 1/10/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import Foundation

struct Stack {
    
    struct Operation {
        
        enum Method {
            case insert
            case update
            case delete
        }
        
        var method: Method = .insert
        var storables: [Storable] = []
        var table: Table
        
    }
    
    private var operations: [Operation] = []
    
    var count: Int {
        return self.operations.count
    }
    
    mutating func push(_ operation: Operation) {
        self.operations.append(operation)
    }
    
    mutating func pop() -> Operation {
        guard let operation = self.operations.popLast() else { fatalError() }
        return operation
    }
    
    func peek() -> Operation {
        guard let operation = self.operations.last else { fatalError() }
        return operation
    }
    
}
