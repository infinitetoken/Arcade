//
//  Dictionary+JSON.swift
//  Arcade
//
//  Created by Aaron Wright on 9/28/18.
//  Copyright © 2018 A.C. Wright Design. All rights reserved.
//

import Foundation

public extension Dictionary {
    
    func jsonString() throws -> String? {
        guard let dict = self as? [String : Any] else { return nil }
        
        let data = try JSONSerialization.data(withJSONObject: dict, options: .sortedKeys)
        
        return String(data: data, encoding: .utf8)
    }
    
}
