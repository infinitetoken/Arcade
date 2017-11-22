//
//  Arcade.swift
//  Arcade
//
//  Created by A.C. Wright Design on 10/30/17.
//  Copyright © 2017 A.C. Wright Design. All rights reserved.
//

import Foundation

public final class Arcade {
    
    public static var shared: Arcade = Arcade()

    private var adapters: [String: Adapter] = [:]
    
    public func addAdapter(_ adapter: Adapter, forKey key: String) {
        self.adapters[key] = adapter
    }
    
    public func removeAdapter(forKey key: String) {
        self.adapters.removeValue(forKey: key)
    }
    
    public func adapter(forKey key: String) -> Adapter? {
        return self.adapters[key]
    }
    
}
